#!/bin/bash
#SOUSAGE
#
#NAME
#  CMD - © MapR Technologies, Inc., All Rights Reserved
#
#DESCRIPTION
#  MapR Converged Data Platform initialization and setup
#
#SYNOPSIS
#  CMD [OPTIONS] [cli|docker|image|install|reload|remove|update] <args>
#
#  cli *                   execute Stanza (mapr-installer-cli) command
#  docker *                build docker images
#  image *                 build cloud images
#  install                 install Installer packages (default)
#  reload                  reload Installer definitions
#  remove                  uninstall Installer packages
#  update                  update Installer packages
#
#OPTIONS
#  -a|--archives package_archive_file ...
#                          MapR 5.2+: paths to mapr-installer-*.tgz
#                              mapr-*.tgz, and mapr-mep-*.tgz
#                          MapR < 5.2: path to mapr-5.[0-1]*.tgz
#
#  -h|--help               Display this help message
#
#  -i|--install installer-pkg definitions-pkg
#                          Path to MapR installer and definition packages
#
#  -n|--noinet             Indicate that there is no internet access
#
#  -p|--port [host:]port   Set installer HTTPS port (9443) and optional
#                              internal network hostname
#
#  -r|--repo               Specify the top repository URL for MapR installer,
#                              core and ecosystem packages
#
#  -v|--verbose            Enable verbose output
#
#  -y|--yes                Do not prompt and accept all default values
#
#EOUSAGE

# return codes
NO=0
YES=1
INFO=0
WARN=-1
ERROR=1

# vars
BOOLSTR=("false" "true")
CMD=${0##*/}
CONTINUE_MSG="Continue install anyway?"
CONN_TIMEOUT=${CONN_TIMEOUT:-15}
CURL="curl -f -s --max-time $CONN_TIMEOUT"
CURL_NOSAVE="$CURL -o /dev/null"
DOMAIN=$(hostname -d 2>/dev/null)
ECHOE="echo -e"
[ "$(echo -e)" = "-e" ] && ECHOE="echo"
ID=$(id -u)
IMAGE_DISK_SIZE=128
INSTALLER=$(cd $(dirname $0) 2>/dev/null && echo $(pwd)/$(basename $0))
ISCONNECTED=$YES
ISUPDATE=$NO
NOINET=$NO
PAGER=${PAGER:-more}
PROMPT_SILENT=$NO
SSHD=sshd
SSHD_PORT=22
TEST_CONNECT=$YES
USE_SYSTEMCTL=$NO
USER=$(id -n -u)
VERBOSE=$NO
VERSION=BUILD_VERSION_INTERNAL
WGET="wget -q -T$CONN_TIMEOUT"

MAPR_CLUSTER=${MAPR_CLUSTER:-my.cluster.com}
MAPR_ENV_FILE=/etc/profile.d/mapr.sh
MAPR_ENVIRONMENT=
MAPR_UID=${MAPR_UID:-5000}
MAPR_GID=${MAPR_GID:-5000}
MAPR_USER=${MAPR_USER-mapr}
MAPR_USER_CREATE=${MAPR_USER_CREATE:-$NO}
MAPR_GROUP=${MAPR_GROUP:-mapr}
MAPR_GROUP_CREATE=${MAPR_GROUP_CREATE:-$NO}
MAPR_HOME=${MAPR_HOME:-/opt/mapr}
MAPR_PORT=${MAPR_PORT:-9443}
MAPR_INSTALLER_DIR=${MAPR_INSTALLER_DIR:-$MAPR_HOME/installer}
MAPR_BIN_DIR=${MAPR_BIN_DIR:-$MAPR_INSTALLER_DIR/bin}
MAPR_DATA_DIR=${MAPR_DATA_DIR:-$MAPR_INSTALLER_DIR/data}
MAPR_LIB_DIR=${MAPR_LIB_DIR:-$MAPR_HOME/lib}
MAPR_PKG_URL=${MAPR_PKG_URL:-http://package.mapr.com/releases}
MAPR_FUSE_FILE="${MAPR_HOME}/conf/fuse.conf"
MAPR_PROPERTIES_FILE="$MAPR_DATA_DIR/properties.json"
MAPR_SUDOERS_FILE="/etc/sudoers.d/mapr_user"
# MAPR_MOUNT_PATH=${MAPR_MOUNT_PATH-/mapr} # set this to enable FUSE
MAPR_TICKET_FILE=$(basename ${MAPR_TICKETFILE_LOCATION:-mapr_ticket})

MAPR_CORE_URL=${MAPR_CORE_URL:-$MAPR_PKG_URL}
MAPR_ECO_URL=${MAPR_ECO_URL:-$MAPR_PKG_URL}
MAPR_GPG_KEY_URL="http://package.mapr.com/releases/pub/maprgpg.key"
MAPR_INSTALLER_URL=${MAPR_INSTALLER_URL:-$MAPR_PKG_URL/installer}
MAPR_INSTALLER_PACKAGES=
MAPR_PACKAGES_BASE="mapr-core mapr-hadoop-core mapr-mapreduce2 mapr-zk-internal"
MAPR_PACKAGES_CLIENT="mapr-client"
MAPR_PACKAGES_IMAGE="mapr-core-internal mapr-hadoop-core mapr-mapreduce2 mapr-zk-internal"
MAPR_PACKAGE_POSIX=${MAPR_PACKAGE_POSIX:-mapr-posix-client-container}
MAPR_VERSION_CORE=${MAPR_VERSION_CORE:-5.2.2}
MAPR_VERSION_MEP=${MAPR_VERSION_MEP:-3.0.1}

DEPENDENCY_BASE_DEB="curl sudo tzdata wget"
DEPENDENCY_INSTALLER_DEB="$DEPENDENCY_BASE_DEB openssh-client openssh-server sshpass"
DEPENDENCY_CLIENT_DEB="$DEPENDENCY_BASE_DEB apt-utils dnsutils file \
iputils-ping net-tools nfs-common openssl syslinux sysv-rc-conf libssl1.0.0"
DEPENDENCY_SERVER_DEB="$DEPENDENCY_CLIENT_DEB debianutils libnss3 libsysfs2 \
netcat ntp ntpdate python-dev python-pycurl sdparm sysstat"

DEPENDENCY_BASE_RPM="curl initscripts net-tools sudo wget which"
DEPENDENCY_CLIENT_RPM="$DEPENDENCY_BASE_RPM syslinux openssl file"
DEPENDENCY_INSTALLER_RPM="$DEPENDENCY_BASE_RPM openssh-clients openssh-server sshpass"
DEPENDENCY_SERVER_RPM="$DEPENDENCY_CLIENT_RPM device-mapper iputils libsysfs \
lvm2 nc nfs-utils nss ntp python-devel python-pycurl rpcbind sdparm sysstat"

DEPENDENCY_BASE_SUSE="aaa_base curl net-tools sudo timezone wget which"
DEPENDENCY_CLIENT_SUSE="$DEPENDENCY_BASE_SUSE libopenssl1_0_0 \
netcat-openbsd nfs-client openssl syslinux tar util-linux vim"
DEPENDENCY_INSTALLER_SUSE="$DEPENDENCY_BASE_SUSE openssh sshpass"
DEPENDENCY_SERVER_SUSE="$DEPENDENCY_CLIENT_SUSE device-mapper iputils lvm2 \
mozilla-nss ntp sdparm sysfsutils sysstat util-linux"

EPEL6_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm"
EPEL7_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"

CONTAINER=$NO
CONTAINER_CLUSTER_CONF="$MAPR_HOME/conf/mapr-clusters.conf"
CONTAINER_CONFIGURE_SCRIPT="$MAPR_HOME/server/configure.sh"
CONTAINER_INITIALIZED=$NO
CONTAINER_INSTALLER_CONF="$MAPR_DATA_DIR/installer.mv.db"
CONTAINER_PORTS=
CONTAINER_SCRIPT_DIR="$MAPR_INSTALLER_DIR/docker"
CONTAINER_SCRIPT="$CONTAINER_SCRIPT_DIR/$(basename $0)"
CONTAINER_SUDO=$YES
[ -f "$CONTAINER_CLUSTER_CONF" -o -f "$CONTAINER_INSTALLER_CONF" ] && \
    CONTAINER_INITIALIZED=$YES

DOCKER_DIR=${DOCKER_DIR:-$(pwd)/docker_images}
DOCKER_BASE_DIR="$DOCKER_DIR/base"
DOCKER_BUILD_FILE=docker-build.sh
DOCKER_CLIENT_DIR="$DOCKER_DIR/client"
DOCKER_CORE_DIR="$DOCKER_DIR/core"
DOCKER_FILE=Dockerfile
DOCKER_INSTALLER_DIR="$DOCKER_DIR/installer"
DOCKER_TAG_FILE=tagname

HTTPD_DEB=${HTTPD_DEB:-apache2}
HTTPD_RPM=${HTTPD_RPM:-httpd}
HTTPD_REPO=${HTTPD_REPO:-/var/www/html/mapr}

OPENJDK_DEB=${OPENJDK_DEB:-openjdk-7-jdk}
OPENJDK_DEB_7=${OPENJDK_DEB_7:-openjdk-7-jdk}
OPENJDK_DEB_8=${OPENJDK_DEB_8:-openjdk-8-jdk}
OPENJDK_RPM=${OPENJDK_RPM:-java-1.8.0-openjdk-devel}
OPENJDK_RPM_7=${OPENJDK_RPM_7:-java-1.7.0-openjdk-devel}
OPENJDK_RPM_8=${OPENJDK_RPM_8:-java-1.8.0-openjdk-devel}
OPENJDK_SUSE=${OPENJDK_SUSE:-java-1_8_0-openjdk-devel}
OPENJDK_SUSE_7=${OPENJDK_SUSE_7:-java-1_7_0-openjdk-devel}
OPENJDK_SUSE_8=${OPENJDK_SUSE_8:-java-1_8_0-openjdk-devel}

OPENJDK_DEB_HL=${OPENJDK_DEB_HL:-openjdk-7-jre-headless}
OPENJDK_DEB_7_HL=${OPENJDK_DEB_7_HL:-openjdk-7-jre-headless}
OPENJDK_DEB_8_HL=${OPENJDK_DEB_8_HL:-openjdk-8-jre-headless}
OPENJDK_RPM_HL=${OPENJDK_RPM_HL:-java-1.8.0-openjdk-headless}
OPENJDK_RPM_7_HL=${OPENJDK_RPM_7_HL:-java-1.7.0-openjdk-headless}
OPENJDK_RPM_8_HL=${OPENJDK_RPM_8_HL:-java-1.8.0-openjdk-headless}
OPENJDK_SUSE_HL=${OPENJDK_SUSE_HL:-java-1_8_0-openjdk-headless}
OPENJDK_SUSE_7_HL=${OPENJDK_SUSE_7_HL:-java-1_7_0-openjdk-headless}
OPENJDK_SUSE_8_HL=${OPENJDK_SUSE_8_HL:-java-1_8_0-openjdk-headless}

REPO_EXT_redhat=repo
REPO_EXT_suse=repo
REPO_EXT_ubuntu=list
REPO_PATH_redhat=/etc/yum.repos.d
REPO_PATH_suse=/etc/zypp/repos.d
REPO_PATH_ubuntu=/etc/apt/sources.list.d

CLOUD_SWAP_SIZE=2048
AZURE_END=""
AZURE_NEW_PARTITION=""
AZURE_ROOT_DEVICE=""
AZURE_ROOT_DEVICE_NAME=""
AZURE_ROOT_SIZE_GB=""
AZURE_SIZE_GB=0
AZURE_START=""

# OS support matrix
declare -a SUPPORTED_RELEASES=
declare -a SUPPORTED_RELEASES_RH=('6.1' '6.2' '6.3' '6.4' '6.5' '6.6' '6.7' \
'6.8' '7.0' '7.1' '7.2' '7.3')
declare -a SUPPORTED_RELEASES_SUSE=('11.3' '12' '12.0' '12.1')
declare -a SUPPORTED_RELEASES_UBUNTU=('12.04' '14.04' '16.04')

export JDK_QUIET_CHECK=$YES # don't want env.sh to exit
export JDK_REQUIRED=$YES    # ensure we have full JDK
JAVA_HOME_OLD=
JDK_UPDATE_ONLY=$NO
JDK_UPGRADE_JRE=$NO
JDK_VER=0

# check to see if we are running in a container env
RESULTS=$(cat /proc/1/sched 2>&1| head -n 1 | awk '{gsub("[(,]","",$2); print $2}')
[ $? -eq 0 ] && echo "$RESULTS" | grep -Eq '^[0-9]+$' && [ $RESULTS -ne 1 ] && \
   CONTAINER=$YES

if hostname -A > /dev/null 2>&1; then
    HOST=$(hostname -A | cut -d' ' -f1)
fi
if [ -z "$HOST" ] && hostname --fqdn > /dev/null 2>&1; then
    HOST=$(hostname --fqdn 2>/dev/null)
fi
if [ -z "$HOST" ]; then
    HOST=$(hostname 2>/dev/null)
fi
if [ -z "$HOST" ] && hostname -I > /dev/null 2>&1; then
    HOST=$(hostname -I | cut -d' ' -f1)
fi
if [ -z "$HOST" ] || [ $CONTAINER -eq $YES ]; then
    if which ip > /dev/null 2>&1 && ip addr show > /dev/null 2>&1; then
        HOST=$(ip addr show | grep inet | grep -v 'scope host' | head -1 | \
            sed -e 's/^[^0-9]*//; s/\(\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\).*/\1/')
    fi
fi
if [ -z "$HOST" -a $(uname -s) = "Darwin" ]; then
    HOST=$(ipconfig getifaddr en0)
    [ -z "$HOST" ] && HOST=$(ipconfig getifaddr en1)
fi

HOST_INTERNAL=$HOST
MAPR_HOST=$HOST:$MAPR_PORT

# determine timezone
MAPR_TZ=${MAPR_TZ:-$TZ}
[ -z "$MAPR_TZ" ] && MAPR_TZ="$(cat /etc/timezone 2> /dev/null)"
[ -z "$MAPR_TZ" ] && MAPR_TZ="$(readlink /etc/localtime | sed -e 's|.*zoneinfo/||')"
[ -z "$MAPR_TZ" ] && MAPR_TZ="$(grep "ZONE=" /etc/sysconfig/clock 2> /dev/null | cut -d'"' -f 2)"
[ -z "$MAPR_TZ" ] && MAPR_TZ=US/Pacific

# determine service management framework
if [ $CONTAINER -eq $YES ]; then
    [ -x "/usr/bin/systemctl" ] && USE_SYSTEMCTL=$YES
else
    which systemctl >/dev/null 2>&1 && systemctl | fgrep -q '.mount' && \
        USE_SYSTEMCTL=$YES
fi

unset MAPR_ARCHIVES
unset MAPR_DEF_VERSION
unset MAPR_SERVER_VERSION
unset OS

##
## functions
##

# Set traps so script exits cleanly. Ubuntu behaves better when signals are
# caught in parent shell. Otherwise, sub-commands do get interrupted, but don't
# always exit properly - seems like a bug
catch_signals() {
    if grep -q -s DISTRIB_ID=Ubuntu /etc/lsb-release; then
        trap catch_trap SIGHUP SIGINT SIGQUIT SIGUSR1 SIGTERM
    else
        trap '' SIGHUP SIGINT SIGQUIT SIGUSR1 SIGTERM
    fi
}

catch_trap() {
    msg ""
}

json_field() {
    echo $(echo "$1" | grep -Po "$2"'.*?[^\\]",' | cut -d: -f2 | \
        sed -e 's/ *"/"/;s/",/"/')
}

# Output an error, warning or regular message
msg() {
    msg_format "$1" $2
}

msg_bold() {
    tput bold
    msg_format "$1"
    tput sgr0
}

msg_center() {
    local width=$(tput cols)
    $ECHOE "$1" | awk '{ spaces = ('$width' - length) / 2
        while (spaces-- >= 1) printf (" ")
        print
    }'
}

msg_err() {
    tput bold
    msg_format "\nERROR: $1"
    tput sgr0
    [ $MAPR_USER_CREATE -eq $YES ] && userdel $MAPR_USER > /dev/null 2>&1
    [ $MAPR_GROUP_CREATE -eq $YES ] && groupdel $MAPR_GROUP > /dev/null 2>&1
    exit $ERROR
}

# Print each word according to the screen size
msg_format() {
    local length=0
    local width=$(tput cols)
    local words=$1

    width=${width:-80}
    for word in $words; do
        length=$(($length + ${#word} + 1))
        if [ $length -gt $width ]; then
            $ECHOE "\n$word \c"
            length=$((${#word} + 1))
        else
            $ECHOE "$word \c"
        fi
    done
    [ -z "$2" ] && $ECHOE "\n"
}

msg_warn() {
    tput bold
    msg_format "\nWARNING: $1"
    tput sgr0
    sleep 2
}

prompt() {
    local query=$1
    local default=${2:-""}

    shift 2
    if [ $PROMPT_SILENT -eq $YES ]; then
        if [ -z "$default" ]; then
            msg_err "no default value available"
        else
            msg "$query: $default\n" "-"
            ANSWER=$default
            return
        fi
    fi
    unset ANSWER
    # allow SIGINT to interrupt
    trap - SIGINT
    while [ -z "$ANSWER" ]; do
        if [ -z "$default" ]; then
            msg "$query:" "-"
        else
            msg "$query [$default]:" "-"
        fi
        if [ "$1" = "-s" -a -z "$BASH" ]; then
            trap 'stty echo' EXIT
            stty -echo
            read ANSWER
            stty echo
            trap - EXIT
        else
            read $* ANSWER
        fi
        if [ "$ANSWER" = "q!" ]; then
            exit 1
        elif [ -z "$ANSWER" -a -n "$default" ]; then
            ANSWER=$default
        fi
        [ "$1" = "-s" ] && echo
    done
    # don't allow SIGINT to interrupt
    if [ "$OS" = "ubuntu" ]; then
        trap catch_trap SIGINT
    else
        trap '' SIGINT
    fi
}

prologue() {
    tput clear
    tput bold
    msg_center "\nMapR Distribution Initialization and Update\n"
    msg_center "Copyright $(date +%Y) MapR Technologies, Inc., All Rights Reserved"
    msg_center "http://www.mapr.com\n"
    tput sgr0
    check_os
    prompt_warn "" "$1?"
    [ $? -eq $NO ] && exit 1
}

prompt_boolean() {
    unset ANSWER
    while [ -z "$ANSWER" ]; do
        prompt "$1 (y/n)" ${2:-y}
        case "$ANSWER" in
        n*|N*) ANSWER=$NO; break ;;
        y*|Y*) ANSWER=$YES; break ;;
        *) unset ANSWER ;;
        esac
    done
}

prompt_package() {
    prompt_boolean "Add $1 to image?" $4
    if [ $ANSWER -eq $YES ]; then
        PACKAGES="$PACKAGES $2"
        if [ -z "$TAG" ]; then
            TAG=$3
        else
            TAG="${TAG}_$3"
        fi
        shift 4
        if [ $# -gt 0 ]; then
            CONTAINER_PORTS="$CONTAINER_PORTS $*"
        fi
    fi
}

prompt_warn() {
    [ -n "$1" ] && msg_warn "$1"
    prompt_boolean "$2" "$3"
    return $ANSWER
}

success() {
    local s="...Success"

    [ "$1" = "$YES" ] && s="\n$s"
    [ -n "$2" ] && s="$s - $2"
    msg "$s"
}

# the /usr/bin/tput may not exist in docker container
tput() {
    [ -f /usr/bin/tput ] && /usr/bin/tput "$@"
}

usage() {
    code=${1-1}
    [ $code -ne 0 ] && msg_warn "invalid command-line arguments\c"
    head -50 $INSTALLER | sed -e '1,/^#SOUSAGE/d' -e '/^#EOUSAGE/,$d' \
        -e 's/^\#//' -e "s?CMD?$CMD?" | $PAGER
    exit $code
}


# WARNING: The code from here to the next tag is included in env.sh.
#          any changes should be applied there too
check_java_home() {
    local found=0
    if [ -n "$JAVA_HOME" ]; then
        if [ $JDK_REQUIRED -eq 1 ]; then
            if [ -e "$JAVA_HOME"/bin/javac -a -e "$JAVA_HOME"/bin/java ]; then
                found=1
            fi
        elif [ -e "$JAVA_HOME"/bin/java ]; then
            found=1
        fi
        if [ $found -eq 1 ]; then
            java_version=$($JAVA_HOME/bin/java -version 2>&1 | fgrep version | \
                head -n1 | cut -d '.' -f 2)
            [ -z "$java_version" ] || echo $java_version | \
                fgrep -i Error > /dev/null 2>&1 || [ "$java_version" -le 6 ] && \
                unset JAVA_HOME
        else
            unset JAVA_HOME
        fi
    fi
}

# WARNING:  You must replicate any changes here in env.sh
check_java_env() {
    # We use this flag to force checks for full JDK
    JDK_QUIET_CHECK=${JDK_QUIET_CHECK:-0}
    JDK_REQUIRED=${JDK_REQUIRED:-0}
    # Handle special case of bogus setting in some virtual machines
    [ "${JAVA_HOME:-}" = "/usr" ] && JAVA_HOME=""

    # Look for installed JDK
    if [ -z "$JAVA_HOME" ]; then
        sys_java="/usr/bin/java"
        if [ -e $sys_java ]; then
            jcmd=$(readlink -f $sys_java)
            if [ $JDK_REQUIRED -eq 1 ]; then
                if [ -x ${jcmd%/jre/bin/java}/bin/javac ]; then
                    JAVA_HOME=${jcmd%/jre/bin/java}
                elif [ -x ${jcmd%/java}/javac ]; then
                    JAVA_HOME=${jcmd%/bin/java}
                fi
            else
                if [ -x ${jcmd} ]; then
                    JAVA_HOME=${jcmd%/bin/java}
                fi
            fi
            [ -n "$JAVA_HOME" ] && export JAVA_HOME
        fi
    fi

    check_java_home
    # MARKER - DO NOT DELETE THIS LINE
    # attempt to find java if JAVA_HOME not set
    if [ -z "$JAVA_HOME" ]; then
        for candidate in \
            /Library/Java/Home \
            /usr/java/default \
            /usr/lib/jvm/default-java \
            /usr/lib*/jvm/java-8-openjdk* \
            /usr/lib*/jvm/java-8-oracle* \
            /usr/lib*/jvm/java-8-sun* \
            /usr/lib*/jvm/java-1.8.* \
            /usr/lib*/jvm/java-1.8.*/jre \
            /usr/lib*/jvm/java-7-openjdk* \
            /usr/lib*/jvm/java-7-oracle* \
            /usr/lib*/jvm/java-7-sun* \
            /usr/lib*/jvm/java-1.7.*/jre \
            /usr/lib*/jvm/java-1.7.* ; do
            if [ -e $candidate/bin/java ]; then
                export JAVA_HOME=$candidate
                check_java_home
                if [ -n "$JAVA_HOME" ]; then
                    break
                fi
            fi
        done
        # if we didn't set it
        if [ -z "$JAVA_HOME" -a $JDK_QUIET_CHECK -eq $NO ]; then
            cat 1>&2 <<EOF
+======================================================================+
|      Error: JAVA_HOME is not set and Java could not be found         |
+----------------------------------------------------------------------+
| MapR requires Java 1.7 or later.                                     |
| NOTE: This script will find Oracle or Open JDK Java whether you      |
|       install using the binary or the RPM based installer.           |
+======================================================================+
EOF
            exit 1
        fi
    fi

    if [ -n "${JAVA_HOME}" ]; then
        # export JAVA_HOME to PATH
        export PATH=$JAVA_HOME/bin:$PATH
    fi
}

# WARNING: The code above is also in env.sh

check_checkpwd() {
    case $OS in
    redhat|suse)
        CHKPWD_ID=suid
        CHKPWD_PERM=-4000
        ;;
    ubuntu)
        CHKPWD_ID=sgid
        CHKPWD_PERM=-2000
        ;;
    esac
    find -L /sbin -perm $CHKPWD_PERM | fgrep unix_chkpwd > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        prompt_warn "unix_chkpwd does not have the $CHKPWD_ID bit set so local password authentication will fail" \
            "$CONTINUE_MSG"
        [ $? -eq $NO ] && exit 1
    fi
}

# Test the connection MapR Techonolgies, Inc. If a
# connection exists, then use the MapR URLs. Othewise,
# prompt the user for the location of the MapR archive tarball
check_connection() {
    # If a MapR package tarball has been given, use that as the default
    ISCONNECTED=$NO
    if [ $TEST_CONNECT -eq $YES ]; then
        msg "Testing connection to $MAPR_INSTALLER_URL...\c"
        if which curl > /dev/null 2>&1; then
            $CURL_NOSAVE "$MAPR_INSTALLER_URL" && ISCONNECTED=$YES
        elif which wget > /dev/null 2>&1; then
            $WGET "$MAPR_INSTALLER_URL" -O /dev/null && ISCONNECTED=$YES
        elif [ -n "$MAPR_INSTALLER_PACKAGES" ]; then
            msg_err "Connectivity to $MAPR_INSTALLER_URL required"
        fi
        [ $ISCONNECTED -eq $YES ] && success && return

        msg "...No connection found"
        msg "Without connectivity to MapR Technologies ($MAPR_INSTALLER_URL),
            a complete set of MapR archive tarballs are required to complete this setup"
    fi

    if [ -z "$MAPR_ARCHIVES" ]; then
        local file_cnt mapr_archives valid_file_cnt
        local prompt="Enter paths to MapR archives - 1 or more space separated files"

        while true; do
            prompt "$prompt" "$MAPR_ARCHIVES"
            file_cnt=0
            mapr_archives=""
            valid_file_cnt=0
            for af in $ANSWER ; do
                let file_cnt=file_cnt+1
                if [ -f "$af" ]; then
                    mapr_archives="$mapr_archives $(cd $(dirname $af); pwd)/$(basename $af)"
                    let valid_file_cnt=valid_file_cnt+1
                else
                    msg_warn "$af: no such file"
                fi
            done
            [ $file_cnt -eq $valid_file_cnt ] && break
        done
        MAPR_ARCHIVES="$mapr_archives"
    fi

    msg "\nCreating local repo from $MAPR_ARCHIVES...\c"
    check_port_80

    prompt "Enter the web server filesystem directory to extract MapR archives to" "$HTTPD_REPO"
    HTTPD_REPO="$ANSWER"

    prompt "\nEnter web server url for this path" "http://$HOST_INTERNAL/$(basename $HTTPD_REPO)"
    MAPR_ECO_URL="$ANSWER"
    MAPR_CORE_URL="$ANSWER"

    msg "\nExtracting packages from $MAPR_ARCHIVES...\c"
    [ -d "$HTTPD_REPO/installer" ] && rm -rf "$HTTPD_REPO"
    mkdir -p "$HTTPD_REPO"
    for af in $MAPR_ARCHIVES ; do
        if ! tar -xvzf $af -C "$HTTPD_REPO"; then
            msg_err "Unable to extract archive file"
        fi
    done
    success $YES
}

# Test if JDK 7 or higher is installed
check_jdk() {
    # if javac exists, then JDK-devel has been installed
    msg "Testing for JDK 7 or higher..."
    [ -n "$JAVA_HOME" ] && JAVA_HOME_OLD=$JAVA_HOME

    # determine what kind of Java env we have
    check_java_env
    if [ -z "$JAVA_HOME" ]; then
        # try again to see if we have a valid JRE
        JDK_REQUIRED=0
        check_java_env
        if [ -n "$JAVA_HOME" ]; then
            JAVA=$JAVA_HOME/bin/java
            JDK_UPGRADE_JRE=1
        fi
    else
        JAVA=$JAVA_HOME/bin/java
    fi
    if [ -n "$JAVA" -a -e "$JAVA" ]; then
        JDK_VER=$($JAVA_HOME/bin/java -version 2>&1 | head -n1 | cut -d. -f2)
    fi

    # check if javac is actually valid and exists
    local msg

    if [ -n "$JAVA_HOME" -a $JDK_UPGRADE_JRE -eq $YES ]; then
        msg="Upgrading JRE to JDK 1.$JDK_VER"
        force_jdk_version $JDK_VER
    elif [ -z "$JAVA_HOME" ]; then
        if [ "$OS" == "ubuntu" -a $OSVER_MAJ -ge 16 ]; then
            force_jdk_version 8
        fi
        msg="JDK not found - installing $OPENJDK..."
    else
        msg="Ensuring existing JDK 1.$JDK_VER is up to date..."
    fi
    fetch_jdk "$msg"
    success
}

# validate current OS
check_os() {
    if ! which ping > /dev/null 2>&1 ; then
        [ $CONTAINER -eq $NO ] && msg_err "ping command not found"
    elif [ -z "$HOST" ] || ! ping -c 1 -q "$HOST" > /dev/null 2>&1 ; then
        msg_err "Hostname ($HOST) cannot be resolved. Correct the problem and retry $CMD"
    fi
    if [ -f /etc/redhat-release ]; then
        OS=redhat
        OSNAME=$(cut -d' ' -f1 < /etc/redhat-release)
        OSVER=$(grep -o -P '[0-9\.]+' /etc/redhat-release | cut -d. -f1,2)
        OSVER_MAJ=$(grep -o -P '[0-9\.]+' /etc/redhat-release | cut -d. -f1)
        OSVER_MIN=$(grep -o -P '[0-9\.]+' /etc/redhat-release | cut -d. -f2)
        SUPPORTED_RELEASES=( "${SUPPORTED_RELEASES_RH[@]}" )
    elif [ -d /etc/mach_init.d ]; then
        OS=darwin
        OSVER=$(uname -r)
        OSVER_MAJ=$(echo $OSVER | cut -d\. -f1)
        OSVER_MIN=$(echo $OSVER | cut -d\. -f2)
    elif grep -q -s SUSE /etc/os-release ; then
        OS=suse
        if [ -f /etc/os-release ]; then
            OSVER=$(grep VERSION_ID /etc/os-release | cut -d\" -f2)
            OSVER_MAJ=$(echo $OSVER | cut -d\. -f1)
            OSVER_MIN=$(echo $OSVER | cut -d\. -f2)
        else
            OSVER=$(grep VERSION /etc/SuSE-release | cut -d= -f2 | tr -d '[:space:]')
            OSVER_MAJ=$OSVER
            OSPATCHLVL=$(grep PATCHLEVEL /etc/SuSE-release | cut -d= -f2 | tr -d '[:space:]')
            if [ -n "$OSPATCHLVL" ]; then
                OSVER=$OSVER.$OSPATCHLVL
                OSVER_MIN=$OSPATCHLVL
            fi
        fi
        SUPPORTED_RELEASES=( "${SUPPORTED_RELEASES_SUSE[@]}" )
    elif grep -q -s DISTRIB_ID=Ubuntu /etc/lsb-release; then
        OS=ubuntu
        OSVER=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d= -f2)
        OSVER_MAJ=$(echo $OSVER | cut -d\. -f1)
        OSVER_MIN=$(echo $OSVER | cut -d\. -f2)
        SSHD=ssh
        SUPPORTED_RELEASES=( "${SUPPORTED_RELEASES_UBUNTU[@]}" )
        export DEBIAN_FRONTEND=noninteractive
    else
        msg_err "$CMD must be run on RedHat, CentOS, SUSE, or Ubuntu Linux"
    fi
    if [ $(uname -m) != "x86_64" ]; then
        msg_err "$CMD must be run on a 64 bit version of Linux"
    fi
    [ $OS != "darwin" ] && check_checkpwd
    case $OS in
    redhat) OSPKG="RPM" ;;
    suse) OSPKG="SUSE" ;;
    ubuntu) OSPKG="DEB" ;;
    esac
    eval HTTPD="\$HTTPD_$OSPKG"
    eval OPENJDK="\$OPENJDK_$OSPKG"
}

# check for supported OS version
check_os_version() {
    local supported=$NO
    shift 2
    for sr in ${SUPPORTED_RELEASES[@]} ; do
        if [ "$sr" == "$OSVER" ]; then
            supported=$YES
            break
        fi
    done
    if [ ! $supported ]; then
        prompt_warn "$OS release '$OSVER' is not supported" "$CONTINUE_MSG"
        [ $? -eq $NO ] && exit 1
    fi
}

# Is there a webserver and is it listening on port 80.
# If port 80 is not listening, assume there's no web service.
# Prompt the user on whether to install apache2/httpd or continue
check_port_80() {
    local rc=$YES

    # If nothing is returned, then port 80 is not active
    if $(ss -lnt "( sport = :80 or sport = :443 )" | grep -q LISTEN); then
        msg "Existing web server will be used to serve packages from this system"
    else
        msg "No web server detected, but one is required to serve packages from this system"

        prompt_warn "" "Would you like to install a webserver on this system?"
        rc=$?
        [ $rc -eq $YES ] && fetch_web_server
    fi
    return $rc
}

# ensure that root and admin users have correct permissions
check_sudo() {
    if ! su $MAPR_USER -c "id $MAPR_USER" > /dev/null 2>&1 ; then
        msg_err "User 'root' is unable to run services as user '$MAPR_USER'. Correct the problem and retry $CMD"
    fi
    dir=$(getent passwd $MAPR_USER | cut -d: -f6)
    if [ -z "$dir" ] ; then
        msg_err "User '$MAPR_USER' does not have a home directory configured. Correct the problem and retry $CMD"
    fi
    if [ -d "$dir" ] && ! su $MAPR_USER -c "test -O $dir -a -w $dir" ; then
        msg_err "User '$MAPR_USER' does not own and have permissions to write to '$dir'. Correct the problem and retry $CMD"
    fi
    gid=$(stat -c '%G' /etc/shadow)
    if [ $MAPR_USER_CREATE -eq $NO ] && ! id -Gn $MAPR_USER | grep -q $gid ; then
        msg_warn "User '$MAPR_USER' must be in group '$gid' to allow UNIX authentication"
    fi
    success
}

cli_process() {
    msg "Starting the installer..."
    start_service_installer
    $WGET "-t 5 --retry-connrefused --waitretry=30" https://$MAPR_HOST
    success $YES
    local maprcli="$MAPR_INSTALLER_DIR/bin/mapr-installer-cli"
    [ ! -f "$maprcli" ] && msg_err "Installer CLI not found"
    msg "Invoking the MapR installer client..."
    sudo -u $MAPR_USER $maprcli "$@"
    success
}

# If a 'mapr' user account does not exist or a user
# defined account does not exist, create a 'mapr' user account
create_user() {
    local acct_type=${1:-admin}

    msg "\nTesting for cluster $acct_type account..."
    tput sgr0
    prompt "Enter MapR cluster $acct_type name" "$MAPR_USER"
    TMP_USER=$ANSWER
    while [ "$TMP_USER" = root -a "$acct_type" != "user" ]; do
        msg_warn "Cluster $acct_type cannot be root user"
        prompt "Enter MapR cluster $acct_type name" "$MAPR_USER"
        TMP_USER=$ANSWER
    done
    MAPR_USER=$TMP_USER
    local passwd_entry=$(getent passwd $MAPR_USER)
    TMP_UID=$(echo $passwd_entry | cut -d':' -f3)
    TMP_GID=$(echo $passwd_entry | cut -d':' -f4)

    # some docker containers (SUSE) do not have a shadow file
    if [ ! -f /etc/shadow ]; then
        msg "\nCreating shadow file"
        touch /etc/shadow
        chmod 600 /etc/shadow
    fi

    # If the given/default user name is valid, set the
    # returned uid and gid as the mapr user
    if [ -n "$TMP_UID" -a -n "$TMP_GID" ]; then
        MAPR_UID=$TMP_UID
        MAPR_GID=$TMP_GID
        MAPR_GROUP=$(getent group $MAPR_GID | cut -d: -f1)
        check_sudo
        return
    fi

    msg "\nUser '$MAPR_USER' does not exist. Creating new cluster $acct_type account..."

    # ensure that the given/default uid doesn't already exist
    if getent passwd $MAPR_UID > /dev/null 2>&1 ; then
        MAPR_UID=""
    fi
    prompt "Enter '$MAPR_USER' uid" "$MAPR_UID"
    TMP_UID=$ANSWER
    while getent passwd $TMP_UID > /dev/null 2>&1 ; do
        msg_warn "uid $TMP_UID already exists"
        prompt "Enter '$MAPR_USER' uid" "$MAPR_UID"
        TMP_UID=$ANSWER
    done
    MAPR_UID=$TMP_UID
    # prompt the user for the mapr user's group
    prompt "Enter '$MAPR_USER' group name" "$MAPR_GROUP"
    MAPR_GROUP=$ANSWER

    set -- $(getent group $MAPR_GROUP | tr ':' ' ')
    TMP_GID=$3

    # if the group id does not exist, then this is a new group
    if [ -z "$TMP_GID" ]; then
        # ensure that the default gid does not already exist
        if getent group $MAPR_GID > /dev/null 2>&1 ; then
            MAPR_GID=""
        fi

        # prompt the user for a group id
        prompt "Enter '$MAPR_GROUP' gid" "$MAPR_GID"
        TMP_GID=$ANSWER

        # verify that the given group id doesn't already exist
        while getent group $TMP_GID > /dev/null 2>&1 ; do
msg_warn "gid $TMP_GID already exists"
            prompt "Enter '$MAPR_GROUP' gid" "$MAPR_GID"
            TMP_GID=$ANSWER
        done

        # create the new group with the given group id
        RESULTS=$(groupadd -g $TMP_GID $MAPR_GROUP 2>&1)
        if [ $? -ne 0 ]; then
            msg_err "Unable to create group $MAPR_GROUP: $RESULTS"
        fi
        MAPR_GROUP_CREATE=$YES
    fi
    MAPR_GID=$TMP_GID

    # prompt for password
    [ -z "$MAPR_PASSWORD" -a $PROMPT_SILENT -eq $YES ] && MAPR_PASSWORD=$MAPR_USER
    prompt "Enter '$MAPR_USER' password" "$MAPR_PASSWORD" -s
    MAPR_PASSWORD=$ANSWER
    if [ $PROMPT_SILENT -eq $YES ]; then
        TMP_PASSWORD=$ANSWER
    else
        prompt "Confirm '$MAPR_USER' password" "" -s
        TMP_PASSWORD=$ANSWER
    fi
    while [ "$MAPR_PASSWORD" != "$TMP_PASSWORD" ]; do
        msg_warn "Password for '$MAPR_USER' does not match"
        prompt "Enter '$MAPR_USER' password" "" -s
        MAPR_PASSWORD=$ANSWER
        prompt "Confirm '$MAPR_USER' password" "" -s
        TMP_PASSWORD=$ANSWER
    done

    # create the new user with the default/given uid and gid
    # requires group read access to /etc/shadow for PAM auth
    RESULTS=$(useradd -m -u $MAPR_UID -g $MAPR_GID -G $(stat -c '%G' /etc/shadow) $MAPR_USER 2>&1)
    if [ $? -ne 0 ]; then
        msg_err "Unable to create user $MAPR_USER: $RESULTS"
    fi

    passwd $MAPR_USER > /dev/null 2>&1 << EOM
$MAPR_PASSWORD
$MAPR_PASSWORD
EOM
    MAPR_USER_CREATE=$YES
    check_sudo
}

# Refresh package manager and install package dependencies
fetch_dependencies() {
    local pkgs=$(echo "$1" | tr '[:lower:]' '[:upper:]')

    msg "\nInstalling $1 package dependencies..."
    case $OS in
    redhat)
        [ $pkgs = "INSTALLER" ] && rm -f /etc/yum.repos.d/mapr_installer.repo
        if [ "$MAPR_CORE_URL" = "$MAPR_ECO_URL" ]; then
            yum -q clean expire-cache
        else
            yum -q clean all
        fi
        if (! command -v sshpass  >/dev/null 2>&1 || [ $OSVER_MAJ -lt 7 ] ) && \
            ! rpm -qa | grep -q epel-release; then
            yum -q -y install epel-release
            if [ $? -ne 0 ]; then
                if [ $NOINET -eq $YES ]; then
                    msg_err "Unable to install epel-release package - set up a local repo"
                else
                    if grep -q " 7." /etc/redhat-release; then
                        yum -q -y install $EPEL7_URL
                   elif grep -q " 6." /etc/redhat-release; then
                        yum -q -y install $EPEL6_URL
                    fi
                    [ $? -ne 0 ] && msg_err "Unable to install epel-release package"
                fi
            fi
        fi
        local disable_epel
        rpm -qa | grep -q epel-release && disable_epel="--disablerepo=epel"
        yum $disable_epel -q -y update ca-certificates
        eval pkgs="\$DEPENDENCY_${pkgs}_RPM"
        yum -q -y install $pkgs
        ;;
    suse)
        [ $pkgs = "INSTALLER" ] && rm -f /etc/zypp/repos.d/mapr_installer.repo
        zypper --non-interactive -q refresh
        zypper --non-interactive -q install ca-certificates
        eval pkgs="\$DEPENDENCY_${pkgs}_SUSE"
        if [ "$1" = "server" ]; then
            [ $OSVER_MAJ -ge 12 ] && pkgs="$pkgs python-pycurl" || pkgs="$pkgs python-curl"
        fi
        if zypper --non-interactive -q install -n $pkgs; then
            if [ -e /usr/lib64/libcrypto.so.1.0.0 ]; then
                ln -f -s /usr/lib64/libcrypto.so.1.0.0 /usr/lib64/libcrypto.so.10
            elif [ -e /lib64/libcrypto.so.1.0.0 ]; then
                ln -f -s /lib64/libcrypto.so.1.0.0 /lib64/libcrypto.so.10
            fi
            if [ -e /usr/lib64/libssl.so.1.0.0 ]; then
                ln -f -s /usr/lib64/libssl.so.1.0.0 /usr/lib64/libssl.so.10
            elif [ -e /lib64/libssl.so.1.0.0 ]; then
                ln -f -s /lib64/libssl.so.1.0.0 /lib64/libssl.so.10
            fi
        else
            false
        fi
        ;;
    ubuntu)
        [ $pkgs = "INSTALLER" ] && rm -f /etc/apt/sources.list.d/mapr_installer.list
        apt-get update -qq
        apt-get install -qq -y ca-certificates
        eval pkgs="\$DEPENDENCY_${pkgs}_DEB"
        apt-get install -qq -y $pkgs
        ;;
    esac
    if [ $? -ne 0 ]; then
        msg_err "Unable to install dependencies ($*). Ensure that a core OS repo is enabled and retry $CMD"
    fi
    success $YES
}

# Install RedHat/CentOS installer package
fetch_installer_redhat() {
    msg "\nInstalling installer packages..."
    setenforce 0 > /dev/null 2>&1
    if [ -n "$MAPR_INSTALLER_PACKAGES" ]; then
        yum -q -y install $MAPR_INSTALLER_PACKAGES
    elif [ "$ISCONNECTED" = "$YES" ]; then
        # Create the mapr-installer repository information file
        [ "$MAPR_CORE_URL" = "$MAPR_ECO_URL" ] && subdir="/redhat"
        local dir=REPO_PATH_redhat
        local ext=REPO_EXT_redhat
        repo_add_redhat "${!dir}/mapr_installer.${!ext}" "$MAPR_INSTALLER_URL$subdir" "Installer"
        yum -q clean expire-cache
        [ $CONTAINER -eq $NO ] && yum -q -y makecache fast 2>&1 | fgrep 'Not using' > /dev/null
        [ $? -eq 0 ] && yum clean all --disablerepo="*" --enablerepo=MapR_Installer
        yum --disablerepo=* --enablerepo=MapR_Installer -q -y install \
            mapr-installer-definitions mapr-installer
    else
        (cd "$HTTPD_REPO/installer/redhat"; yum -q -y --nogpgcheck localinstall mapr-installer*)
    fi
    if [ $? -ne 0 ]; then
        msg_err "Unable to install packages. Correct the error and retry $CMD"
    fi
    [ $CONTAINER -eq $YES ] && yum clean all
    # disable firewall on initial install
    if [ $USE_SYSTEMCTL -eq $YES ]; then
        systemctl disable firewalld > /dev/null 2>&1
        systemctl --no-ask-password stop firewalld > /dev/null 2>&1
        systemctl disable iptables > /dev/null 2>&1
        systemctl --no-ask-password stop iptables > /dev/null 2>&1
    else
        service iptables stop > /dev/null 2>&1 && chkconfig iptables off > /dev/null 2>&1
    fi
    success $YES
}

fetch_installer_suse() {
    msg "Installing installer packages..."
    if [ -n "$MAPR_INSTALLER_PACKAGES" ]; then
        zypper --non-interactive -q install -n $MAPR_INSTALLER_PACKAGES
    elif [ $ISCONNECTED -eq $YES ]; then
        # Create the mapr-installer repository information file
        [ "$MAPR_CORE_URL" = "$MAPR_ECO_URL" ] && subdir="/suse"
        local dir=REPO_PATH_suse
        local ext=REPO_EXT_suse
        repo_add_suse "${!dir}/mapr_installer.${!ext}" "$MAPR_INSTALLER_URL$subdir" "Installer"
        zypper --non-interactive -q install -n mapr-installer-definitions mapr-installer
    else
        (cd "$HTTPD_REPO/installer/suse"; zypper --non-interactive -q install -n ./mapr-installer*)
    fi

    if [ $? -ne 0 ]; then
        msg_err "Unable to install packages. Correct the error and retry $CMD"
    fi
    success $YES
}

fetch_installer_ubuntu() {
    msg "Installing installer packages..."
    aptsources="-o Dir::Etc::SourceList=$REPO_PATH_ubuntu/mapr_installer.list"
    if [ -n "$MAPR_INSTALLER_PACKAGES" ]; then
        dpkg -i $MAPR_INSTALLER_PACKAGES
        apt-get update -qq
        apt-get install -f --force-yes -y
    elif [ "$ISCONNECTED" = "$YES" ]; then
        # Create the custom source list file
        mkdir -p $REPO_PATH_ubuntu
        [ "$MAPR_CORE_URL" = "$MAPR_ECO_URL" ] && subdir="/ubuntu"
        local dir=REPO_PATH_ubuntu
        local ext=REPO_EXT_ubuntu
        # update repo info and install mapr-installer assuming new repo struct
        repo_add_ubuntu "${!dir}/mapr_installer.${!ext}" "$MAPR_INSTALLER_URL$subdir binary trusty" "Installer"
        apt-get -qq $aptsources update 2> /dev/null
        if [ $? -ne 0 ]; then
            # update repo info and install mapr-installer assuming old repo struct
            repo_add_ubuntu "${!dir}/mapr_installer.${!ext}" "$MAPR_INSTALLER_URL$subdir binary/" "Installer"
            apt-get -qq $aptsources update 2> /dev/null
            [ $? -ne 0 ] && msg_err "Repository url is invalid: $MAPR_INSTALLER_URL"
        fi
        apt-get $aptsources -qq install -y --force-yes mapr-installer-definitions mapr-installer
    else
        (cd "$HTTPD_REPO/installer/ubuntu"; dpkg -i mapr-installer*)
    fi
    if [ $? -ne 0 ]; then
        msg_err "Unable to install packages. Correct the error and retry $CMD"
    fi
    success $YES
}

# install OpenJDK if no JRE version found that can be upgraded to full JDK
fetch_jdk() {
    local msg=$1 warn_msg=""

    if [ -n "$JAVA_HOME" -a $JDK_UPGRADE_JRE -eq $NO ]; then
        # ensure the latest version of currently installed JDK
        JDK_UPDATE_ONLY=$YES
    elif [ -n "$JAVA_HOME" ]; then
        if [ -n "$JAVA_HOME_OLD" ]; then
            if [ "$JAVA_HOME" = "$JAVA_HOME_OLD" -a $JDK_UPGRADE_JRE -eq $YES ]; then
                warn_msg="JAVA_HOME is set to a JRE which is insufficient. $CMD can upgrade it to a full JDK"
            else
                warn_msg="JAVA_HOME is set to a JDK that is missing or too old. $CMD can install a more current version"
            fi
        else
            warn_msg="JAVA_HOME is not set, but found a JRE which is insufficient. $CMD can upgrade it to a full JDK"
        fi
        prompt_warn "$warn_msg" \
            "Continue and upgrade JDK 1.$JDK_VER? If no, either manually install a JDK or remove JAVA_HOME from /etc/profile or login scripts and retry $CMD"
        [ $? -eq $NO ] && exit 1
    fi
    msg "$msg"
    case $OS in
    redhat)
        if [ $JDK_UPDATE_ONLY -eq $YES ]; then
            JDK_PKG=$(rpm -q --whatprovides $JAVA_HOME/bin/javac 2> /dev/null)
            if [ $? -eq 0 -a -n "$JDK_PKG" ]; then
                OPENJDK=$JDK_PKG
                yum -q -y upgrade $OPENJDK
            fi
        else
            yum -q -y install $OPENJDK
        fi
        ;;
    suse)
        if [ $JDK_UPDATE_ONLY -eq $YES ]; then
            JDK_PKG=$(rpm -q --whatprovides $JAVA_HOME/bin/javac 2> /dev/null)
            if [ $? -eq 0 -a -n "$JDK_PKG" ]; then
                OPENJDK=$JDK_PKG
            fi
        fi
        zypper --non-interactive -q install -n $OPENJDK
        ;;
    ubuntu)
        if [ $JDK_UPDATE_ONLY -eq $YES ]; then
            JDK_PKG=$(dpkg-query -S $JAVA_HOME/bin/javac 2> /dev/null | cut -d: -f1)
            if [ $? -eq 0 -a -n "$JDK_PKG" ]; then
                OPENJDK=$JDK_PKG
            fi
        fi
        apt-get install -qq -y --force-yes $OPENJDK
        ;;
    esac
    if [ $? -ne 0 ]; then
        msg_err "Unable to install JDK $JDK_VER ($OPENJDK). Install manually and retry $CMD"
    fi
}

# Install and start apache2/httpd if no web server found
fetch_web_server() {
    msg "Installing web server..."
    case $OS in
    redhat) yum -q -y install $HTTPD ;;
    suse) zypper --non-interactive -q install -n $HTTPD ;;
    ubuntu) apt-get install -qq -y $HTTPD ;;
    esac

    if [ $? -ne 0 ]; then
        msg_err "Unable to install web server '$HTTPD'. Correct the error and retry $CMD"
    fi

    # start newly installed web service
    setup_service $HTTPD
}

# Set full JDK version corresponding to current JRE
force_jdk_version() {
    local pkg

    case $OS in
    redhat) pkg="OPENJDK_RPM_$1" ;;
    suse) pkg="OPENJDK_SUSE_$1" ;;
    ubuntu) pkg="OPENJDK_DEB_$1" ;;
    esac
    OPENJDK=${!pkg}
}

# determine cloud environment and public hostnames if possible
get_environment() {
    # if host is in EC2 or GCE, find external IP address from metadata server
    RESULTS=$($CURL http://169.254.169.254/latest/meta-data/public-hostname)
    [ $? -eq 0 ] && ! echo $RESULTS | grep '[<>="/:\?\&\+\(\)\;]' > /dev/null 2>&1 && \
        HOST=$RESULTS && MAPR_ENVIRONMENT=amazon && return
    RESULTS=$($CURL --header "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/hostname)
    [ $? -eq 0 ] && HOST=$RESULTS && MAPR_ENVIRONMENT=google && return

    RESULTS=$($CURL http://ipinfo.io)
    if [ $? -eq 0 ]; then
        # no reliable way to find azure external hostname yet
        m_hn=$(json_field "$RESULTS" '"hostname":')
        m_hn=$(echo "$m_hn" | fgrep -vi "No Hostname")
        echo "$m_hn" | fgrep -qi azure.com && HOST=$m_hn
        m_org=$(json_field "$RESULTS" '"org":')
        m_org=$(echo $m_org | fgrep -i "Microsoft Corporation")
        m_dns=$(grep 'cloudapp.net' /etc/resolv.conf)
        [ -n "$m_org" -a -n "$m_dns" ] && MAPR_ENVIRONMENT=azure && return
    fi
    local pidnum=1
    [ -f "/proc/1/sched" ] && pidnum=$(cat /proc/1/sched | head -n 1|cut -d ',' -f1|cut -d '(' -f2)
    [ "$pidnum" -ne 1 ] && MAPR_ENVIRONMENT=docker && return
}

get_versions_redhat() {
    MAPR_DEF_VERSION=$(rpm -q --queryformat '%{VERSION}\n' mapr-installer-definitions | tail -n1)
    MAPR_SERVER_VERSION=$(rpm -q --queryformat '%{VERSION}\n' mapr-installer | tail -n1)
}

get_versions_suse() {
    MAPR_DEF_VERSION=$(rpm -q --queryformat '%{VERSION}\n' mapr-installer-definitions | tail -n1)
    MAPR_SERVER_VERSION=$(rpm -q --queryformat '%{VERSION}\n' mapr-installer | tail -n1)
}

get_versions_ubuntu() {
    MAPR_DEF_VERSION=$(dpkg -s mapr-installer-definitions | grep -i version | head -1 | awk '{print $NF}')
    MAPR_SERVER_VERSION=$(dpkg -s mapr-installer | grep -i version | head -1 | awk '{print $NF}')
}

package_cleanup_redhat() {
    yum clean all -q
}

package_cleanup_suse() {
    zypper clean -a
}

package_cleanup_ubuntu() {
    apt-get autoremove --purge -q -y
    rm -rf /var/lib/apt/lists/*
    apt-get clean -q
}

package_install_redhat() {
    yum -y install $* || msg_err "Could not install packages ($*)"
}

package_install_suse() {
    zypper --non-interactive install -n $* || \
        msg_err "Could not install packages ($*)"
}

package_install_ubuntu() {
    apt-get install --no-install-recommends -q -y $* || \
        msg_err "Could not install packages ($*)"
}

repo_add_error() {
    msg_err "Could not import repo key $MAPR_GPG_KEY_URL"
}

repo_add_redhat() {
    rpm --import $MAPR_GPG_KEY_URL || repo_add_error
    cat > $1 << EOM
[MapR_$3]
name=MapR $3 Components
baseurl=$2
gpgcheck=1
enabled=1
protected=1
EOM
}

repo_add_suse() {
    rpm --import $MAPR_GPG_KEY_URL || repo_add_error
    cat > $1 << EOM
[MapR_$3]
name=MapR $3 Components
baseurl=$2
gpgcheck=1
enabled=1
autorefresh=1
type=rpm-md
EOM
}

repo_add_ubuntu() {
    apt-key adv --fetch-keys $MAPR_GPG_KEY_URL || repo_add_error
    cat > $1 << EOM
deb $2
EOM
    apt-get -qq update
}

set_port() {
    local host port first_time=1

    while [ -z "$port" ]; do
        if [ $first_time -eq 1 ]; then
            # loop through once to ensure MAPR_HOST contains both a
            # hostname and port number before using it in the prompt
            ANSWER=$MAPR_HOST
        else
            prompt "Enter [host:]port that cluster nodes connect to this host on" "$MAPR_HOST"
        fi
        host=$(echo $ANSWER | cut -d: -f1)
        port=$(echo $ANSWER | cut -s -d: -f2)
        if [ -z "$port" ]; then
            case $host in
            ''|*[!0-9]*) port=$MAPR_PORT ;;
            *) port=$host && host=$HOST ;;
            esac
        else
            case $port in
            ''|*[!0-9]*)
                msg_warn "Port must be numeric ($port)"
                # make sure we don't loop forever
                [ $PROMPT_SILENT -eq $YES ] && exit $ERROR
                unset port ;;
            esac
        fi
        if [ $first_time -eq 1 ]; then
            if [ -z $port ]; then
                MAPR_HOST="$host:$MAPR_PORT"
            else
                MAPR_HOST="$host:$port"
                unset port
           fi
            first_time=0
        fi
    done
    HOST=$host
    MAPR_HOST=$host
    MAPR_PORT=$port
}

setup_service() {
    local enabled=$NO

    if [ $USE_SYSTEMCTL -eq $YES ]; then
        systemctl is-enabled $1 >/dev/null 2>&1 && enabled=$YES
    else
        local cmd="chkconfig"
        type sysv-rc-conf > /dev/null 2>&1 && cmd="sysv-rc-conf"
        $cmd --list $1 2> /dev/null | grep -q 3:on && enabled=$YES
        command -v $cmd > /dev/null 2>&1 || \
            msg_warn "$cmd not found. Services will not be enabled or disabled"
    fi
    if [ ${2:-$YES} -eq $YES ]; then
        [ $enabled -eq $NO ] || setup_service_cmd enable $1 || \
            msg_warn "Could not enable service $1"
        # RC scripts fail if service already running
        setup_service_cmd start $1 || \
            msg_err "Could not start service $1"
        msg "Started service $1"
    else
        if [ $enabled -eq $YES ]; then
            setup_service_cmd disable $1 || \
                msg_error "Could not disable service $1"
            msg "Disabled service $1"
        fi
        setup_service_cmd stop $1 >/dev/null 2>&1 && msg "Stopped service $1"
    fi
}

setup_service_cmd() {
    local svc_file1=/etc/init.d/$2
    local svc_file2=/etc/rc.d/init.d/$2

    if [ $USE_SYSTEMCTL -eq $YES ]; then
        systemctl $1 $2
    elif [ -f $svc_file1 ] || [ -f $svc_file2 ]; then
        [ $1 = "enable" -o $1 = "disable" ] && return
        [ -f $svc_file1 ] && $svc_file1 $1 && return
        [ -f $svc_file2 ] && $svc_file2 $1 && return
    else
        local cmd=service
        local new_state=$1
        if [ $1 = "enable" -o $1 = "disable" ]; then
            type sysv-rc-conf > /dev/null 2>&1 && cmd=sysv-rc-conf || cmd=chkconfig
            [ $1 = "enable" ] && new_state=on || new_state=off
        fi
        $cmd $2 $new_state
    fi
}

setup_service_fuse() {
    [ ! -f $MAPR_FUSE_FILE ] && return
    sed -i -e "s|^source|export MAPR_TICKETFILE_LOCATION=$MAPR_TICKETFILE_LOCATION\n&|" \
        "$MAPR_HOME/initscripts/$MAPR_PACKAGE_POSIX"
    # FUSE start script requires flock which brings in 250mb RH OS update
    if ! which flock >/dev/null 2>&1; then
        ln -s $(which true) /usr/local/bin/flock
    fi
    setup_service $MAPR_PACKAGE_POSIX $NO
    chmod u+s "$MAPR_HOME/bin/fusermount"
}

setup_service_sshd() {
    if [ -z "$MAPR_DOCKER_NETWORK" -o "$MAPR_DOCKER_NETWORK" = "bridge" ]; then
        setup_service $SSHD
    else
        setup_service $SSHD $NO
    fi
}

start_service_installer() {
    if [ $USE_SYSTEMCTL -eq $YES ]; then
        RESULTS=$(systemctl --no-ask-password start mapr-installer)
    else
        RESULTS=$(service mapr-installer condstart)
    fi
    [ $? -ne 0 ] && msg_err "mapr-installer start failed: $RESULTS"
}

sudoers_add() {
    cat > $MAPR_SUDOERS_FILE << EOM
$MAPR_USER      ALL=(ALL)       NOPASSWD:ALL
Defaults:$MAPR_USER             !requiretty
EOM
    chmod 0440 $MAPR_SUDOERS_FILE
}

# code run inside Docker containers
container_check_environment() {
    # MAPR_SECURITY, MAPR_OT_HOSTS, MAPR_HS_HOST optional
    [ -z "$MAPR_CLUSTER" ] && msg_err "MAPR_CLUSTER must be set"
    [ -z "$MAPR_DISKS" ] && msg_err "MAPR_DISKS must be set"
    if [ -z "$MAPR_CLDB_HOSTS" ]; then
        msg "MAPR_CLDB_HOSTS not set - using $HOST"
        MAPR_CLDB_HOSTS=$HOST
    fi
    if [ -z "$MAPR_ZK_HOSTS" ]; then
        msg "MAPR_ZK_HOSTS not set - using $HOST"
        MAPR_ZK_HOSTS=$HOST
    fi
}

container_cleanup_installer() {
    rm -rf $MAPR_DATA_DIR
    rm -rf $MAPR_INSTALLER_DIR/lib/swagger-codegen*.jar
    find / -name *.a -exec rm {} +
}

container_configure_client() {
    if [ $CONTAINER_INITIALIZED -eq $YES ]; then
        msg "Container already initialized"
        return
    fi
    [ -z "$MAPR_CLUSTER" ] && msg_err "MAPR_CLUSTER must be set"
    [ -z "$MAPR_CLDB_HOSTS" ] && msg_err "MAPR_CLDB_HOSTS must be set"
    . $MAPR_HOME/conf/env.sh
    local args="$args -c -C $MAPR_CLDB_HOSTS -N $MAPR_CLUSTER"
    [ -n "$MAPR_TICKETFILE_LOCATION" ] && args="$args -secure"
    [ $VERBOSE -eq $YES ] && args="$args -v"
    msg "Configuring MapR client ($args)..."
    container_configure_output $args
    chown -R $MAPR_USER:$MAPR_GROUP "$MAPR_HOME"
    chown -fR root:root "$MAPR_HOME/conf/proxy"
}

container_configure_output() {
    if $CONTAINER_CONFIGURE_SCRIPT "$@" 2>&1; then
        CONTAINER_INITIALIZED=$YES
        success $YES
    else
        rm -f $CONTAINER_CLUSTER_CONF
        msg_err "CONTAINER_CONFIGURE_SCRIPT failed with code $1"
    fi
}

container_configure_server() {
    local LICENSE_MODULES="${MAPR_LICENSE_MODULES:-DATABASE,HADOOP,STREAMS}"
    local CLDB_HOSTS="${MAPR_CLDB_HOSTS:-$HOST}"
    local ZK_HOSTS="${MAPR_ZK_HOSTS:-$HOST}"
    local args

    if [ -f "$CONTAINER_CLUSTER_CONF" ]; then
        args=-R
        [ $VERBOSE -eq $YES ] && args="$args -v"
        msg "Re-configuring MapR services ($args)..."
        container_configure_output $args
        return
    fi
    . $MAPR_HOME/conf/env.sh
    [ -n "$MAPR_HS_HOST" ] && args="$args -HS $MAPR_HS_HOST"
    [ -n "$MAPR_OT_HOSTS" ] && args="$args -OT $MAPR_OT_HOSTS"
    if [ -n "$CLDB_HOSTS" ]; then
        args="$args -f -no-autostart -on-prompt-cont y -N $MAPR_CLUSTER -C $CLDB_HOSTS -Z $ZK_HOSTS -u $MAPR_USER -g $MAPR_GROUP"
        if [ "$MAPR_SECURITY" = "master" ]; then
            args="$args -secure -genkeys"
        elif [ "$MAPR_SECURITY" = "enabled" ]; then
            args="$args -secure"
        else
            args="$args -unsecure"
        fi
        [ -n "${LICENSE_MODULES##*DATABASE*}" -a -n "${LICENSE_MODULES##*STREAMS*}" ] && args="$args -noDB"
    else
        args="-R $args"
    fi
    [ $VERBOSE -eq $YES ] && args="$args -v"
    msg "Configuring MapR services ($args)..."
    container_configure_output $args
}

container_disk_setup() {
    local DISK_FILE="$MAPR_HOME/conf/disks.txt"
    local DISKSETUP="$MAPR_HOME/server/disksetup"
    local DISKTAB_FILE="$MAPR_HOME/conf/disktab"
    local FORCE_FORMAT=${FORCE_FORMAT:-$YES}
    local STRIPE_WIDTH=${STRIPE_WIDTH:-3}

    msg "Configuring disks..."
    if [ -f "$DISKTAB_FILE" ]; then
        msg "MapR disktab file $DISKTAB_FILE already exists. Skipping disk setup"
        return
    fi
    IFS=',' read -r -a disk_list_array <<< "$MAPR_DISKS"
    for disk in "${disk_list_array[@]}"; do
        echo "$disk" >> $DISK_FILE
    done
    sed -i -e 's/mapr/#mapr/g' /etc/security/limits.conf
    sed -i -e 's/AddUdevRules(list(gdevices));/#AddUdevRules(list(gdevices));/g' $MAPR_HOME/server/disksetup
    [ -x "$DISKSETUP" ] || msg_err "MapR disksetup utility $DISKSETUP not found"
    [ $FORCE_FORMAT -eq $YES ] && ARGS="$ARGS -F"
    [ $STRIPE_WIDTH -eq 0 ] && ARGS="$ARGS -M" || ARGS="$ARGS -W $STRIPE_WIDTH"
    $DISKSETUP $ARGS $DISK_FILE
    if [ $? -eq 0 ]; then
        success $NO "Local disks formatted for MapR-FS"
    else
        rc=$?
        rm -f $DISK_FILE $DISKTAB_FILE
        msg_err "$DISKSETUP failed with error code $rc"
    fi
}

container_install() {
    msg "Installing packages ($*)..."
    case "$*" in
    *"$MAPR_PACKAGES_CLIENT"*) package_install_$OS $MAPR_PACKAGES_CLIENT ;;
    esac
    case "$*" in
    *"mapr-pig"*)
        local ver=$(hadoop version | egrep -o "Hadoop [0-9]+.[0-9]+.[0-9]+" | egrep -o "[0-9]+.[0-9]+.[0-9]+")
        mkdir -p -m 777 /opt/mapr/hadoop/
        echo $ver > /opt/mapr/hadoop/hadoopversion
        ;;
    esac
    package_install_$OS $*
    package_cleanup_$OS
    success $YES
}

container_install_thin() {
    # choose last (most recent) file from HTML index
    msg "Downloading and installing $MAPR_PACKAGE_POSIX package..."
    local url="$MAPR_CORE_URL/v$1/$OS"
    local file=$($WGET --no-verbose -O- $url | \
        grep -o '<a .*href=.*>' | \
        sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | \
        grep 'mapr-thin-client.*.tar.gz$')

    [ -z "$file" ] && msg_err "Could not determine file name from $url"
    url="$url/$file"
    file="/tmp/$file"
    $WGET --tries=3 --waitretry=5 -O $file $url || \
        msg_err "Could not wget thin client from $url"
    tar -xf $file --directory=/opt/ || msg_err "Could not untar $file"
    rm -f $file
    ln -s $MAPR_HOME/initscripts/mapr-fuse /etc/init.d
    ln -s $MAPR_HOME/initscripts/$MAPR_PACKAGE_POSIX /etc/init.d
    package_cleanup_$OS
    success
}

# keep image running to prevent container shutdown
container_keep_alive() {
    if [ -z "$1" ]; then
        exec tail -f /dev/null
    else
        exec "$@"
    fi
}

container_post_client() {
    USE_SYSTEMCTL=$NO
    container_set_timezone
    [ $CONTAINER_INITIALIZED -eq $NO ] && container_user user
    container_configure_client
    container_start_fuse
    if [ $MAPR_CONTAINER_USER = root ]; then
        [ $# -ne 0 ] && local arg=-c
        container_keep_alive $SHELL -l $arg "$@"
    else
        [ $# -eq 0 ] && local arg=bash
        container_keep_alive sudo -E -H -n -u $MAPR_CONTAINER_USER \
            -g ${MAPR_CONTAINER_GROUP:-$MAPR_GROUP} $arg "$@"
    fi
}

container_post_installer() {
    PROMPT_SILENT=$YES
    USE_SYSTEMCTL=$NO
    MAPR_CORE_URL=$MAPR_PKG_URL
    MAPR_ECO_URL=$MAPR_PKG_URL
    container_set_timezone
    set_port
    MAPR_CONTAINER_USER=${MAPR_CONTAINER_USER:-$MAPR_USER}
    MAPR_CONTAINER_PASSWORD=${MAPR_CONTAINER_PASSWORD:-mapr}
    sudo passwd root > /dev/null 2>&1 << EOM
$MAPR_CONTAINER_PASSWORD
$MAPR_CONTAINER_PASSWORD
EOM
    [ $CONTAINER_INITIALIZED -eq $NO ] && container_user
    get_environment
    get_versions_$OS
    [ ! -f "$MAPR_PROPERTIES_FILE" ] && installer_properties_create
    $MAPR_BIN_DIR/create-ssl-keys.sh
    if [ "$OS" == "suse" ] || ( [ "$OS" == "redhat" ] && [ $OSVER_MAJ -ge 7 ] ); then
        ssh-keygen -A && /usr/sbin/sshd && container_start_services mapr-installer
    else
        container_start_services $SSHD mapr-installer
    fi
    # wait for installer to start completely
    $WGET -t 10 --no-check-certificate --retry-connrefused --waitretry=1 \
        -O /dev/null https://localhost:$MAPR_PORT || \
        msg_err "Unable to start Installer server"
    if [ $# -gt 0 -a "$1" != " " ]; then
        stz_cmd="$(echo "$@"|sed 's/ .*//')"
        [ "$stz_cmd" = "install" ] && [ -f "$MAPR_STANZAFILE_LOCATION" ] && \
            stz_tmplt_arg=" -t $MAPR_STANZAFILE_LOCATION"
        container_keep_alive sudo -E -n -u $MAPR_CONTAINER_USER \
            "$MAPR_BIN_DIR/mapr-installer-cli" "$@" $stz_tmplt_arg
    else
        installer_epilogue
        container_keep_alive sudo -E -H -n -u $MAPR_CONTAINER_USER \
            -g ${MAPR_CONTAINER_GROUP:-$MAPR_GROUP} bash
    fi
}

container_post_server() {
    container_set_timezone
    container_check_environment
    container_user
    container_set_memory
    [ $USE_SYSTEMCTL -eq $YES ] && sleep 5
    container_post_server_$OS
    setup_service_sshd
    container_configure_server
    container_disk_setup
    container_start_services $SSHD mapr-zookeeper mapr-warden
    container_keep_alive
}

container_post_server_redhat() {
    setup_service ntpd
    setup_service rpcbind
    if [ $OSVER_MAJ -ge 7 ]; then
        setup_service nfs-lock
    else
        setup_service nfslock
    fi
}

container_post_server_suse() {
    if [ $OSVER_MAJ -ge 12 ]; then
        setup_service ntpd
    else
        setup_service ntp
    fi
    setup_service rpcbind
}

container_post_server_ubuntu() {
    setup_service ntp
}

container_process() {
    CONTAINER_CMD=$1 && shift
    check_os
    case "$CONTAINER_CMD" in
    base)
        [ $# -ne 2 ] && container_usage
        fetch_dependencies server
        check_jdk
        container_security
        container_repos $1 $2
        container_install $MAPR_PACKAGES_BASE
        setup_service mapr-warden $NO
        ;;
    bash|csh|ksh|sh|zsh) container_keep_alive "$@" ;;
    client)
        [ $# -lt 2 ] && container_usage
        local core_version=$1
        fetch_dependencies client
        check_jdk
        container_security
        container_repos $core_version $2
        shift 2
        if [ $# -gt 0 ]; then
            container_install "$@"
        else
            container_install_thin $core_version
        fi
        setup_service_fuse
        ;;
    core) container_install "$@" ;;
    -h|help) container_usage ;;
    installer)
        msg "\nPreparing installer"
        JDK_REQUIRED=$NO
        fetch_dependencies installer
        container_security
        check_connection
        fetch_installer_$OS
        container_cleanup_installer
        ;;
    post_server) container_post_server ;;
    *)  # auto-create user during initial run
        [ -n "$MAPR_CONTAINER_USER" ] && PROMPT_SILENT=$YES
        if [ -f "$MAPR_HOME/conf/warden.conf" ]; then
            container_start post_server $CONTAINER_CMD "$@"
        elif [ -d "$MAPR_BIN_DIR" ]; then
            container_post_installer $CONTAINER_CMD "$@"
        else
            container_post_client $CONTAINER_CMD "$@"
        fi
        ;;
    esac
}

container_repos() {
    msg "Configuring MapR repositories..."
    local url="$MAPR_CORE_URL/v$1/$OS"
    [ $OS = "ubuntu" ] && url="$url binary trusty"
    local dir=REPO_PATH_$OS
    local ext=REPO_EXT_$OS
    repo_add_$OS "${!dir}/mapr_core.${!ext}" "$url" Core
    if [ -n "$2" ]; then
        url="$MAPR_ECO_URL/MEP/MEP-$2/$OS"
        [ $OS = "ubuntu" ] && url="$url binary trusty"
        repo_add_$OS "${!dir}/mapr_eco.${!ext}" "$url" Ecosystem
    fi
    success
}

container_security() {
    # allow non-root users to log into the system
    rm -f /run/nologin
    if [ -f /etc/ssh/sshd_config ]; then
        sed -i 's/^ChallengeResponseAuthentication no$/ChallengeResponseAuthentication yes/g' \
            /etc/ssh/sshd_config || msg_err "Could not enable ChallengeResponseAuthentication"
        msg "ChallengeResponseAuthentication enabled"
    fi
}

container_set_memory() {
    local mem_file="$MAPR_HOME/conf/container_meminfo"
    local mem_char=$(echo "$MAPR_MEMORY" | grep -o -E '[kmgKMG]')
    local mem_number=$(echo "$MAPR_MEMORY" | grep -o -E '[0-9]+')

    msg "Seting MapR container memory limits..."
    [ ${#mem_number} -eq 0 ] && msg_err "Empty memory allocation"
    [ ${#mem_char} -gt 1 ] && msg_err "Invalid memory allocation: $mem_char must be [kmg]"
    [ $mem_number == "0" ] && return
    case "$mem_char" in
    g|G) local mem_total=$(($mem_number * 1024 * 1024)) ;;
    m|M) local mem_total=$(($mem_number * 1024)) ;;
    k|K) local mem_total=$(($mem_number)) ;;
    esac
    cp -f -v /proc/meminfo $mem_file
    sed -i "s!/proc/meminfo!${mem_file}!" "$MAPR_HOME/server/initscripts-common.sh" || \
        msg_err "Could not edit initscripts-common.sh"
    sed -i "/^MemTotal/ s/^.*$/MemTotal:     $mem_total kB/" "$mem_file" || \
        msg_err "Could not edit meminfo MemTotal"
    sed -i "/^MemFree/ s/^.*$/MemFree:     $mem_total kB/" "$mem_file" || \
        msg_err "Could not edit meminfo MemFree"
    sed -i "/^MemAvailable/ s/^.*$/MemAvailable:     $mem_total kB/" "$mem_file" || \
        msg_err "Could not edit meminfo MemAvailable"
    success $YES
}

container_set_timezone() {
    local file=/usr/share/zoneinfo/$MAPR_TZ

    [ ! -f $file ] && msg_err "Invalid MAPR_TZ timezone ($MAPR_TZ)"
    ln -f -s "$file" /etc/localtime
}

container_start() {
    if [ $USE_SYSTEMCTL -eq $YES -a -x "/usr/sbin/init" ]; then
        $CONTAINER_SCRIPT container "$@" &
        exec /usr/sbin/init
    else
        container_process "$@"
    fi
}

container_start_fuse() {
    if [ -n "$MAPR_MOUNT_PATH" -a -f $MAPR_HOME"/conf/fuse.conf" ]; then
        sed -i "s|^fuse.mount.point.*$|fuse.mount.point=$MAPR_MOUNT_PATH|g" \
            $MAPR_FUSE_FILE || msg_err "Could not set FUSE mount path"
        mkdir -p -m 755 "$MAPR_MOUNT_PATH"
        container_start_services $MAPR_PACKAGE_POSIX
    fi
}

container_start_services() {
    msg "Starting services ($*)..."
    [ $USE_SYSTEMCTL -eq $YES ] && systemctl daemon-reload
    for service in $*; do
        setup_service $service
    done
    success
}

container_user() {
    [ -z "$MAPR_CONTAINER_USER" ] && msg_err "Must specify MAPR_CONTAINER_USER"
    MAPR_USER=$MAPR_CONTAINER_USER
    MAPR_PASSWORD=$MAPR_CONTAINER_PASSWORD
    if [ "$1" = "user" ]; then
        MAPR_UID=${MAPR_CONTAINER_UID:-1000}
        MAPR_GROUP=${MAPR_CONTAINER_GROUP:-users}
        MAPR_GID=${MAPR_CONTAINER_GID:-100}
    else
        MAPR_UID=${MAPR_CONTAINER_UID:-$MAPR_UID}
        MAPR_GROUP=${MAPR_CONTAINER_GROUP:-$MAPR_GROUP}
        MAPR_GID=${MAPR_CONTAINER_GID:-$MAPR_GID}
    fi
    create_user $1
    echo ". $MAPR_ENV_FILE" >> /home/$MAPR_USER/.bashrc
    [ $CONTAINER_SUDO -eq $YES ] && sudoers_add
    container_user_profile "MAPR_CLUSTER=\"$MAPR_CLUSTER\""
    container_user_profile "MAPR_HOME=\"$MAPR_HOME\""
    [ -f "$MAPR_HOME/bin/mapr" ] && container_user_profile "MAPR_CLASSPATH=\"\$($MAPR_HOME/bin/mapr classpath)\""
    [ -n "$MAPR_MOUNT_PATH" ] && container_user_profile "MAPR_MOUNT_PATH=\"$MAPR_MOUNT_PATH\""
    if [ -n "$MAPR_TICKETFILE_LOCATION" ]; then
        local ticket="MAPR_TICKETFILE_LOCATION=$MAPR_TICKETFILE_LOCATION"

        echo "$ticket" >> /etc/environment
        container_user_profile "$ticket"
        sed -i -e "s|MAPR_TICKETFILE_LOCATION=.*|MAPR_TICKETFILE_LOCATION=$MAPR_TICKETFILE_LOCATION|" \
            "$MAPR_HOME/initscripts/$MAPR_PACKAGE_POSIX"
    fi
    container_user_profile "PATH=\"\$PATH:\$MAPR_HOME/bin\""
    unset MAPR_CONTAINER_PASSWORD MAPR_PASSWORD
}

container_user_profile() {
    [ ! -f $env_file ] && echo "#!/bin/bash" > $MAPR_ENV_FILE
    echo "export $1" >> $MAPR_ENV_FILE
}

container_usage() {
    cat << EOM
Execute commands inside a Docker container

usage: $CMD container <cmd> [options] ...
  bash|csh|ksh|sh|zsh [*]      start shell with arguments
  base version mep             finalize base server image
  client version mep pkgs ...  finalize client image
  core pkgs ...                finalize core server image with packages
  installer ...                finalize installer image and run mapr-installer-cli
  ...                          start application with arguments
EOM
    exit 1
}

docker_allocate() {
    msg "Allocating data file $2 ($3)..."
    if [ $OS = "darwin" ]; then
        mkfile -n $3 $2 && success
    else
        fallocate -l $3 $2 && success
    fi
}

docker_base() {
    local create_docker_build_file=$YES
    local docker_dir="$DOCKER_BASE_DIR"
    local docker_build_file="$docker_dir/$DOCKER_BUILD_FILE"
    local docker_tag_file="$docker_dir/$DOCKER_TAG_FILE"
    local image_tag="maprtech:base"

    docker_prologue "Build MapR base image"
    mkdir -p -m 770 $docker_dir
    [ -f $docker_tag_file ] && image_tag=$(cat $docker_tag_file)
    if [ -f $docker_build_file ]; then
        prompt_boolean "$docker_build_file exists - overwrite?"
        create_docker_build_file=$ANSWER
    fi
    if [ $create_docker_build_file -eq $YES ]; then
        prompt "MapR base image tag name" $image_tag
        image_tag=$ANSWER
        docker_build_file "$docker_dir" $image_tag
    fi
    docker_build_run "$docker_dir" $image_tag
    if [ $? -eq 0 ]; then
        success
        msg_bold "MapR base image $image_tag now built. Run '$CMD docker core' to build server images"
    else
        msg_err "Unable to create base image"
    fi
}

docker_build_file() {
    local docker_build_file="$1/$DOCKER_BUILD_FILE"

    cat > $docker_build_file << EOM
#!/bin/sh

docker build --force-rm --pull -t $2 $1
EOM
    chmod +x $docker_build_file
}

docker_build_finish() {
    cat >> "$1/$DOCKER_FILE" << EOM

ENTRYPOINT ["$CONTAINER_SCRIPT", "container"]
EOM
    echo $3 > "$1/$DOCKER_TAG_FILE"
    docker_create_run $*
    docker_build_file "$1" $3
    docker_build_run "$1" $3
}

docker_build_run() {
    local docker_build_file="$1/$DOCKER_BUILD_FILE"

    msg "\nBuilding $2..."
    $docker_build_file || msg_err "Unable to build $2"
}

docker_client() {
    local docker_dir="$DOCKER_CLIENT_DIR"
    local docker_file="$docker_dir/$DOCKER_FILE"
    local docker_run_file="$docker_dir/mapr-docker-client.sh"

    USE_SYSTEMCTL=$NO
    prologue "Build MapR client image"
    docker_create_dirs $docker_dir
    [ $? -eq $NO ] && return
    docker_prompt_os "CLIENT"
    prompt "MapR core version" $MAPR_VERSION_CORE
    local mapr_version=$ANSWER
    prompt "MapR MEP version" $MAPR_VERSION_MEP
    local mep_version=$ANSWER
    prompt_boolean "Install Hadoop YARN client" n
    if [ $ANSWER -eq $YES ]; then
        TAG=_yarn
        PACKAGES="$MAPR_PACKAGES_CLIENT"
        prompt_package "POSIX (FUSE) client" $MAPR_PACKAGE_POSIX fuse y
        prompt_package "HBase client" mapr-hbase hbase n
        [ $ANSWER -eq $YES ] && PACKAGES="$PACKAGES mapr-asynchbase"
        prompt_package "Hive client" mapr-hive hive n
        prompt_package "Pig client" mapr-pig pig n
        prompt_package "Spark client" mapr-spark spark n
        prompt_package "MapR Streams clients" mapr-kafka streams y
        [ $ANSWER -eq $YES -a $(echo $mep_version | cut -d. -f1) -gt 2 ] && PACKAGES="$PACKAGES mapr-librdkafka"
    fi
    local image_tag="maprtech/pacc:${mapr_version}_${mep_version}_${CONTAINER_OS}$TAG"
    prompt "MapR client image tag name" $image_tag
    image_tag=$ANSWER
    docker_dockerfile $docker_dir $mapr_version $mep_version
    cat >> "$docker_file" << EOM
RUN $CONTAINER_SCRIPT -r $MAPR_CORE_URL container client $mapr_version $mep_version $PACKAGES
EOM
    docker_build_finish $docker_dir $docker_run_file "$image_tag" client
    msg_bold "\nEdit '$docker_run_file' to set MAPR_CLUSTER and MAPR_CLDB_HOSTS and then execute it to start the container"
}

docker_core() {
    local base_tag="maprtech:base"
    local image_tag="maprtech:core"
    local create_docker_build_file=$YES
    local create_dockerfile=$YES
    local create_disk_file=$YES
    local docker_base_dir="$DOCKER_BASE_DIR"
    local docker_core_dir="$DOCKER_CORE_DIR"
    local docker_build_file="$docker_core_dir/$DOCKER_BUILD_FILE"
    local docker_run_file="$docker_core_dir/mapr-docker-server.sh"
    local docker_tag_file="$docker_base_dir/$DOCKER_TAG_FILE"
    local dockerfile_file="$docker_core_dir/$DOCKER_FILE"

    docker_prologue "Build MapR core image"
    docker_create_dirs $docker_core_dir
    create_dockerfile=$?
    [ -f $docker_tag_file ] && base_tag=$(cat $docker_tag_file)
    if [ -d $docker_core_dir ]; then
        if [ -f $docker_build_file ]; then
            prompt_boolean "$docker_build_file exists - overwrite?"
            create_docker_build_file=$ANSWER
        fi
    else
        mkdir -p -m 770 $docker_core_dir
    fi
    if [ $create_dockerfile -eq $YES ]; then
        CONTAINER_PORTS="$SSHD_PORT 5660"
        unset PACKAGES
        unset TAG
        prompt "MapR base image tag name" $base_tag
        base_tag=$ANSWER
        prompt "Create file to use as raw disk" $create_disk_file
        create_disk_file=$ANSWER
        prompt_package "Zookeeper" mapr-zookeeper zk y 5181 2888 3888
        prompt_package "MapR-FS CLDB" mapr-cldb cldb y 7222 7221
        prompt_package "MapR-FS Gateway" mapr-gateway gw n 7660
        prompt_package "NFS Server" mapr-nfs nfs n 111 2049 9997 9998
        prompt_package "UI Administration Server" mapr-webserver mcs y 8443
        prompt_package "YARN Resource Manager" mapr-resourcemanager rm y 8032 8033 8088 8090
        prompt_package "YARN Node Manager" mapr-nodemanager nm y 8041 8042 8044
        prompt_package "YARN History Server" mapr-historyserver hs n 10020 19888 19890
        prompt_package "Spark Master Node" mapr-spark-master smn n 7077
        prompt_package "Spark History Server" mapr-spark-history shs n 18080
        TAG="${base_tag}_${TAG}"

        cat > $dockerfile_file << EOM
FROM $base_tag

EXPOSE $CONTAINER_PORTS

# create default MapR admin user and group
RUN groupadd -g $MAPR_GID $MAPR_GROUP && \
useradd -m -u $MAPR_UID -g $MAPR_GID -G \$(stat -c '%G' /etc/shadow) $MAPR_USER

COPY mapr-setup.sh $CONTAINER_SCRIPT_DIR/
RUN $CONTAINER_SCRIPT -f container core $PACKAGES
RUN dd if=/dev/zero of=/root/storagefile bs=1G count=20 \
    sed -i "/root/storagefile" /tmp/disks.txt

ENTRYPOINT ["$CONTAINER_SCRIPT", "-y", "container"]
EOM
    fi
    if [ $create_docker_build_file -eq $YES ]; then
        prompt "MapR core image tag name" $TAG
        image_tag="$ANSWER"
        docker_build_file "$docker_core_dir" $image_tag
    fi
    docker_create_run $docker_core_dir $docker_run_file $image_tag server
    docker_build_run "$docker_core_dir" $image_tag
    if [ $? -eq 0 ]; then
        success
        msg_bold "\nMapR core image $image_tag built successfully. If this image will be shared across nodes, publish it to an appropriate repository"
    else
        msg_err "Unable to create core image"
    fi
}

docker_dockerfile() {
    local dockerfile_file="$1/$DOCKER_FILE"

    cat > "$dockerfile_file" << EOM
FROM $DOCKER_FROM

ENV container docker

EOM
    case $CONTAINER_OS in
    centos6) docker_dockerfile_redhat6 "$dockerfile_file" ;;
    centos7) docker_dockerfile_redhat7 "$dockerfile_file" ;;
    ubuntu14|ubuntu16) docker_dockerfile_ubuntu "$dockerfile_file" ;;
    suse|suse13) docker_dockerfile_suse "$dockerfile_file" ;;
    *) msg_err "Invalid container OS $CONTAINER_OS" ;;
    esac
    if [ -n "$2" ]; then
        cat >> "$dockerfile_file" << EOM

LABEL mapr.os=$CONTAINER_OS mapr.version=$2 mapr.mep_version=$3
EOM
    else
        cat >> "$dockerfile_file" << EOM

LABEL mapr.os=$CONTAINER_OS
EOM
    fi
    cat >> "$dockerfile_file" << EOM

COPY mapr-setup.sh $CONTAINER_SCRIPT_DIR/
EOM
}

docker_dockerfile_redhat_common() {
    cat >> "$1" << EOM
RUN yum install -y $DEPENDENCY_INIT && yum -q clean all
EOM
}

docker_dockerfile_redhat6() {
    docker_dockerfile_redhat_common $1
}

docker_dockerfile_redhat7() {
    docker_dockerfile_redhat_common $1
    if [ $USE_SYSTEMCTL -eq $YES ]; then
        cat >> "$1" << EOM
VOLUME [ "/sys/fs/cgroup" ]

# enable systemd support
RUN (cd /lib/systemd/system/sysinit.target.wants/ || return; for i in *; do [ \$i == systemd-tmpfiles-setup.service ] || rm -f \$i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*; \
rm -f /etc/systemd/system/*.wants/*; \
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*; \
rm -f /lib/systemd/system/anaconda.target.wants/*;
EOM
    fi
}

docker_dockerfile_suse() {
    cat >> "$1" << EOM
VOLUME [ "/sys/fs/cgroup" ]

RUN zypper --non-interactive up && zypper --non-interactive install -n $DEPENDENCY_INIT && zypper clean -a
EOM
}

docker_dockerfile_ubuntu() {
    cat >> "$1" << EOM
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update -qq && apt-get install --no-install-recommends -q -y $DEPENDENCY_INIT && apt-get autoremove --purge -q -y && rm -rf /var/lib/apt/lists/* && apt-get clean -q
EOM
}

docker_create_dirs() {
    local create_dockerfile=$YES
    local dockerfile_file="$1/$DOCKER_FILE"

    if [ -d $1 ]; then
        if [ -f $dockerfile_file ]; then
            prompt_boolean "$dockerfile_file exists - overwrite?" n
            create_dockerfile=$ANSWER
        fi
    else
        mkdir -p -m 770 $1
    fi
    cp -f $INSTALLER $1
    return $create_dockerfile
}

docker_create_run() {
    local create_docker_run_file=$YES
    local docker_args docker_memory docker_network docker_security

    if [ -d "$1" -a -f "$2" ]; then
        prompt_boolean "$2 exists - overwrite?" n
        create_docker_run_file=$ANSWER
    fi
    [ $create_docker_run_file -eq $NO ] && return
    if [ "$4" = "installer" ]; then
        docker_network="bridge"
    else
        while [ -z "$docker_network" ]; do
            prompt "Container network mode (bridge|host)" "bridge"
            case $ANSWER in
            bridge|host) docker_network=$ANSWER ;;
            *) msg "Invalid network mode: $ANSWER" ;;
            esac
        done
    fi
    while [ -z "$docker_memory" ]; do
        prompt "Container memory: specify host XX[kmg] or 0 for no limit" 0

        local mem_char=$(echo "$ANSWER" | grep -o -E '[kmgKMG]')
        local mem_number=$(echo "$ANSWER" | grep -o -E '[0-9]+')

        [ ${#mem_number} -eq 0 ] && continue
        if [ ${#mem_char} -gt 1 ]; then
            msg_warn "Invalid memory allocation: $mem_char must be [kmg]"
            continue
        fi
        if [ ${#mem_char} -eq 0 -a $mem_number != "0" ]; then
            msg_warn "Memory allocation unit must be specified"
            continue
        fi
        docker_memory=$ANSWER
    done
    cat > $2 << EOM
#!/bin/sh

# The environment variables in this file are for example only. These variables
# must be altered to match your docker container deployment needs

EOM
    case "$4" in
    client)
        docker_security='$([ -n $"MAPR_MOUNT_PATH" ] && echo "--cap-add SYS_ADMIN --cap-add SYS_RESOURCE --device /dev/fuse")'
        cat >> "$2" << EOM
MAPR_CLUSTER=$MAPR_CLUSTER
MAPR_CLDB_HOSTS=

# MapR POSIX client mount path to enable direct MapR-FS access
# MAPR_MOUNT_PATH=/mapr

# MapR secure cluster ticket file path on host
MAPR_TICKET_FILE=/tmp/mapr_ticket
# MapR secure cluster ticket file path in container
MAPR_TICKETFILE_LOCATION="/tmp/\$(basename \$MAPR_TICKET_FILE)"

# MapR client user / group
MAPR_CONTAINER_USER=\$(id -u -n)
MAPR_CONTAINER_UID=\$(id -u)
MAPR_CONTAINER_GROUP=$([ $(uname -s) = "Darwin" ] && echo users || echo '$(id -g -n)')
MAPR_CONTAINER_GID=$([ $(uname -s) = "Darwin" ] && echo 100 || echo '$(id -g)')
MAPR_CONTAINER_PASSWORD=
EOM
        ;;
    installer)
        docker_args="-p $MAPR_PORT:9443 "
        docker_security="--privileged"
        cat >> "$2" << EOM
# MapR cluster admin user / group
MAPR_CONTAINER_USER=$MAPR_USER
MAPR_CONTAINER_UID=$MAPR_UID
MAPR_CONTAINER_GROUP=$MAPR_GROUP
MAPR_CONTAINER_GID=$MAPR_GID
MAPR_PKG_URL=$MAPR_PKG_URL
MAPR_CONTAINER_PASSWORD=
# MapR stanza file path on host
MAPR_STANZA_FILE=
# MapR stanza file path in container
MAPR_STANZAFILE_LOCATION=
[ -z "\$MAPR_STANZAFILE_LOCATION" ] && [ -n "\$MAPR_STANZA_FILE" ] && MAPR_STANZAFILE_LOCATION="/tmp/\$(basename \$MAPR_STANZA_FILE)"
EOM
        ;;
    server)
        docker_args="--ipc=host"
        docker_security="--privileged --device \$MAPR_DISKS"
        cat >> "$2" << EOM
MAPR_CLUSTER=$MAPR_CLUSTER
MAPR_DISKS=/dev/sd?,...
MAPR_LICENSE_MODULES=DATABASE,HADOOP,STREAMS
MAPR_CLDB_HOSTS=
MAPR_ZK_HOSTS=
MAPR_HS_HOST=
MAPR_OT_HOSTS=

# MapR cluster admin user / group
MAPR_CONTAINER_USER=$MAPR_USER
MAPR_CONTAINER_UID=$MAPR_UID
MAPR_CONTAINER_GROUP=$MAPR_GROUP
MAPR_CONTAINER_GID=$MAPR_GID
MAPR_CONTAINER_PASSWORD=

# MapR cluster security: [disabled|enabled|master]
MAPR_SECURITY=disabled
EOM
        ;;
    esac
    cat >> "$2" << EOM

# Container memory: specify host XX[kmg] or 0 for no limit. Ex: 8192m, 12g
MAPR_MEMORY=$docker_memory

# Container timezone: filename from /usr/share/zoneinfo
MAPR_TZ=\${TZ:-"$MAPR_TZ"}

# Container network mode: "host" causes the container's sshd service to conflict
# with the host's sshd port (22) and so it will not be enabled in that case
MAPR_DOCKER_NETWORK=$docker_network

# Container security: --privileged or --cap-add SYS_ADMIN /dev/<device>
MAPR_DOCKER_SECURITY="$docker_security"

# Other Docker run args:
MAPR_DOCKER_ARGS="$docker_args"

### do not edit below this line ###
grep -q -s DISTRIB_ID=Ubuntu /etc/lsb-release && \\
  MAPR_DOCKER_SECURITY="\$MAPR_DOCKER_SECURITY --security-opt apparmor:unconfined"

MAPR_DOCKER_ARGS="\$MAPR_DOCKER_SECURITY \\
  --memory \$MAPR_MEMORY \\
  --network=\$MAPR_DOCKER_NETWORK \\
  -e MAPR_DISKS=\$MAPR_DISKS \\
  -e MAPR_CLUSTER=\$MAPR_CLUSTER \\
  -e MAPR_LICENSE_MODULES=\$MAPR_LICENSE_MODULES \\
  -e MAPR_MEMORY=\$MAPR_MEMORY \\
  -e MAPR_MOUNT_PATH=\$MAPR_MOUNT_PATH \\
  -e MAPR_SECURITY=\$MAPR_SECURITY \\
  -e MAPR_TZ=\$MAPR_TZ \\
  -e MAPR_USER=\$MAPR_USER \\
  -e MAPR_CONTAINER_USER=\$MAPR_CONTAINER_USER \\
  -e MAPR_CONTAINER_UID=\$MAPR_CONTAINER_UID \\
  -e MAPR_CONTAINER_GROUP=\$MAPR_CONTAINER_GROUP \\
  -e MAPR_CONTAINER_GID=\$MAPR_CONTAINER_GID \\
  -e MAPR_CONTAINER_PASSWORD=\$MAPR_CONTAINER_PASSWORD \\
  -e MAPR_CLDB_HOSTS=\$MAPR_CLDB_HOSTS \\
  -e MAPR_HS_HOST=\$MAPR_HS_HOST \\
  -e MAPR_OT_HOSTS=\$MAPR_OT_HOSTS \\
  -e MAPR_ZK_HOSTS=\$MAPR_ZK_HOSTS \\
  \$MAPR_DOCKER_ARGS"

[ -f "\$MAPR_TICKET_FILE" ] && MAPR_DOCKER_ARGS="\$MAPR_DOCKER_ARGS \\
  -e MAPR_TICKETFILE_LOCATION=\$MAPR_TICKETFILE_LOCATION \\
  -v \$MAPR_TICKET_FILE:\$MAPR_TICKETFILE_LOCATION:ro"
[ -d /sys/fs/cgroup ] && MAPR_DOCKER_ARGS="\$MAPR_DOCKER_ARGS -v /sys/fs/cgroup:/sys/fs/cgroup:ro"

EOM
    case "$4" in
    installer)
        cat >> "$2" << EOM
MAPR_STANZA_ARGS="\$@"

[ -f "\$MAPR_STANZA_FILE" ] && MAPR_DOCKER_ARGS="\$MAPR_DOCKER_ARGS \\
    -e MAPR_STANZAFILE_LOCATION=\$MAPR_STANZAFILE_LOCATION \\
    -v \$MAPR_STANZA_FILE:\$MAPR_STANZAFILE_LOCATION:ro"

MAPR_DOCKER_ARGS="\$MAPR_DOCKER_ARGS -e MAPR_PKG_URL=\$MAPR_PKG_URL"
docker run -it \$MAPR_DOCKER_ARGS $3 \$MAPR_STANZA_ARGS
EOM
    ;;
    *)
    cat >> "$2" << EOM
docker run --rm -it \$MAPR_DOCKER_ARGS $3 "\$@"
EOM
     ;;
    esac
    chmod +x $2
}

docker_init() {
    local docker_dir="$DOCKER_BASE_DIR"
    local docker_tag_file="$docker_dir/$DOCKER_TAG_FILE"
    local dockerfile_file="$docker_dir/$DOCKER_FILE"

    docker_prologue "Initialize Docker configuration"
    docker_create_dirs $docker_dir
    [ $? -eq $NO ] && return
    docker_prompt_os "SERVER"
    prompt "MapR core version" "$MAPR_VERSION_CORE"
    local mapr_version=$ANSWER
    prompt "MEP version" $MAPR_VERSION_MEP
    local mep_version=$ANSWER
    prompt "MapR base image tag name" "maprtech/server:${mapr_version}_${mep_version}_$CONTAINER_OS"
    local image_tag=$ANSWER
    docker_dockerfile $docker_dir $mapr_version $mep_version
    cat >> $dockerfile_file << EOM
RUN $CONTAINER_SCRIPT -r $MAPR_CORE_URL container base $mapr_version $mep_version
EOM
    echo "$image_tag" > "$docker_tag_file"
    msg_bold "\nCustomize $dockerfile_file and then run '$CMD docker base'"
}

docker_installer() {
    local docker_dir="$DOCKER_INSTALLER_DIR"
    local docker_file="$docker_dir/$DOCKER_FILE"
    local docker_run_file="$docker_dir/mapr-docker-installer.sh"

    USE_SYSTEMCTL=$NO
    prologue "Build MapR UI Installer image"
    docker_create_dirs $docker_dir
    [ $? -eq $NO ] && return
    docker_prompt_os "INSTALLER" "_HL"
    local image_tag="maprtech/installer:$CONTAINER_OS"
    prompt "MapR installer image tag name" $image_tag
    image_tag=$ANSWER
    docker_dockerfile $docker_dir
    cat >> "$docker_file" << EOM
EXPOSE $SSHD_PORT $MAPR_PORT

RUN $CONTAINER_SCRIPT -r $MAPR_CORE_URL container installer
EOM
    docker_build_finish $docker_dir $docker_run_file $image_tag installer
    msg_bold "\nEdit '$docker_run_file' to configure settings and then execute it to start the container"
}

docker_process() {
    [ $# -eq 0 -o "$1" = "-h" ] && docker_usage
    check_os
    [ "$1" = "-y" ] && shift && PROMPT_SILENT=$YES
    DOCKER_CMD=$1 && shift
    case "$DOCKER_CMD" in
    allocate|base|client|core|init|installer) docker_$DOCKER_CMD "$@";;
    *) docker_usage ;;
    esac
}

docker_prologue() {
    prologue "Building MapR Docker sandbox containers are for development and test purposes only!
        MapR does not support production containers. DO YOU AGREE"
    [ $ANSWER = $YES ] || exit 1
    prompt_boolean "$1"
}

docker_prompt_from() {
    CONTAINER_OS=$1
    prompt "Docker FROM base image name:tag" $2
    DOCKER_FROM=$ANSWER
}

docker_prompt_os() {
    local dep=$1
    local hl=$2
    local ver=8
    local pkg tag

    case $OS in
    darwin) CONTAINER_OS=centos7 ;;
    redhat) CONTAINER_OS="centos$OSVER_MAJ" ;;
    ubuntu) CONTAINER_OS="ubuntu$OSVER_MAJ" ;;
    *) CONTAINER_OS=$OS ;;
    esac
    unset ANSWER
    while [ -z "$ANSWER" ]; do
        prompt "Image OS class (centos6, centos7, ubuntu14, ubuntu16)" \
            $CONTAINER_OS
        case $ANSWER in
        centos6) pkg="RPM" && tag="centos:centos6" ;;
        centos7) pkg="RPM" && tag="centos:centos7" ;;
        suse|suse13) pkg="SUSE" && tag="opensuse:13.2" ;;
        ubuntu14) pkg="DEB" && tag="ubuntu:14.04" && ver=7 ;;
        ubuntu16) pkg="DEB" && tag="ubuntu:16.04" ;;
        *) unset ANSWER ;;
        esac
    done
    eval DEPENDENCY_INIT="\"\$DEPENDENCY_${dep}_$pkg \$OPENJDK_${pkg}_$ver$hl\""
    docker_prompt_from $ANSWER $tag
}

docker_usage() {
    cat << EOM
Create Docker images with MapR software

usage: $CMD docker <cmd> [options] ...
  client                       create client image
  installer                    create installer image
EOM
    exit 1
    # TODO add help back
    cat << EOM
Create Docker images with MapR software

usage: $CMD docker <cmd> [options] ...
  allocate filename size       allocate disk file for MapR-FS
  base                         create server base image
  client                       create client image
  core                         create server core services image
  init                         create server iniitial $DOCKER_FILE
  installer                    create installer image
EOM
    exit 1
}


azure_format_partition() {
    mkfs.ext4 "$AZURE_NEW_PARTITION" || msg_err "Could not format new partition"
}

azure_get_largest_free_space() {
    local count=1
    local largest=0
    local largest_index=-1
    local free_space_result=$(parted -s /dev/${AZURE_ROOT_DEVICE_NAME} unit B print free | awk '/Free Space/')

    while [ $count -lt 20 ]; do
        local free_size_str=$(echo "$free_space_result" | sed -n ${count}p | awk '{print $3}')
        [ -z "$free_size_str" ] && break

        local free_size=$(echo "${free_size_str%?} / 1073741824" | bc)
        if [ $free_size -gt $largest ]; then
            largest=$free_size
            largest_index=$count
        fi

        let count=count+1
    done
    [ $largest_index -eq -1 ] && return
    AZURE_SIZE_GB=$largest

    AZURE_START=$(echo "$free_space_result" | sed -n ${largest_index}p | awk '{print $1}')
    AZURE_END=$(echo "$free_space_result" | sed -n ${largest_index}p | awk '{print $2}')
}

azure_get_root_information() {
    local root_device_line=$(df -B G / | sed -n 2p)
    local root_device=$(echo "$root_device_line"  | awk '{print $1}')
    root_device=${root_device%?}
    AZURE_ROOT_DEVICE=$root_device

    local root_size=$(echo "$root_device_line"  | awk '{print $2}')
    [ -z "$root_size" ] && return
    AZURE_ROOT_SIZE_GB=${root_size%?}

    local device_name=$(echo $root_device | sed -e "s/\/dev\///")
    [ -z "$device_name" ] && return
    AZURE_ROOT_DEVICE_NAME=$device_name
}

azure_mount_partition() {
    mv -f /opt /.opt_old || msg_err "Could not move opt directory"
    mkdir -m 755 /opt || msg_err "Could not create opt directory"
    mount $AZURE_NEW_PARTITION /opt/ || msg_err "Could not mount opt directory"
    cp -rf /.opt_old/* /opt/ || msg_err "Could not copy temp opt directory to new directory"
    rm -rf /.opt_old || msg_err "Could not remove temp opt directory"

    local uuid=$(blkid -o export "$AZURE_NEW_PARTITION" | sed -n 2p)
    [ -z "$uuid" ] && msg_err "Could not determin UUID of new partition"
    echo "$uuid    /opt    ext4    defaults    0 0" >> /etc/fstab
}

azure_partition_free_space() {
    local count_before=$(grep -c "${AZURE_ROOT_DEVICE_NAME}[0-9]" /proc/partitions)
    [ ${#count_before} -ne 1 ] && msg_err "Could not determine partition count before partitioning"

    msg "Partitioning device..."
    parted -s --align=optimal $AZURE_ROOT_DEVICE mkpart primary ext4 $AZURE_START $AZURE_END
    [ $? -ne 0 ] && msg_err "Could not partition device"

    local count_after=$(grep -c "${AZURE_ROOT_DEVICE_NAME}[0-9]" /proc/partitions)
    [ ${#count_after} -ne 1 ] && msg_err "Could not determine partition count after partitioning"

    local more_count=$(echo "$count_after - $count_before" | bc)
    [ $more_count -ne 1 ] && msg_err "Invalid count $more_count"

    AZURE_NEW_PARTITION="${AZURE_ROOT_DEVICE}${count_after}"
}

azure_process_opt() {
    cat << EOM
This partition script will attempt to find free space on your root device and
then move the /opt directory to that space if it is greater than the root
partition size. Please see MapR documentation for recommended /opt free space
requirements.
EOM
    prompt_boolean "Do you want to continue?"
    [ $ANSWER -eq $NO ] && return

    azure_get_root_information
    azure_get_largest_free_space

    msg "Root device: $AZURE_ROOT_DEVICE"
    msg "Root device name: $AZURE_ROOT_DEVICE_NAME"
    msg "Root partition size: $AZURE_ROOT_SIZE_GB"
    msg "Largest free partition size: $AZURE_SIZE_GB"
    msg "Free partition start sector: $AZURE_START"
    msg "Free partition end sector: $AZURE_END"
    if [ $AZURE_ROOT_SIZE_GB -gt $AZURE_SIZE_GB ]; then
        msg_warn "The existing root partition size of $AZURE_ROOT_SIZE_GB is larger than the amount free space of $AZURE_SIZE_GB"
        return
    fi

    prompt_boolean "Is above information correct and do you want to partition this disk free space?"
    [ $ANSWER -eq $NO ] && return

    azure_partition_free_space
    msg "New partition name is: $AZURE_NEW_PARTITION"
    [ -z $AZURE_NEW_PARTITION ] && msg_warn "Could not determine new partition name" && return
    azure_format_partition
    msg "New partition is: $AZURE_NEW_PARTITION"
    azure_mount_partition
    msg "Partition is mounted"
}

azure_setup_swap() {
    local waagent=/etc/waagent.conf
    sed -i 's/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/' $waagent ||
        msg_err "Could not enable swapfile"
    sed -i "s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=$CLOUD_SWAP_SIZE/" $waagent ||
        msg_err "Could not set swapfile size"
}

image_clean() {
    cd /
    rm -rf /var/lib/cloud/
    rm -f /var/log/cloud-init*
    find /home -name authorized_keys -type f -exec rm -f {} \;
    find /root -name authorized_keys -type f -exec rm -f {} \;
    find /var/log -type f -exec cp /dev/null {} \;
    rm -rf /tmp/*
    history -c
    sync
}

image_create_aws() {
    while [ $# -gt 0 ]; do
        case "$1" in
        -i|--image_name) local image_name=$2 ;;
        -k|--access_key_id) local access_key=$2 ;;
        -s|--secret_access_key) local secret_key=$2 ;;
        -d|--disk_size) local disk_size=$2 ;;
        *) image_create_aws_usage ;;
        esac
        shift 2
    done

    [ -z "$image_name" ] && msg_err "image name required"
    [ -z "$disk_size" ] && local disk_size=$IMAGE_DISK_SIZE
    [ -n "$access_key" ] && export AWS_ACCESS_KEY_ID=$access_key
    [ -n "$secret_key" ] && export AWS_SECRET_ACCESS_KEY=$secret_key
    [ $disk_size -eq $disk_size 2>/dev/null ] || msg_err "disk size must be integer"
    . $MAPR_INSTALLER_DIR/build/installer/bin/activate
    local document=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document)
    local instanceId=$(echo $document | sed -e 's/.*"instanceId" : "\([^"]*\).*/\1/')
    local region=$(echo $document | sed -e 's/.*"region" : "\([^"]*\).*/\1/')
    prompt_warn "Creating an AMI requires this instance to reboot" "$CONTINUE_MSG"
    [ $? -eq $NO ] && exit 1
    image_clean
    aws ec2 create-image --instance-id $instanceId --name $image_name \
        --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$disk_size, \"DeleteOnTermination\": true, \"VolumeType\": \"gp2\"}}]" \
        --region $region || msg_err "Unable to create image"
}

# create image for Azure
image_create_azure() {
    while [ $# -gt 0 ]; do
        case "$1" in
        -g|--resource-group) local resource_group=$2 ;;
        -i|--image-name) local image_name=$2 ;;
        -p|--password) local password=$2 ;;
        -n|--name) local vm_name=$2 ;;
        -s|--service-principal) local sp="--service-principal" ;;
        -t|--tenant) local tenant=$2 ;;
        -u|--username) local username=$2 ;;
        *) image_create_azure_usage ;;
        esac
        shift 2
    done

    [ -z "$resource_group" ] && msg_err "resource group required"
    [ -z "$image_name" ] && msg_err "image name required"
    [ -z "$vm_name" ] && msg_err "virtual machine name required"

    . /opt/mapr/installer/build/azure-cli/bin/activate
    # don't login if the session is already logged in
    az account show > /dev/null 2>&1
    local logged_in=$?
    local cmd="az login"

    [ -n "$username" ] && cmd="${cmd} -u $username"
    [ -n "$password" ] && cmd="${cmd} -p $password"
    [ -n "$tenant" ] && cmd="${cmd} -t $tenant"
    [ -n "$sp" ] && cmd="${cmd} $sp"
    [ $logged_in -ne 0 ] && msg "Logging into Azure..." && ${cmd}

    local disk_image=$(az vm show --resource-group $resource_group --name $vm_name --query storageProfile.osDisk.managedDisk.id | tr -d ,\"" ")
    [ -z "$disk_image" ] && msg_err "Could not find managed disk in resource group $resource_group"
    msg "Found managed disk at $disk_image"

    msg "Deallocating VM $vm_name in resource group $resource_group ..."
    az vm deallocate --resource-group $resource_group  --name $vm_name ||
        msg_err "Could not deallocate VM"
    msg "Generalizing VM $vm_name in resource group $resource_group ..."
    az vm generalize --resource-group $resource_group  --name $vm_name ||
        msg_err "Could not generalize VM"

    msg "Creating image $image_name from VM $vm_name ..."
    local image_id=$(az image create --resource-group $resource_group --name $image_name --os-type Linux --source $disk_image --query id)
    [ $? -ne 0 ] && msg_err "Could not create image"
    image_id=$(echo $image_id | tr -d ,\"" ")
    [ $logged_in -ne 0 ] && az logout
    deactivate
    msg "The image ID to use in your ARM template is: $image_id"
    success
}

image_finalize_azure() {
    prompt_boolean "You will no longer be able to access this machine after finalizing it. Continue?"
    [ $ANSWER -eq $NO ] && return
    prompt "Enter MapR cluster admin name used during image prep" $MAPR_USER
    MAPR_USER=$ANSWER
    sudoers_add

    local finalized="$MAPR_DATA_DIR/finalized"
    echo "finalize cloud: azure" >> "$finalized"
    echo "finalize user: $MAPR_USER" > "$finalized"
    chmod 0444 "$finalized"

    rm -f /etc/udev/rules.d/70-persistent-net.rules
    image_clean
    waagent -deprovision+user -force
}

image_prep() {
    local reset=$NO
    while [ $# -gt 0 ]; do
        case "$1" in
        -l|--license)
            local license=$2
            [ -n "$license" ] && [ ! -f "$license" ] &&
                msg_err "license file $license does not exist"
            shift 2
            ;;
        -p|--partner)
            local partner=$2
            [ -n "$partner" ] && [ ! -f "$partner" ] &&
                msg_err "partner jar $partner does not exist"
            shift 2
            ;;
        -r|--reset)
            local reset_url=$2
            if [ -z "$reset_url" ] || [ ${reset_url:0:1} == '-' ]; then
                reset_url=$MAPR_PKG_URL
                shift
            else
                shift 2
            fi
            ;;
        -v|--version)
            local version=$2
            if [ -z "$version" ] || [ ${version:0:1} == '-' ]; then
                msg_err "version number is required"
            fi
            [ $(printf "$version\n5.2.0" | sort -r | head -n1) != $version ] &&
                msg_err "version 5.2.0 and higher is supported"
            shift 2
            ;;
        *) image_prep_usage ;;
        esac
    done

    [ -z "$version" ] && local version=$MAPR_VERSION_CORE
    $CURL_NOSAVE -I $MAPR_CORE_URL/installer/$OS/mapr-setup.sh || msg_err "Invalid repo URL: $repo_url"
    local repo_url=$MAPR_CORE_URL/v$version/$OS
    if [ -n "$reset_url" ]; then
        $CURL_NOSAVE -I $reset_url/installer/$OS/mapr-setup.sh  || msg_err "Invalid reset repo URL: $reset_url"
        local reset_repo_url=$reset_url/v$version/$OS
    fi

    prompt_boolean "Install pre-requisites and prepare $version base image"
    [ $ANSWER -eq $NO ] && return
    get_environment
    if [ "$MAPR_ENVIRONMENT" == "azure" ]; then
        azure_process_opt
        azure_setup_swap
    else
        # Create 2GB swap on disk if no swap found
        if [ $(swapon -s | wc -l) -le 1 ]; then
            msg "Creating swapfile ..."
            /bin/dd if=/dev/zero of=/var/swapfile bs=1M count=$CLOUD_SWAP_SIZE
            /sbin/mkswap /var/swapfile
            chmod 600 /var/swapfile
            echo "/var/swapfile none swap defaults 0 0" >> /etc/fstab
            swapon /var/swapfile
        fi
    fi
    create_user
    fetch_dependencies installer
    check_jdk
    fetch_installer_$OS
    get_versions_$OS
    installer_properties_create
    setup_service mapr-installer $NO
    sed -i -e '/"host":/d' $MAPR_PROPERTIES_FILE
    fetch_dependencies server
    local dir=REPO_PATH_$OS
    local ext=REPO_EXT_$OS
    if [ $OS = "ubuntu" ]; then
        if [ $(printf "$version\n5.2.1" | sort -r | head -n1) == $version ]; then
            repo_url="$repo_url binary trusty"
            [ -n "$reset_url" ] && reset_repo_url="$reset_repo_url binary trusty"
        else
            repo_url="$repo_url mapr optional"
            [ -n "$reset_url" ] && reset_repo_url="$reset_repo_url mapr optional"
        fi
    fi
    repo_add_$OS "${!dir}/mapr_core.${!ext}" "$repo_url" Core
    package_install_$OS $MAPR_PACKAGES_IMAGE
    setup_service mapr-warden $NO
    package_cleanup_$OS
    if [ -n "$license" ]; then
        msg "Moving license file"
        mv -f $license ${MAPR_DATA_DIR}/license.txt ||
            msg_err "Could not move license file $license to $MAPR_DATA_DIR"
    fi
    if [ -n "$partner" ]; then
         msg "Moving partner jar file" &&
         mv -f $partner ${MAPR_LIB_DIR}/partner.jar ||
             msg_err "Could not move partner jar file $partner to $MAPR_LIB_DIR"
    fi
    if [ $OS == 'redhat' ]; then
        sed -i -e 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
    fi

    chown $MAPR_USER:$MAPR_GROUP $MAPR_PROPERTIES_FILE

    if [ -n "$reset_url" ]; then
        sed -i -e "s|\"repo_core_url\":.*,|\"repo_core_url\": \"$reset_url\",|" $MAPR_PROPERTIES_FILE
        sed -i -e "s|\"repo_eco_url\":.*,|\"repo_eco_url\": \"$reset_url\",|" $MAPR_PROPERTIES_FILE
        repo_add_$OS "${!dir}/mapr_core.${!ext}" "$reset_repo_url" Core
        local installer_repo=$reset_url/installer/$OS
        [ $OS == 'ubuntu' ] && installer_repo="$installer_repo binary trusty"
        repo_add_$OS "${!dir}/mapr_installer.${!ext}" "$installer_repo" "Installer"
    fi
}

# create image for the cloud
image_process() {
    [ "$1" = "-h" ] && image_usage
    IMAGE_CMD=$1 && shift
    check_os

    local err="Invalid cloud provider $MAPR_ENVIRONMENT"

    case "$IMAGE_CMD" in
    create)
        [ $# -eq 0 ] && image_usage
        MAPR_ENVIRONMENT=$1
        shift
        image_create_$MAPR_ENVIRONMENT $* || msg_err "$err"
        ;;
    finalize)
        [ $# -ne 1 ] && image_usage
        image_finalize_$1 || msg_err "$err"
        ;;
    prep) image_prep "$@" ;;
    *) image_usage ;;
    esac
}

image_create_aws_usage() {
    cat << EOM
Create an AWS AMI from a prepped virtual machine
NOTE: VM will be stopped during this operation

usage: $CMD image create aws -i <image_name> [options]

required:
  -i, --image_name             name of image to be created

options:
  -d, --disk_size              size of the root disk in GB (default 128)
  -k, --access_key_id          AWS access key id
  -s, --secret_access_key      AWS secret key
EOM
    exit 1
}

image_create_azure_usage() {
    cat << EOM
Create an Azure image from a prepped virtual machine
NOTE: VM will be deallocated/stopped and no longer usable after this operation

usage: $CMD image create azure -g <resource_group> -i <image_name>
  -n <vm_name> [options]

required:
  -g, --resource-group         existing resource group containing prepped vm
  -i, --image-name             name of image created from prepped vm
  -n, --name                   existing prepped vm name

options:
  -p, --password               password supplied to 'az login' command
  -s, --service-principal      credential representing a service principal
  -t, --tenant                 AAD tenant (required when using service principals)
  -u, --username               username supplied to 'az login' command
EOM
    exit 1
}

image_prep_usage() {
    cat << EOM
Pre-install MapR software on a virtual machine in a cloud

usage: $CMD prep [OPTIONS]

options:
  -l, --license license_file   add license file to container
  -p, --partner partner_file   add partner jar file to container
  -r, --reset                  reset repo URL to package.mapr.com
  -v, --version core_version   install MapR core services (default latest)
EOM
    exit 1
}

image_usage() {
    cat << EOM
Pre-install MapR software on a virtual machine in a cloud

usage: $CMD image <cmd> [options] ...
  create aws <image_name>      create AWS image
  create azure *               create Azure image
  finalize azure               finalize Azure machine before creating image
  prep *                       prepare OS and pre-install MapR software
EOM
    exit 1
}

# this is an update if mapr-installer package exists
installer_check_update() {
    local defs_installed=$NO

    case $OS in
    redhat|suse)
        rpm -qa | grep -q mapr-installer-definitions 2>&1 && defs_installed=$YES
        rpm -qa | grep -q mapr-installer-\[1-9\] 2>&1 && ISUPDATE=$YES
        ;;
    ubuntu)
        dpkg -l | grep "^ii" | grep -q mapr-installer-definitions 2>&1 && defs_installed=$YES
        dpkg -l | grep "^ii" | grep -q mapr-installer-\[1-9\] 2>&1 && ISUPDATE=$YES
        ;;
    esac
    # remove the definitions too if the installer is gone
    [ $ISUPDATE -eq $NO -a $defs_installed -eq $YES ] && installer_remove "silent"
    if [ $ISUPDATE -eq $NO ] && $(ss -lnt "( sport = :$MAPR_PORT )" | grep -q LISTEN); then
        msg_err "Port $MAPR_PORT is in use. Correct the problem and retry $CMD"
    fi
}

# cleanup remnants from previous install if any
installer_cleanup() {
    rm -rf $MAPR_INSTALLER_DIR
}

installer_epilogue() {
    tput bold
    msg_center "To continue installing MapR software, open the following URL in a web browser"
    msg_center ""
    if [ "$HOST_INTERNAL" = "$HOST" ]; then
        msg_center "If the address '$HOST' is internal and not accessible"
        msg_center "from your browser, use the external address mapped to it instead"
        msg_center ""
    fi
    msg_center "https://$HOST:$MAPR_PORT"
    msg_center ""
    tput sgr0
}

# Remove all packages
installer_remove() {
    local pkgs="mapr-installer mapr-installer-definitions"

    prologue "Remove packages"
    [ -z "$1" ] && msg "\nUninstalling packages ($pkgs)..."
    if [ $USE_SYSTEMCTL -eq $YES ]; then
       systemctl --no-ask-password stop mapr-installer > /dev/null
    else
       service mapr-installer condstop > /dev/null
    fi
    case $OS in
    redhat)
        rm -f /etc/yum.repos.d/mapr_installer.repo
        yum -q -y remove $pkgs 2> /dev/null
        yum -q clean all 2> /dev/null
        ;;
    suse)
        rm -f etc/zypp/repos.d/mapr_installer.repo
        zypper --non-interactive -q remove $pkgs 2> /dev/null
        ;;
    ubuntu)
        rm -f /etc/apt/sources.list.d/mapr_installer.list
        apt-get purge -q -y $pkgs 2> /dev/null
        apt-get clean -q 2> /dev/null
        ;;
    esac
    [ $? -ne 0 ] && msg_err "Unable to remove packages ($pkgs)"
    installer_cleanup
    [ -z "$1" ] && success $YES
}

installer_properties_create() {
    if [ $ISUPDATE -eq $YES -a -f "$MAPR_PROPERTIES_FILE" ]; then
        installer_properties_update
    else
        mkdir -m 700 -p $MAPR_DATA_DIR
        [ $ISCONNECTED -eq $NO ] && NOINET=$YES
        cat > "$MAPR_PROPERTIES_FILE" << EOM
{
    "cluster_admin_create": ${BOOLSTR[$MAPR_USER_CREATE]},
    "cluster_admin_gid": $MAPR_GID,
    "cluster_admin_group": "$MAPR_GROUP",
    "cluster_admin_id": "$MAPR_USER",
    "cluster_admin_uid": $MAPR_UID,
    "container": ${BOOLSTR[$CONTAINER]},
    "core_version": "$MAPR_VERSION_CORE",
    "debug": false,
    "environment": "$MAPR_ENVIRONMENT",
    "host": "$MAPR_HOST",
    "installer_admin_group": "$MAPR_GROUP",
    "installer_admin_id": "$MAPR_USER",
    "installer_version": "$MAPR_SERVER_VERSION",
    "log_rotate_cnt": 5,
    "no_internet": ${BOOLSTR[$NOINET]},
    "os_version": "${OS}_${OSVER}",
    "port": $MAPR_PORT,
    "repo_core_url": "$MAPR_CORE_URL",
    "repo_eco_url": "$MAPR_ECO_URL",
    "services_version": "$MAPR_DEF_VERSION"
}
EOM
    fi
}

installer_properties_reload() {
    if [ -f /etc/init.d/mapr-installer -o -f /etc/systemd/system/mapr-installer.service ]; then
        if [ $USE_SYSTEMCTL -eq $YES ]; then
            RESULTS=$(systemctl --no-ask-password condreload mapr-installer)
        else
            RESULTS=$(service mapr-installer condreload)
        fi
        [ $? -ne 0 ] && msg_err "Reload failed: $RESULTS"
    fi
}

installer_properties_update() {
    sed -i -e "s/\"installer_version.*/\"installer_version\": \"$MAPR_SERVER_VERSION\",/" -e "s/\"services_version.*/\"services_version\": \"$MAPR_DEF_VERSION\"/" "$MAPR_PROPERTIES_FILE"
    if ! grep -q installer_admin_group "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/cluster_admin_uid/a\
\ \ \ \ \"installer_admin_group\": \"$MAPR_GROUP\","  "$MAPR_PROPERTIES_FILE"
    fi
    if ! grep -q installer_admin_id "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/installer_admin_group/a\
\ \ \ \ \"installer_admin_id\": \"$MAPR_USER\","  "$MAPR_PROPERTIES_FILE"
    fi
    if ! grep -q log_rotate_cnt "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/installer_admin_id/a\
\ \ \ \ \"log_rotate_cnt\": 5,"  "$MAPR_PROPERTIES_FILE"
    fi
    if ! grep -q os_version "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/log_rotate_cnt/a\
\ \ \ \ \"os_version\": \"${OS}_${OSVER}\"," "$MAPR_PROPERTIES_FILE"
    else
       CONF_VER=$(grep  os_version "$MAPR_PROPERTIES_FILE" | cut -d: -f2)
       if [ "$CONF_VER" != "${OS}_${OSVER}" ]; then
           sed -i -e "s/$CONF_VER/ \"${OS}_${OSVER}\",/" "$MAPR_PROPERTIES_FILE"
       fi
    fi
    if ! grep -q no_internet "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/os_version/a\
\ \ \ \ \"no_internet\": ${BOOLSTR[$NOINET]}," "$MAPR_PROPERTIES_FILE"
    fi
    if ! grep -q container "$MAPR_PROPERTIES_FILE"; then
       sed -i -e "/environment/a\
\ \ \ \ \"container\": ${BOOLSTR[$CONTAINER]}," "$MAPR_PROPERTIES_FILE"
    fi
}

upgrade_installer_redhat() {
    yum --disablerepo=* --enablerepo=MapR_Installer -q -y update \
        mapr-installer-definitions mapr-installer
}

upgrade_installer_suse() {
    zypper --non-interactive -q install \
        -n mapr-installer-definitions mapr-installer
}

upgrade_installer_ubuntu() {
    aptsources="-o Dir::Etc::SourceList=$REPO_PATH_ubuntu/mapr_installer.list"
    apt-get -qq $aptsources update 2> /dev/null
    apt-get $aptsources -qq install -y --force-yes \
        mapr-installer-definitions mapr-installer
}

##
## MAIN
##
export TERM=${TERM:-ansi}
tput init

# Parse command line and set globals
while [ $# -gt 0 -a -z "${1##-*}" ]; do
    case "$1" in
    -a|--archives)
        while [ -n "$2" -a "$2" != -* -a -f "$2" ]; do
            MAPR_ARCHIVES="$MAPR_ARCHIVES $2"
            shift
        done
        [ -z "$MAPR_ARCHIVES" ] && usage
        TEST_CONNECT=$NO
        ;;
    -h|-\?|--help) usage 0 ;;
    -i|--install)
        [ $# -gt 2 ] || usage
        MAPR_INSTALLER_PACKAGES="$2 $3"
        shift 2
        ;;
    -n|--noinet)
        NOINET=$YES
        TEST_CONNECT=$NO
        ;;
    -p|--port)
        [ $# -gt 1 ] || usage
        tport=$(echo $2| cut -s -d: -f2)
        if [ -z "$tport" ]; then
            tport=$2
            thost=$(echo $MAPR_HOST | cut -d: -f1)
        else
            thost=$(echo $2| cut -s -d: -f1)
        fi
        case $tport in
        ''|*[!0-9]*)
            msg_warn "Port must be numeric: $port"
            usage
            ;;
        esac
        MAPR_HOST="$thost:$tport"
        shift
        ;;
    -r|--repo)
        [ $# -gt 1 ] || usage
        MAPR_INSTALLER_URL=$2/installer
        MAPR_PKG_URL=$2
        MAPR_CORE_URL=$2
        MAPR_ECO_URL=$2
        shift
        ;;
    -v|--verbose) VERBOSE=$YES ;;
    -y|--yes) PROMPT_SILENT=$YES ;;
    *) usage ;;
    esac
    shift
done

[ "$1" != "docker" -a $ID -ne 0 ] &&
    msg_err "$CMD must be run as 'root'"
[ -z "$HOST" ] && msg_err "Unable to determine hostname"
MAIN_CMD=$1 && shift
case "$MAIN_CMD" in
cli) cli_process "$@" ;;
container) container_process "$@" ;;
docker) docker_process "$@" ;;
image) image_process "$@" ;;
""|install)
    # If mapr-installer has been installed, then do an update.
    # Otherwise, prepare the system for MapR installation
    prologue "Install required packages"
    check_os_version
    catch_signals
    installer_check_update
    fetch_dependencies installer
    check_jdk
    check_connection
    set_port
    [ $ISUPDATE -eq $NO ] && installer_cleanup && create_user
    get_environment
    fetch_installer_$OS
    get_versions_$OS
    installer_properties_create
    start_service_installer
    installer_epilogue
    ;;
reload)
    # avoid questions asked during package upgrade
    PROMPT_SILENT=$YES
    check_os
    get_versions_$OS
    installer_properties_update
    installer_properties_reload
    ;;
remove) installer_remove ;;
update)
    prologue "Update packages"
    check_os_version
    catch_signals
    check_connection
    ISUPDATE=$YES
    fetch_installer_$OS
    get_versions_$OS
    installer_properties_update
    installer_properties_reload
    start_service_installer
    installer_epilogue
    ;;
upgrade)
    check_os
    upgrade_installer_$OS
    ;;
*) usage ;;
esac

exit 0       

