THIS="${BASH_SOURCE[0]}"
SCRIPT_HERE=$( cd "$( dirname "${THIS}" )" && pwd )
UTIL_HERE="$(dirname $SCRIPT_HERE)/utils.d"

source "${UTIL_HERE}/debug.sh"

ROOT=$1
SRC=$2
TARGET=$3
DIFFS=$4
BACKUPS=$5
MAKEDIFFS=$6

# replace_symlink <file>
#
# Replaces the symlink with the file it is being linked to.
replace_symlink() {
	local file="$1"
	if [ -L "$file" ]; then
		realfile=$( realpath -e "$file" )
		if [ $? -ne 0 ]; then
			info "Target file is a broken symlink, removing it: $(gray)$(realpath "$file")$(color_reset)"
			color_output
			rm -v --force "$file"
			color_reset
		else
			info "Target file is a symlink, replace it with the target"
			color_output
			rm -v --force "$file"
			cp -v "$realfile" "$file"
			color_reset
		fi
	fi
}

# backup_target_file <file A> <file B> <backup>
#
# Creates a backup file if A and B differs.
backup_target_file() {
	local src=$1
	local target=$2
	local backup=$3
	if [ -e "$target" ]; then
		diff "$src" "$target" &> /dev/null
		if [ $? -ne 0 ]; then
			info "Making backup of old file, $(gray)${target}$(color_reset)"
			color_output
			mkdir -p `dirname "$backup"`
			mv -v --no-clobber --force "$target" "$backup"
			local result=$?
			color_reset
			if [ $result -ne 0 ]; then
				err "Could not backup file, aborting!"
				return 1
			fi
		fi
	fi
}

# install_file <from> <to>
#
# Copies from file to to file.
install_file() {
	local src=$1
	local target=$2
	local result=0
	info "Install $(gray)${target}$(color_reset) (source: $(gray)${src}$(color_reset))"

	color_output
	mkdir -p `dirname "${target}"`
	color_reset

	if [ -d "$src" ]; then
		err "Source is a directory, not handled"
		result=3
	else
		local do_copy=1

		if [ -d "$target" ]; then
			result=3
		else
			if [ -e "$target" -a "$CLOBBER" != 1 ]; then
				diff "$src" "$target" &> /dev/null
				if [ $? -eq 0 ]; then
					warn "Source and target file do not differ, no copying"
					do_copy=0
				fi
			fi
			if [ "$do_copy" == 1 ]; then
				cp "$src" "$target" > /dev/null
				result=$?
				if [ $result -eq 0 ]; then
					result=1
				else
					result=2
				fi
			fi
		fi
	fi
	return $result
}

create_diff_file() {
	local curpath=$1
	local srcpath=$2
	local diffpath=$3
	local tmppath=$4
	if [ -e "$diffpath" -a "$CLOBBER" != 1 ]; then
		err "Could not generate new diff, old diff already exists"
		return 5
	fi
	if [ -e "$curpath" ]; then
		sh $SCRIPT_HERE/diffs.sh create "$curpath" "$srcpath" "$diffpath"
		if [ $? -ne 0 ]; then
			return 6
		fi
		info "Created new diff file $(gray)${diffpath}$(color_reset)"
	fi
}

#echo "ROOT: $ROOT"
#echo "SRC: $SRC"
#echo "TARGET: $TARGET"
#echo "DIFFS: $DIFFS"
#echo "BACKUPS: $BACKUPS"

replace() {
	local srcpath="${ROOT}/${SRC}"
	local curpath="${TARGET}/${SRC}"
	local diffpath="${DIFFS}/${SRC}"
	local create_diff="$MAKEDIFFS"

	### Check if we are doing backups
	if [ ! -z "$BACKUPS" ]; then
		local backuppath="${BACKUPS}/${SRC}"
	else
		# backupdir isn't set so we do not back this up
		if [ "$create_diff" -ne 1 ]; then
			warn "Intentionally not backing up $(gray)${SRC}$(color_reset)"
		fi
		local backuppath=
	fi

	local tmppath=`mktemp --suffix="setupsh"`
	local result=0
	rm --force "$tmppath"

	local newsrc="$srcpath"
	if [ -r "$diffpath" ]; then
		sh $SCRIPT_HERE/diffs.sh patch "$tmppath" "$srcpath" "$diffpath"
		result=$?
		if [ $result -eq 0 ]; then
			newsrc="$tmppath"
		else
			return 3
		fi
	fi

	if [ -e "$curpath" -a "$CLOBBER" != 1 ]; then
		if [ "$create_diff" != 1 ]; then
			diff "$newsrc" "$curpath" &> /dev/null
			result=$?
			if [ $result -eq 1 ]; then
				err "Aborting, Target file $(gray)${curpath}$(color_reset) already exists"
			else
				info "Target file $(gray)${curpath}$(color_reset) already exists and matches the new file"
			fi
			return 5
		fi
	fi

	if [ ! -e "$srcpath" ]; then
		warn "Source $(gray)${SRC}$(color_reset) does not exist"
		return 0
	fi

	replace_symlink "$curpath"

	if [ "$create_diff" == 1 ]; then
		create_diff_file "$curpath" "$srcpath" "$diffpath"
		if [ $? -ne 0 ]; then
			return 5
		fi
		return 0
	fi

	if [ ! -z "$backuppath" ]; then
		backup_target_file "$newsrc" "$curpath" "$backuppath"
	fi

	install_file "$newsrc" "$curpath" "$backuppath"
	result=$?

	if [ $result -eq 0 ]; then
		warn "Did not install file"
	elif [ $result -eq 1 ]; then
		info "File successfully installed, $(gray)${target}$(color_reset)"
	else
		warn "Could not install file"
	fi
	return $result
}

replace
exit $?

# vim: ts=2 sw=2 tw=100
