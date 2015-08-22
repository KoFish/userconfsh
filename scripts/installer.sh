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

oldIFS=$IFS
IFS=`echo -e "\n"`
CURRTARGET=
STARTOFFILE=1
while read line; do
	CFGSEG=`echo $line | sed -n "s/\(^[A-Z]\+\)=[^ \t]\+$/\1/p"`
	if [ ! -z "$CFGSEG" ]; then
		#info "Found config line $CFGSEG"
		if [ "$STARTOFFILE" -ne 1 ]; then
			err "Settings can only be in the beginning of config files"
		else
			CFGVAL=`echo $line | sed -n "s/^.\+=\([^ \t]\+\)$/\1/p"`
			case "$CFGSEG" in
				"DIFF")
					DIFFDIR="${CONF_ROOT}/${CFGVAL}"
					;;
				"BACKUP")
					BACKUPDIR="${CONF_ROOT}/${CFGVAL}"
					;;
				*) ;;
			esac
		fi
	else
		PATHSEG=`echo $line | sed -n "s/\([^:]\+[^\/]\)\/\?:/\1/p"`
		if [ ! -z "$PATHSEG" ]; then
			STARTOFFILE=0
			HOMESEG=`echo "$PATHSEG" | sed -n "s;^~\(/\|$\);${HOME}\1;p"`
			if [ ! -z "$HOMESEG" ]; then
				CURRTARGET=$HOMESEG
			else
				CURRTARGET=$PATHSEG
			fi
		elif [ ! -z "$CURRTARGET" ]; then
			DIRSEG=`echo $line | sed -n "s/\t\(.\+[^\/]\)\/$/\1/p"`
			FILESEG=`echo $line | sed -n "s/\t\(.\+\)/\1/p"`
			if [ ! -z "$DIRSEG" ]; then
				STARTOFFILE=0
				dirpath="$CONF_ROOT/$DIRSEG"
				newIFS=$IFS
				IFS=$oldIFS
				for file in `ls -A "$dirpath/"`; do
					install "$dirpath" "$file" "$CURRTARGET"
				done
				IFS=$newIFS
			elif [ ! -z "$FILESEG" ]; then
				STARTOFFILE=0
				install "$CONF_ROOT" "$FILESEG" "$CURRTARGET"
			fi
		fi
	fi
done < $CONF_PATH
IFS=$oldIFS

# vim: ts=2 sw=2
