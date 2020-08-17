#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Specifically, this script is intended SOLELY to support the Confluent
# Quick Start offering in Amazon Web Services. It is not recommended
# for use in any other production environment.
#

set -x

SCRIPT_NAME=prepare-disks
LOG=/tmp/${SCRIPT_NAME}.log

# Inputs :
#	DATA_DISKS (optional)
#	DATA_TOP (optional)
# Outputs
#	DATA_DIRS (potentially empty)
#

# TBD : add command line parsing to allow passing in of DATA_TOP
#	and DATA_DISKS (in case we don't want to search for them

# Where will data directories show up; "empty" means they will show
# up in root directory
#
DATA_TOP=
# DATA_TOP=/opt/confluent

# Confluent Installation Home (used for ownership details)
CP_HOME=${CP_HOME:-/opt/confluent}
unset DATA_DIRS

#
# Generate a list of unmounted disks (often persistent disks)
find_data_disks() {
    disks=""
    for d in `fdisk -l 2>/dev/null | grep -e "^Disk .* bytes.*$" | awk '{print $2}' | sort `
    do
        dev=${d%:}

        [ $dev != ${dev#/dev/mapper/} ] && continue     # skip udev devices
        [ $dev != ${dev#/dev/ram} ] && continue     # skip ramdisks devices
        [ $dev != ${dev#/dev/md} ] && continue     # skip software raid  devices

        mount | grep -q -w -e $dev -e ${dev}1 -e ${dev}2
        [ $? -eq 0 ] && continue

        swapon -s | grep -q -w $dev
        [ $? -eq 0 ] && continue

        which pvdisplay > /dev/null 2> /dev/null
        if [ $? -eq 0 ]; then
            pvdisplay $dev > /dev/null 2> /dev/null
            [ $? -eq 0 ] && continue
        fi

        disks="$disks $dev"
    done

    DATA_DISKS="$disks"
}

# $1 = device_file
# $2 = mount path (relative to $DATA_TOP)
#
# Side Effect : keep track of mount points in DATA_DIRS
#
update_fstab() {
	local dev=$1
	local dpath=$2

	sed -i "s|^$dev[ 	]|# $dev |" /etc/fstab
	echo "$dev  $DATA_TOP/$dpath  xfs  defaults  0  0" >> /etc/fstab
	mkdir -p $DATA_TOP/$dpath/kafka
	chown --reference $CP_HOME $DATA_TOP/$dpath/kafka

	if [ "$DATA_TOP" == "$CP_HOME" ] ; then
		DATA_DIRS="$DATA_DIRS $DATA_TOP/$dpath/kafka"
	else
		rm -f ${CP_HOME}/$dpath
		ln -s $DATA_TOP/$dpath/kafka ${CP_HOME}/$dpath
		if [ $? -eq 0 ] ; then
			DATA_DIRS="$DATA_DIRS ${CP_HOME}/$dpath"
		else
			DATA_DIRS="$DATA_DIRS ${DATA_TOP}/$dpath/kafka"
		fi
	fi

		# Strip leading space
	DATA_DIRS=`echo $DATA_DIRS`
}

# Called ONLY when DATA_DISKS has rational values
#	Normally NOT called for a single disk, but we allow it
raid_data_disks() {
	local numDisks=`echo $DATA_DISKS | wc -w`
	if [ $numDisks -lt 1 ] ; then
		return 1
	elif [ $numDisks -eq 1 ] ; then
		local mdadm_args="--force"
	fi

		# Create the array and a single mount point
		# Make sure "--chunk" and "su" settings match !!!
	local mdev=/dev/md0
	mdadm --create ${mdadm_args:-} --verbose $mdev --level=stripe --chunk=256 --raid-devices=$numDisks $DATA_DISKS
	[ $? -ne 0 ] && return 1

	mkfs -t xfs -f -d su=256k -d sw=$numDisks $mdev
	[ $? -ne 0 ] && return 1	# need better error handling 

	mkdir $DATA_TOP/data1
	mount $mdev $DATA_TOP/data1
	if [ $? -eq 0 ] ; then
		update_fstab $mdev data1
	else
		echo "ERROR: failed to mount $mdev at $DATA_TOP/data1"
	fi
}

# Mounts all data disks that DO NOT HAVE ANY OTHER CONTENT
#	Leaves list of mount points in DATA_DIRS
# 
mount_data_disks() {
	[ -z "$DATA_DISKS" ] && find_data_disks
	[ -z "$DATA_DISKS" ] && return		# nothing to mount

	local numDisks=`echo $DATA_DISKS | wc -w`
	if [ $numDisks -gt 1 ] ; then
		raid_data_disks
		[ $? -eq 0 ] && return
	fi

	didx=0
	for dev in $DATA_DISKS ; do
		didx=$((didx+1))		# increment first so "continue" logic works

		mkdir $DATA_TOP/data${didx}
		[ $? -ne 0 ] && continue			# need better error handling here
		
		mkfs -t xfs $dev
		[ $? -ne 0 ] && continue		# better error handling here as well

			# If we successfully format and mount the drive,
			# add an entry to /etc/fstab (and comment-out other 
			# entries for that device).
		mount $dev $DATA_TOP/data${didx} 
		if [ $? -eq 0 ] ; then
			update_fstab $dev data${didx}
		else
			echo "ERROR: failed to mount $dev at $DATA_TOP/data${didx}"
		fi
	done
}

# An Azure image will have 1 ephemeral disk and 0 or more
# persistent disks.   We will ONLY use the ephemeral disk
# if it is THE ONLY ONE (linking it to /data0).
#
# The disk is mounted at different locations for CentOS 
# vs Ubuntu (/mnt/resource vs /mnt).
#
main() {

	echo "${SCRIPT_NAME} ($0) script started at "`date` >> $LOG

	mount_data_disks

	if [ -z "$DATA_DIRS" ] ; then
		if [ -d /mnt/resource ] ; then
			RMNT=/mnt/resource 
		elif [ -d /mnt ] ; then
			RMNT=/mnt/resource
		fi

		if [ -n "${RMNT:-}" ] ; then
			mkdir -p $RMNT/kafka
			chown --reference $CP_HOME $RMNT/kafka

			rm -f ${CP_HOME}/data0
			ln -s $RMNT/kafka ${CP_HOME}/data0
			[ $? -eq 0 ] && DATA_DIRS=${CP_HOME}/data0
		fi
	fi

	echo "DATA_DIRS=$DATA_DIRS" >> $LOG
	echo "${SCRIPT_NAME} ($0) script finished at "`date` >> $LOG

	return 0
}

main $@
exitCode=$?

[ -n "$DATA_DIRS" ] && export DATA_DIRS="$DATA_DIRS"

set +x

# We want the script to be sourced rather than simply run
# but be careful about exit code
#	 NOTE: This logic requires bash 3.x or greater.
#		AND DOES NOT WORK ON UBUNTU (where default shell is dash)
#
#			if [ "${BASH_SOURCE[0]}" != $0 ] ; then

echo "$0" | grep -q $SCRIPT_NAME
if [ $? -ne 0 ] ; then 
	return $exitCode
else
	exit $exitCode
fi


