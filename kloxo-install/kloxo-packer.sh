#!/bin/sh
#    Kloxo, Hosting Control Panel
#
#    Copyright (C) 2000-2009	LxLabs
#    Copyright (C) 2009-2011	LxCenter
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# LxCenter - Kloxo Packer
#
# Version: 1.0 (2011-08-02 - by mustafa.ramadhan@lxcenter.org)
#

if [ "$#" == 0 ] ; then
	echo
	echo " ----------------------------------------------------------------------"
	echo "  format: sh $0 --fork=<> --branch=<> --part=<>"
	echo " ----------------------------------------------------------------------"
	echo "  --fork - example: lxcenter or mustafaramadhan (for certain developer)"
	echo "  --branch - example: master or dev"
	echo "  --part - example: core or all (defaulting to all)"
	echo
	echo "  * Pack main kloxo package from git"
	echo "  * Thirdparty packages download directly for latest version"
	echo "  * Then run kloxo-installer.sh which the same place with local copy"
	echo
	exit;
fi

echo "Start pack..."

request1=$1
kloxo_fork=${request1#--fork\=}

request2=$2
kloxo_branch=${request2#--branch\=}

request3=$3
kloxo_part=${request3#--part\=}

kloxo_path=${kloxo_fork}/kloxo/zipball/${kloxo_branch}

mkdir -p ./combo

if [ ! -d ./current/kloxo/httpdocs ] ; then
	echo "Download kloxo git from "${kloxo_path}
	yes | rm -rf ${kloxo_branch}*
	wget https://github.com/${kloxo_path} --no-check-certificate
	mv -f ${kloxo_branch} kloxo.zip
	unzip -oq kloxo.zip
	mv -f ./${kloxo_fork}* ./current
	yes | rm -rf kloxo.zip
else
	echo "No download and use local copy"
fi

cp -rf ./current/* ./combo

cp -rf ./patch/* ./combo

if [ ! -f ./combo/kloxo-install/kloxo-installer.php ] ; then

	cd ./combo
	
	echo "Download kloxo-install.zip from http://download.lxcenter.org/download/"
	wget http://download.lxcenter.org/download/kloxo-install.zip
	unzip -oq kloxo-install.zip
	rm -rf kloxo-install.zip
	
	cd ..
	
	# check again
	if [ ! -f ./combo/kloxo-install/kloxo-installer.php ] ; then		
		echo "Download kloxo-installer.php from http://download.lxcenter.org/download/kloxo/production/"
		wget http://download.lxcenter.org/download/kloxo/production/kloxo-installer.php
		mv -f kloxo-installer.php ./combo/kloxo-install/kloxo-installer.php
	fi
fi

cd ./combo

zip -r9y kloxo-install.zip ./kloxo-install

mv -f kloxo-install.zip ../

cd ./kloxo/src
yum -y install gcc automake autoconf libtool make
make
cd ../

zip -r9y kloxo-current.zip ./bin ./cexe ./file ./httpdocs ./pscript ./sbin ./RELEASEINFO ./src -x \
	"*httpdocs/commands.php" \
	"*httpdocs/newpass" \
	"*httpdocs/.php.err" \
	"*/CVS/*" \
	"*/.svn/*" \
	"*httpdocs/thirdparty/*" \
	"*httpdocs/htmllib/extjs/*" \
	"*httpdocs/htmllib/fckeditor/*" \
	"*httpdocs/htmllib/yui-dragdrop/*"

mv -f kloxo-current.zip ../../
cd ../../

if [ ${kloxo_part} != 'core' ] ; then

	thirdpartyver=$(curl -L http://download.lxcenter.org/download/thirdparty/kloxo-version.list)
	if [ ! -f kloxo-thirdparty.$thirdpartyver.zip ] ; then
		echo ${thirdpartyver} > kloxo-thirdparty-version
		wget http://download.lxcenter.org/download/kloxo-thirdparty.${thirdpartyver}.zip
	fi

	kloxophpver=$(curl -L http://download.lxcenter.org/download/version/kloxophp)
	if [ ! -f kloxophp${kloxophpver}.tar.gz ] ; then
		echo ${kloxophpver} > kloxophp-version
		wget http://download.lxcenter.org/download/kloxophp${kloxophpver}.tar.gz
	fi

	kloxophpsixfourver=$(curl -L http://download.lxcenter.org/download/version/kloxophpsixfour)
	if [ ! -f kloxophpsixfour${kloxophpsixfourver}.tar.gz ] ; then
		echo ${kloxophpsixfourver} > kloxophpsixfour-version
		wget http://download.lxcenter.org/download/kloxophpsixfour${kloxophpsixfourver}.tar.gz
	fi

	lxwebmailver=$(curl -L http://download.lxcenter.org/download/version/lxwebmail)
	if [ ! -f lxwebmail${lxwebmailver}.tar.gz ] ; then
		echo ${lxwebmailver} > lxwebmail-version
		wget http://download.lxcenter.org/download/lxwebmail${lxwebmailver}.tar.gz
	fi

	lxawstatsver=$(curl -L http://download.lxcenter.org/download/version/lxawstats)
	if [ ! -f lxawstats${lxawstatsver}.tar.gz ] ; then
		echo ${lxawstatsver} > lxawstats-version
		wget http://download.lxcenter.org/download/lxawstats${lxawstatsver}.tar.gz
	fi
fi

cp ./combo/kloxo-install/kloxo-installer.sh ./

# Reads yes|no answer from the input 
# 1 question text
# 2 default answer, yes = 1 and no = 0
function get_yes_no {
    local question=
    local input=
    case $2 in 
        1 ) question="$1 [Y/n]: "
            ;;
        0 ) question="$1 [y/N]: "
            ;;
        * ) question="$1 [y/n]: "
    esac

    while :
    do
        read -p "$question" input
        input=$( echo $input | tr -s '[:upper:]' '[:lower:]' )
        if [ "$input" = "" ] ; then
            if [ "$2" == "1" ] ; then
                return 1
            elif [ "$2" == "0" ] ; then
                return 0
            fi
        else
            case $input in
                y|yes) return 1
                    ;;
                n|no) return 0
                    ;;
            esac
        fi
    done
}

get_yes_no "Do you delete temporal dirs (patch, current and combo)?" 1
if [ "$?" -eq "1" ] ; then
	rm -rf ./patch
	rm -rf ./current
	rm -rf ./combo
fi

echo
echo "Now you can run 'sh ./kloxo-installer.sh' for installing"
echo
echo "... the end"
echo
