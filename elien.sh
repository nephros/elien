#!/usr/bin/env bash

ELIENVERSION=0.0.99
SAVED_ARGS=$@

write_head() {
	TEMPLATE=${ELIENDIR}/templates/generic.head
	cp ${TEMPLATE} ${EBUILD}

	echo "# ELIEN version $ELIENVERSION initially created this file." >> ${EBUILD}
	echo "# ELIEN was called with: $SAVED_ARGS" >> ${EBUILD}
	echo >> ${EBUILD}
	echo EAPI=\"4\" >> ${EBUILD}
}

write_common() {
	echo LICENSE=\"\"				>> ${EBUILD}
	echo SLOT=0					>> ${EBUILD}
	echo KEYWORDS=\"~$(portageq envvar ARCH)\"	>> ${EBUILD}
	echo IUSE=\"\"					>> ${EBUILD}

	echo >> ${EBUILD}
}

from_sf() {
	local home="http://sourceforge.net/projects/${PN}/"
	local data=${TD}/data.html
	wget -q -O ${data} $home
	local desc=$(awk -F= '/<meta name="description" content="/ {print $3}' ${data} | sed 's/[">]//g')
	local srcball=$(grep -A 3 'class="sfdl"' $data | tail -1 | sed 's@<small .*>\(.*\)</small>@\1@')
	# FIXME handle other formats like zip
	local srcfmt=$(echo $srcball | sed 's/.*\(tar.*\)/\1/')
	local url="mirror://sourceforge/${PN}/\${P}.${srcfmt}"

	write_head

	echo DESCRIPTION=\"$desc\"	>> ${EBUILD}
	echo HOMEPAGE=\"$home\"		>> ${EBUILD}
	echo SRC_URI=\"$url\"		>> ${EBUILD}
	echo >> ${EBUILD}

	write_common

	return
}

from_pdo() {
	local repo=$1
	local home=http://packages.debian.org/$1/${PN}
	local data=${TD}/data.html
	wget -q -O ${data} $home
	local dscurl=$(grep dsc $data | sed 's@.*<a href="\(.*\.dsc\)".*@\1@')
	local dscdata=${TD}/data.dsc
	wget -q -O ${dscdata} $dscurl

	write_head
	echo $(grep Description $data   | sed 's@.*content="\(.*\)".*@DESCRIPTION="\1"@')	>> ${EBUILD}
	echo $(grep Homepage ${dscdata} | sed 's@Homepage: \(.*\)@HOMEPAGE="\1"@')		>> ${EBUILD}
	local srcball=$(awk '/orig/ {print $3}'  ${dscdata} | uniq)
	echo SRC_URI=\"mirror://debian/pool/main/${srcball:0:1}/\${PN}/${srcball}\"		>> ${EBUILD}
	write_common
	echo "# ELIEN note: Debian lists these deps, you will have to find their Gentoo equivalents:" >> ${EBUILD}
	echo $(grep Build-Depends: ${dscdata} | sed 's@Build-Depends: \(.*\)@#DEPEND="\1"@') >> ${EBUILD}
}

store_ebuild() {
	local repo=$(portageq get_repo_path / ${OVERLAY})
	local finalloc=$repo/$CATEGORY/${PN}
	if [[ ! -w $repo ]]; then
	    echo "ERROR: $OVERLAY does not exist or is not writeable!"
	    exit 1
	fi
	mkdir -p ${finalloc}
	cp -i ${EBUILD} ${finalloc}
	ebuild ${finalloc}/*.ebuild manifest fetch unpack prepare
}

usage() {
	
	cat << EOF
USAGE: ${0##*/} 
	-f <fromtag>      : what to convert from. see fromtags below.
	-p name           : what the package is called at the source
	-v version        : version of the package
	-c <category>     : use portage category <category>
	-o <repo_name>    : dump ebuild into overlay <repo_name>
	  -h              : this help

	fromtags:
	    Websites:
		sf	... sourceforge.net
		pdo	... packages.debian.org, testing
		pdos	... packages.debian.org, stable
		gh	... GitHub.com [not implemented]
		gc	... code.google.com [not implemented]
		gnu	... savannah.gnu.org [not implemented]
		nongnu	... savannah.nongnu.org [not implemented]
	    Packages:
		ppa	... Ubuntu PPA [not implemented]
		deb	... Debian package [not implemented]
		rpm	... (S)RPM [not implemented]
EOF
}

cleanup() {
	rm -r ${TD}
}

ask_user() {
    if [[ -z ${FROM} ]]; then
	echo "Where is the package from? [$FROM]" 
	read _FROM_
	[[ ! -z "${_FROM_}" ]] && FROM=${_FROM_}
    fi
    if [[ -z ${PN} ]]; then
	echo "What is the packages name? [$PN]" 
	read _PN_
	[[ ! -z "${_PN_}" ]] && PN=${_PN_}
    fi
    if [[ -z ${PV} ]]; then
	echo "What is the packages version? [$PV]" 
	read _PV_
	[[ ! -z "${_PV_}" ]] && PV=${_PV_}
    fi
    if [[ -z ${OVERLAY} ]]; then
	echo "Where do you want to store the ebuild? [$OVERLAY]" 
	read _OVERLAY_
	[[ ! -z "${_OVERLAY_}" ]] && OVERLAY=${_OVERLAY_}
    fi
}

### parse args:
while getopts "f:p:v:o:c:h" opt
do
		case $opt in
			f) FROM=$OPTARG ;;
			p) PN=$OPTARG ;;
			v) PV=$OPTARG ;;
			e) EBUILD=$OPTARG ;;
			o) OVERLAY=$OPTARG ;;
			c) CATEGORY=$OPTARG ;;
			h)
				usage
				exit 0
			;;
		esac
done

### setup
TD=`mktemp -d`
EBUILD=${TD}/${PN}-${PV}.ebuild
ELIENDIR=${0%%/*}


### main
ask_user
case $FROM in
	sf)
		from_sf
	;;
	pdo)
		from_pdo testing
	;;
	pdos)
		from_pdo stable
	;;
	*)
		echo "Conversion from $FROM not implemented, sorry."
		usage
		exit 0
	;;
esac	

echo preliminary ebuild generated at ${EBUILD}
echo "press return to edit it."
read dummy
$EDITOR $EBUILD
echo Do you want to add this to your overlay now?
echo y will store, n will delete, anything else will do nothing.
read dummy
case $dummy in
    Y|y)
	echo storing ebuild.
	store_ebuild
	;;
    n|N)
	echo not storing ebuild.
	cleanup
	;;
    *)
	echo ok, doing nothing.
	;;
esac

