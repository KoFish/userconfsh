#!/bin/sh

HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#################################################
## Parse incoming commandline arguments
#################################################

DO_HELP=0
DO_DIFFS=0
DO_CLOBBER=0
DO_FETCH=1

while getopts hdcfr: name; do
	case "$name" in
		h)
			DO_HELP=1
			;;
		d)
			DO_DIFFS=1
			;;
		r)
			REPOCONF="$OPTARG"
			;;
		f)
			DO_FETCH=0
			;;
		c)
			DO_CLOBBER=1
			;;
		*) ;;
	esac
done

if [ "$DO_HELP" == 1 ]; then
	echo "$0 [-d] [-h]"
	echo ""
	echo "setup.sh is a set of scripts to install files, primarily, in the users"
	echo "home catalogue."
	echo ""
	echo "    -d             - Create and store a set of diffs between the"
	echo "                     current files and the files to be installed."
	echo "    -c             - Clobber; overwrite existing files."
	echo "    -r             - Repo file; the file to read for repo configuration"
	echo "    -f             - No fetch; do not try updating the repo if it has"
	echo "                     been cloned."
	echo ""
	echo "    -h             - Show this help text."
	echo ""
	echo "Report bugs to krister.svanlund@gmail.com"
	exit 0
fi

#################################################
## Setup basic information for the script
##########################################¤######

REPODIR="${HERE}/repos"
if [ -z "$REPOCONF" ]; then
	REPOCONF="${HERE}/repo.conf"
fi
if [ ! -f "$REPOCONF" ]; then
	echo "${REPOCONF} is not a valid file."
	exit -1
fi
REPONAME=`cat $REPOCONF | cut -f 1 -d" "`
REPOURL=`cat $REPOCONF | cut -f 2 -d" "`
if [ -z "$REPONAME" -o -z "$REPOURL" ]; then
	echo "${REPOCONF} is not a valid repo configuration file."
fi

if [ "$DO_FETCH" -gt 0 -o ! -d "${REPODIR}/${REPONAME}" ]; then
	sh ${HERE}/scripts/git.sh clone_repo "$REPODIR" "$REPONAME" "$REPOURL"
	if [ $? -ne 0 ]; then
		echo "Could not clone configuration repository"
	fi
fi

export CLOBBER=$DO_CLOBBER

sh ${HERE}/scripts/installer.sh "$REPODIR/$REPONAME" \
	"install.conf" "$DO_DIFFS"
exit $?

# vim: ts=2 sw=2
