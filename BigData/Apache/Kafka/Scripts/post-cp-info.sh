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
#
#
#
# Post details back to the CloudFormation framework (if necessary)
# This is a wrapper intended to be used for ANY node in our cluster
# (broker, zookeeper, or worker).  It should be run AFTER all the
# services are up and running (see the wrapper logic in the
# cloud-init script that will call this script).
#
# usage:
#	post-cp-info.sh <WaitHandle>
#
#

HANDLE_URL=${1}

# Log should match all post-*-info scripts
LOG=/tmp/post-cp-info.log

if [ -z "${HANDLE_URL:-}" ] ; then
	echo "post-cp-info: No URL provided ... exiting" | tee -a $LOG
	exit 0
fi

#
# Only Broker 0 needs to post the details (we could have all brokers
# do it, but that would be overkill).
#
# Grab our broker index from /tmp/brokers
#	REMEMBER: ami-launch-index will ALWAYS be 0 for spot instances
#
THIS_HOST=`/bin/hostname -s`
murl_top=http://169.254.169.254/latest/meta-data
broker_index=$(curl -f -s $murl_top/ami-launch-index)
if [ -r /tmp/brokers ] ; then
	hindex=$(grep -n `hostname -s` /tmp/brokers | cut -d: -f1)

	if [ -z "$hindex" ] ; then
		echo "post-cp-info: $THIS_HOST is not a broker; nothing to do" | tee -a $LOG
		exit 0
	fi
	broker_index=$[hindex-1]
fi
[ -z "$broker_index" ] && broker_index=1

public_ip=$(curl -f -s $murl_top/public-ipv4)
instance_id=$(curl -f -s $murl_top/instance-id)

echo "post-cp-info: Executing on $THIS_HOST (broker $broker_index)" | tee -a $LOG

THIS_CLUSTER=$(cat /tmp/clustername)
echo "   for cluster $THIS_CLUSTER" | tee -a $LOG

if [ $broker_index -ne 0 ] ; then
	echo "	broker_index != 0; nothing to do" | tee -a $LOG
	exit 0
fi

	# Extract the necessary host lists from our environment
	# (files created by gen-cluster-hosts.sh).
	# Env variables will be of the form "host1,host2,..."
bhosts=$(awk '{print $1}' /tmp/brokers | head -3)
if [ -n "bhosts" ] ; then
	brokers=`echo $bhosts`			# convert <\n> to ' '
fi
brokers=${brokers// /,}

zkhosts=$(awk '{print $1}' /tmp/zookeepers)
if [ -n "$zkhosts" ] ; then
	zknodes=`echo $zkhosts`			# convert <\n> to ' '
fi
zknodes=${zknodes// /,}		# not really necessary ... but safe

		# external workers
whosts=$(awk '{print $1}' /tmp/workers)
if [ -n "whosts" ] ; then
	workers=`echo $whosts`			# convert <\n> to ' '
fi
workers=${workers// /,}


# TO BE DONE
#	Figure out the "correct" ports in case it's been customized
# zkPort=${clientPort:-2181}
# bPort=${listenerPort:-9092}

zconnect=""
for znode in ${zknodes//,/ } ; do
	if [ -z "$zconnect" ] ; then
		zconnect="$znode:${zkPort:-2181}"
	else
		zconnect="$zconnect,$znode:${zkPort:-2181}"
	fi
done

bconnect=""
for bnode in ${brokers//,/ } ; do
	if [ -z "$bconnect" ] ; then
		bconnect="$bnode:${bPort:-9092}"
	else
		bconnect="$bconnect,$bnode:${bPort:-9092}"
	fi
done


# POST cluster details 
#	ALWAYS send SOMETHING back, so that the WAIT condition is resolved

CP_HOME=${CP_HOME:-/opt/confluent}
if [ -d $CP_HOME ] ; then
	KAFKA_USER=$(stat -L -c "%U" $CP_HOME)
fi

KAFKA_USER=${KAFKA_USER:-kadamin}

CFN_SIGNAL=cfn-signal

# TO BE DONE
#	Have a better mechanism of retrieving ports for service access

if [ -z "${zknodes}"  -o  -z "${brokers}" ] ; then

    echo "Insufficient specification for Confluent Platform cluster ... nothing to post" >> $LOG
	$CFN_SIGNAL -e 0  -r "Stack_Info" \
		-i "private.zookeeper.connect" -d "unknown" "$HANDLE_URL"

	exit 0
fi

# Here's the real work ...

# We need to know our region for the aws commands
#
murl_top=http://169.254.169.254/latest/meta-data
THIS_AZ=$(curl -f -s ${murl_top}/placement/availability-zone)
THIS_REGION=${THIS_AZ%[a-z]}

CC_HOST=${workers%%,*}		# private hostname ... we'll map to public

CC_HOST_PUB=$(aws ec2 describe-instances --output text --region $THIS_REGION \
  --filters 'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].[PublicIpAddress,PublicDnsName,PrivateDnsName,Tags[?Key == `Name`] | [0].Value ]' | \
  grep -w "$CC_HOST" | cut -f 1)

shopt -s nocasematch
[ -n "$CC_HOST_PUB" ] && [[ "$CC_HOST_PUB" != "none" ]] && CC_HOST=$CC_HOST_PUB
shopt -u nocasematch

echo "Posting the following: " >> $LOG
	
echo "	private.zookeeper.connect: $zconnect" >> $LOG
$CFN_SIGNAL -e 0  -r "Stack_Info" \
    -i "private.zookeeper.connect" -d "$zconnect" "$HANDLE_URL"

echo "	private.bootstrap.servers: $bconnect" >> $LOG
$CFN_SIGNAL -e 0  -r "Stack_Info" \
    -i "private.bootstrap.servers" -d "$bconnect" "$HANDLE_URL"

if [ -f /tmp/cedition ] ; then
 	grep -q -i enterprise /tmp/cedition 2> /dev/null
	if [ $? -eq 0 ] ; then
	  	echo "	control.center.console: http://${CC_HOST}:9021" >> $LOG
	  	$CFN_SIGNAL -e 0  -r "Stack_Info" \
		  	-i "control.center.console" -d "http://${CC_HOST}:9021" "$HANDLE_URL"

		grep -q -i "Enabled" /tmp/csecurity 2> /dev/null
		if [ $? -eq 0 ] ; then
			echo "	control.center.credentials: $KAFKA_USER/${instance_id}" >> $LOG
			$CFN_SIGNAL -e 0  -r "Stack_Info" \
				-i "control.center.credentials" -d "$KAFKA_USER/${instance_id}" "$HANDLE_URL"
		fi
	fi
fi


