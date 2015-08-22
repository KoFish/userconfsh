THIS="${BASH_SOURCE[0]}"
SCRIPT_HERE=$( cd "$( dirname "${THIS}" )" && pwd )
UTIL_HERE="$(dirname $SCRIPT_HERE)/utils.d"

source "${UTIL_HERE}/debug.sh"

CONF_ROOT=$1
CONF_FILE="install.cfg"
if [ ! -z "$2" ]; then CONF_FILE="$2"; fi
CONF_PATH="${CONF_ROOT}/${CONF_FILE}"
MAKEDIFFS=$3

if [ ! -r "$CONF_PATH" ]; then
	if [ -f "$CONF_PATH" ]; then
		err "Install configuration could not be read, $(gray)${CONF_PATH}$(color_reset)"
		exit 2
	else
		err "Install configuration does not exist, $(gray)${CONF_PATH}$(color_reset)"
		exit 1
	fi
fi

BACKUPDIR=${CONF_ROOT}/backup
DIFFDIR=${CONF_ROOT}/diff

install_file() {
	local root=$1
	local file=$2
	local target=$3

	sh ${SCRIPT_HERE}/replace.sh "$root" "$file" "$target" \
		"$DIFFDIR" "$BACKUPDIR" "$MAKEDIFFS"
}

install() {
	local root=$1
	local src=$2
	local trg=$3

	#info "Install $root / $src -> $trg"

	if [ -d "$root/$src" ]; then
		for file in `ls -A "$root/$src/"`; do
			install "$root" "$src/$file" "$trg"
		done
	else
		install_file "$root" "$src" "$trg"
	fi
}

classify_line() {
	local line=$1
	local comment=`echo $line | sed -n "s/^#/\0/p"`
	if [ ! -z "$comment" ]; then return 0; fi
	local cfg=`echo $line | sed -n "s/^[A-Z]\+=[^ \t]\+$/\0/p"`
	if [ ! -z "$cfg" ]; then return 1; fi
	local path0=`echo $line | sed -n "s/^[^ \t]/\0/p"`
	if [ ! -z "$path0" ]; then return 2; fi
	local path1=`echo $line | sed -n "s/^\t[^ \t]/\0/p"`
	if [ ! -z "$path1" ]; then return 3; fi
	local path2=`echo $line | sed -n "s/^\t\t[^ \t]/\0/p"`
	if [ ! -z "$path2" ]; then return 4; fi
	return -1
}

expand_home() {
	local line=$1
	local hashome=`echo "$line" | sed -n "s;^~\(/\|$\);${HOME}\1;p"`
	if [ ! -z "$hashome" ]; then
		CURRTARGET=$hashome
	else
		CURRTARGET=$line
	fi
	echo $CURRTARGET
}

parse_cfg() {
	local line=$1
	CFGKEY=`echo $line | sed -n "s/^\([A-Z]\+\)=[^ \t]\+$/\1/p"`
	CFGVAL=`echo $line | sed -n "s/^[A-Z]\+=\(.\+\)$/\1/p"`
	case "$CFGKEY" in
		"DIFF")
			info "Setup diff directory: ${CFGVAL}"
			DIFFDIR="${CONF_ROOT}/${CFGVAL}/`whoami`@`hostname`"
			;;
		"BACKUP")
			info "Setup backup directory: ${CFGVAL}"
			BACKUPDIR="${CONF_ROOT}/${CFGVAL}"
			;;
		*)
			;;
	esac
}

oldIFS=$IFS
IFS=`echo -e "\n"`
CURRTARGET=
STARTOFFILE=1
WAITINGFORFILES=
WAITINGFORMOREFILES=0
while read line; do
	classify_line $line
	LINETYPE=$?
	if [ ! -z $WAITINGFORFILES ]; then
		if [ $LINETYPE == 4 ]; then
			FILESEG=`echo $line | sed -n "s/\t\t\(.\+\)/\1/p"`
			trgpath="$CONF_ROOT/$WAITINGFORFILES"
			install "$trgpath" "$FILESEG" "$CURRTARGET"
			WAITINGFORMOREFILES=1
		elif [ "$WAITINGFORMOREFILES" == 0 ]; then
			dirpath="$CONF_ROOT/$WAITINGFORFILES"
			newIFS=$IFS
			IFS=$oldIFS
			for file in `ls -A "$dirpath/"`; do
				install "$dirpath" "$file" "$CURRTARGET"
			done
			IFS=$newIFS
			WAITINGFORFILES=
		else
			WAITINGFORFILES=
			WAITINGFORMOREFILES=0
		fi
	fi
	if [ -z "$WAITINGFORFILES" ]; then
		classify_line $line
		case $? in
			0) ## Comment
				;;
			1) ## Configuration line
				if [ "$STARTOFFILE" -ne 1 ]; then
					err "Settings can only be in the beginning of config files"
				else
					parse_cfg $line
				fi
				;;
			2) ## Target path
				STARTOFFILE=0
				PATHSEG=`echo $line | sed -n "s/\([^:]\+[^\/]\|~\)\/\?:/\1/p"`
				if [ ! -z "$PATHSEG" ]; then
					CURRTARGET=`expand_home "$PATHSEG"`
				fi
				;;
			3) ## Source paths
				if [ ! -z "$CURRTARGET" ]; then
					STARTOFFILE=0
					DIRSEG=`echo $line | sed -n "s/\t\(.\+[^\/]\)\/$/\1/p"`
					FILESEG=`echo $line | sed -n "s/\t\(.\+\)$/\1/p"`
					if [ ! -z "$DIRSEG" ]; then
						WAITINGFORFILES="$DIRSEG"
					elif [ ! -z "$FILESEG" ]; then
						install "$CONF_ROOT" "$FILESEG" "$CURRTARGET"
					fi
				else
					err "Incorrect configuration file syntax"
					exit 10
				fi
				;;
			*) ;;
		esac
	fi
done < $CONF_PATH
IFS=$oldIFS

# vim: ts=2 sw=2
