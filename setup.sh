#!/bin/sh

HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#################################################
## Parse incoming commandline arguments
#################################################

DO_HELP=0
DO_DIFFS=0
DO_CLOBBER=0
DO_FETCH=0
REPO_ROOT="${HERE}/repos"
REPO_CONF="repo.conf"

while getopts hdcfr:b: name; do
	case "$name" in
		h) ## Help
			DO_HELP=1
			;;
		d) ## Create new set of diffs
			DO_DIFFS=1
			;;
		r) ## Change the name of the repo configuration file
			REPO_CONF="$OPTARG"
			;;
		b) ## Change the root of the cloned repositories
			REPO_ROOT="$OPTARG"
			;;
		f) ## Do not fetch the git repo
			DO_FETCH=1
			;;
		c)
			DO_CLOBBER=1
			;;
		*)
			;;
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
	echo "    -b             - Repo directory; the directory where to find the"
	echo "                     repo config file and to place the repositories."
	echo "    -f             - Fetch; try updating the repo even if it has been"
	echo "                     cloned."
	echo ""
	echo "    -h             - Show this help text."
	echo ""
	echo "Report bugs to krister.svanlund@gmail.com"
	exit 0
fi

#################################################
## Setup basic information for the script
##########################################¤######

if [ ! -d "$REPO_ROOT" ]; then
	echo "Repository root is not a valid directory"
	exit -1
fi

REPO_CONF_PATH="$REPO_ROOT/$REPO_CONF"
LINE_COUNT=`wc -l "$REPO_CONF_PATH" | cut -f 1 -d" "`
if [ ! -r "$REPO_CONF_PATH" -o "$LINE_COUNT" != "1" ]; then
	echo "Repository configuration file, ${REPO_CONF_PATH} is not a valid file"
	exit -1
fi

REPONAME=`cat $REPO_CONF_PATH | cut -f 1 -d" "`
REPOURL=`cat $REPO_CONF_PATH | cut -f 2 -d" "`
if [ -z "$REPONAME" -o -z "$REPOURL" ]; then
	echo "${REPO_CONF_PATH} is not a valid repo configuration file."
fi

if [ "$DO_FETCH" -gt 0 -o ! -d "${REPO_ROOT}/${REPONAME}" ]; then
	sh ${HERE}/scripts/git.sh clone_repo "$REPO_ROOT" "$REPONAME" "$REPOURL"
	if [ $? -ne 0 ]; then
		echo "Could not clone configuration repository"
	fi
fi

export CLOBBER=$DO_CLOBBER

sh ${HERE}/scripts/installer.sh "$REPO_ROOT/$REPONAME" \
	"install.conf" "$DO_DIFFS"
exit $?

# vim: ts=2 sw=2
