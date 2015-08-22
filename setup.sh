#!/bin/sh

#################################################
## Setup basic information for the script
##########################################¤######

HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TARGET="${HOME}"
HOMESOURCE=${HERE}/home
BACKUPDIR="${HERE}/.old"
DIFFDIR="${HERE}/diff/`whoami`@`hostname`"

source ${HERE}/utils.d/replace.sh

dir_count() {
  echo $(ls -A "$1/" | wc -l)
}

if [ -d "${BACKUPDIR}" ]; then
  if [ $(dir_count "$BACKUPDIR") -ne "0" ]; then
    oldbackup="${BACKUPDIR}-`date -I`"
    info "Backup old backup dir, ${oldbackup}"
    mv -v "${BACKUPDIR}" "$oldbackup"
  fi
fi

color_output
mkdir -p ${BACKUPDIR}/
mkdir -p ${TARGET}/
mkdir -p ${DIFFDIR}/
reset

#################################################
## Parse incoming commandline arguments
#################################################

DO_HELP=0
DO_DIFFS=0
DO_CLOBBER=0

while getopts hdc name; do
	case "$name" in
		h)
			DO_HELP=1
			;;
		d)
			DO_DIFFS=1
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
	echo ""
	echo "    -h             - Show this help text."
	echo ""
	echo "Report bugs to krister.svanlund@gmail.com"
	exit 0
fi

#################################################
## Setup functions for doing the installation
#################################################

do_replace() {
  replace "${HOMESOURCE}/$1" "${TARGET}/$1" \
		      "${DIFFDIR}/$1" "${BACKUPDIR}" \
					"$DO_DIFFS" "$DO_CLOBBER"
}

do_install() {
  replace "${HERE}/$1" "${TARGET}/$2" \
					"${DIFFDIR}/$1" "${BACKUPDIR}" \
					"$DO_DIFFS" "$DO_CLOBBER"
}

#################################################
## Indicate which files are to be installed
#################################################

do_replace "test1"
#do_replace ".xinitrc"
#do_replace ".nvimrc"
#do_replace ".zshrc"
#do_replace ".i3"
#do_replace ".config/i3status"
#do_install "scripts" ".bin"

if [ $(dir_count "$BACKUPDIR") -eq "0" ]; then
  # Remove backup dir if it's empty
  rmdir "$BACKUPDIR"
fi

# vim: ts=2 sw=2
