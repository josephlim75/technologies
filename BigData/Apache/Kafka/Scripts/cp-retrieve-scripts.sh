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
# Simple script to retrieve the script files from a known S3 location 
# (specified as a top-level HTTP).  The scripts are stored to 
# the location specified as $2 (default is /tmp/scripts)
# 
#	NOTE: script must be run as user capable of creating/writing
#	to that directory.
#
# usage:
#	cp-retrieve-scripts.sh <s3_bucket_with_prefix | URL>
#		Retrieval from S3 bucket will be directly from that bucket
#			if there is a trailing '/', otherwise from 
#			"<bucket>/scripts"
#		Retrieval from HTTP URL requires existence of "scripts.lst" file
#
# Input (env vars)
#	S3_REGION (default is us-west-2, though we'll look to bucket location if possible)
#
# examples
# 		Retrieve from s3://confluent-cft-devel/scripts
#	retrieve-scripts.sh s3://confluent-cft-devel	
#	retrieve-scripts.sh s3://confluent-cft-devel/scripts/
#
#		Retrieve from alternate locations
#	retrieve-connect-jars.sh s3://my-test-scripts/
#	retrieve-scripts.sh https://public-web-service.com/quickstart-scripts
#

THIS_SCRIPT=`readlink -f $0`
SCRIPTDIR=`dirname ${THIS_SCRIPT}`

LOG=/tmp/cp-retrieve-scripts.log

S3_REGION=${S3_REGION:-us-west-2}

SCRIPT_SRC=${1:-}
TARGET_DIR=${2:-/tmp/scripts}
LFILE=${LFILE:-scripts.lst}

# TBD : Validate the download 
do_s3_retrieval() {
	S3_TOP="${1%/}/"
	aws s3 cp --recursive ${S3_TOP} $TARGET_DIR/
	[ $? -ne 0 ] && return 1

	chmod a+x $TARGET_DIR/*
	rm -f $TARGET_DIR/${LFILE} 
	if [ ! -f $TARGET_DIR/${LFILE} ] ; then
		cd $TARGET_DIR; ls > $TARGET_DIR/${LFILE} 
	fi
	return 0
}

# Curl against Amazon buckets is unhappy with double '/' characters,
# so we always strip off the trailing one.
#
# We've also seen conditions where the first curl fails; so we'll
# leverage the curl retry for a more reliable experience

MAX_RETRIES=10

do_curl_retrieval() {
	SRC_URL=${1%/}
	curl -f -s ${SRC_URL}/${LFILE} -o $TARGET_DIR/${LFILE} \
		--retry $MAX_RETRIES --retry-max-time 60
	[ $? -ne 0 ] && return 1

	local rval=0
	for f in $(cat $TARGET_DIR/${LFILE}) ; do
		[ -z "$f" ] && continue

		curl -f -s ${SRC_URL}/$f -o $TARGET_DIR/$f \
			--retry $MAX_RETRIES --retry-max-time 180
		[ $? -ne 0 ] && rval=1
		chmod a+x $TARGET_DIR/$f
	done

	return $rval
}

set -x

##### Execution Logic starts here 

main()
{
    echo "$0 script started at "`date` >> $LOG

	mkdir -p $TARGET_DIR

		# If S3 is specified, download from there.   
		# If that fails (most likely due to issues with aws tool), simply
		# fall back to a curl retrieval.
		#
	if [ -z "${SCRIPT_SRC%s3:*}" ] ; then
		if [ -z "${SCRIPT_SRC##*/}" ] ; then
			S3_SRC="${SCRIPT_SRC}"
		else
			S3_SRC="${SCRIPT_SRC}/scripts"
		fi
		S3_BUCKET=${S3_SRC#s3://}
		S3_BUCKET=${S3_BUCKET%%/*}
		S3_BUCKET_REGION=$(aws s3api get-bucket-location --bucket ${S3_BUCKET} | jq -r .LocationConstraint)

		[ -n "$S3_BUCKET_REGION" ] && S3_REGION=$S3_BUCKET_REGION
		S3_HOST="s3-${S3_REGION}"
		[ "$S3_REGION" = "us-east-1" ] && S3_HOST="s3"
		HTTP_SRC=https://${S3_HOST}.amazonaws.com/${S3_SRC#s3://}

		do_s3_retrieval ${S3_SRC}
		if [ $? -ne 0 ] ; then
			do_curl_retrieval ${HTTP_SRC}
		fi
	fi

		# If HTTP or HTTPS is specified, download from there.   
		# Users _may_ have not directly specified the sub-directory, so
		# we'll try the default "connectors/<ver>" if necessary
		#
	if [ -z "${SCRIPT_SRC%http://*}" -o -z "${SCRIPT_SRC%https://*}" ] ; then
		do_curl_retrieval ${SCRIPT_SRC}
		if [ $? -ne 0 ] ; then
			do_curl_retrieval ${SCRIPT_SRC}/scripts
		fi
	fi

	echo "$0 script finished at "`date` >> $LOG
}


main $@
exitCode=$?

set +x

