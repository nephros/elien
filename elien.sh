#!/usr/bin/env bash

from_sf() {
	local home="http://sourceforge.net/projects/${PN}/"
	local site=${TD}/site.html
	wget -q -O ${site} $home
	local desc=$(awk -F= '/<meta name="description" content="/ {print $3}' ${site} | sed 's/[">]//g')
	local url="mirror://sourceforge/${PN}/\${P}.tar.xz"

	TEMPLATE=${ELIENDIR}/templates/generic.head
	cp ${TEMPLATE} ${EBUILD}

	echo >> ${EBUILD}
	echo DESCRIPTION=\"$desc\" >> ${EBUILD}
	echo HOMEPAGE=\"$home\" >> ${EBUILD}
	echo SRC_URI=\"$url\" >> ${EBUILD}
	echo >> ${EBUILD}
	return
}

store_ebuild() {
	local repo=$(portageq get_repo_path / ${OVERLAY})
	cp ${EBUILD} ${finalloc}
	ebuild ${finalloc}/$EBUILD manifest
}

usage() {
	
	cat << EOF
USAGE: ${0##*/} 
	* -f [fromtag]	    : what to convert from. see fromtags below.
	* -p name	    : what the package is called at the source
	* -v version	    : version of the package
	* -r <repo_name>    : dump ebuild into overlay <repo_name>

	options marked * are required.

	fromtags:
		sf  ...	sourceforge.net
		deb ...	Debian package [not implemented]
		ppa ...	Ubuntu PPA [not implemented]
		rpm ...	RPM [not implemented]
EOF
}

cleanup() {
	rm -r ${TD}
}

### parse args:
while getopts "f:p:v:r:h" opt
do
		case $opt in
			f) FROM=$OPTARG ;;
			p) PN=$OPTARG ;;
			v) PV=$OPTARG ;;
			e) EBUILD=$OPTARG ;;
			r) OVERLAY=$OPTARG ;;
			h) usage;;
		esac
done

### setup
TD=`mktemp -d`
EBUILD=${TD}/${PN}-${PV}.ebuild
ELIENDIR=${0%%/*}

### main
case $FROM in
	sf)
		from_sf
	;;
	*)
		echo "Conversion from $FROM not implemented, sorry."
		usage
		exit 0
	;;
esac	

echo "press return to edit it."
$EDITOR $EBUILD
cleanup
