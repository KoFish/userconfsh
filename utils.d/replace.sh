#!/bin/sh

UTIL_HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TMPDIR=`mktemp -d`

source "${UTIL_HERE}/debug.sh"

replace_symlink() {
  local file="$1"
  if [ -L "$file" ]; then
    realfile=$( realpath -e $file )
    if [ $? -ne 0 ]; then
      info "Target file is a broken symlink, remove it: $(gray)$(realpath $file)$(reset)"
      color_output
      rm -v --force "$file"
      reset
    else
      info "Target file is a symlink, replace it with the target"
      color_output
      rm -v --force "$file"
      cp -v "$realfile" "$file"
      reset
    fi
  fi
}

create_patch_file() {
  local new=$1
  local current=$2
  local diff=$3

  if [ -e "$diff" ]; then
    warn "Diff file $(gray)${diff}$(reset) already exists"
    return 2
  fi

  diff --unified "$new" "$current" > $diff
  local result=$?
  if [ $result -eq 1 ]; then
    # Files where different
    return 0
  else
    # There where no difference between the files
    rm --force "$diff"
    return 1
  fi
}

create_patched_file() {
  local new=$1
  local diff=$2
  local current=$3

  if [ -e "$current" ]; then
    warn "File $(gray)${current}$(reset) already exists"
    return 2
  fi

  if [ -e "$diff" ]; then
		color_output
    patch -p1 "$new" "$diff" -o "$current"
		local result=$?
		reset
    if [ $result -ne 0 ]; then
      warn "Could not apply diff!"
    else
      return 0
    fi
  fi
  return 1
}

backup_target_file() {
  local src=$1
  local target=$2
  local backup=$3
  if [ -e "$target" ]; then
    diff "$src" "$target" &> /dev/null
    if [ $? -ne 0 ]; then
      info "Making backup of old file, $(gray)${target}$(reset)"
      color_output
      mv -v --no-clobber --force "$target" "$backup"
      local result=$?
      reset
      if [ $result -ne 0 ]; then
        err "Could not backup file, aborting!"
        return 1
      fi
    fi
  fi
}

install_file() {
  local src=$1
  local target=$2
  local result=0
	info "Install $(gray)${target}$(reset) (source: $(gray)${src}$(reset))"

  color_output
  mkdir -p `dirname "${target}"`
  reset

  if [ -d "$src" ]; then
    err "Source is a directory, not handled yet"
    result=3
  else
		local do_copy=1
		if [ -e "$target" ]; then
			diff "$src" "$target" &> /dev/null
			if [ $? -eq 0 ]; then
				warn "Source and target file do not differ, no copying"
				do_copy=0
			fi
		fi
		if [ "$do_copy" == 1 ]; then
			color_output
			cp -v "$src" "$target"
			result=$?
			reset
			if [ $result -eq 0 ]; then
				result=1
			else
				result=2
			fi
		fi
  fi
  return $result
}

# replace from_file, to_file, diff_file, backup_dir
replace() {
	## Source file - The up to date file
	local srcpath="$1"
	local srcfile=`basename "$1"`
	## Current file - The one we currently have installed
	local curpath="$2"
	local curfile=`basename "$2"`
	## Diff file - Where the diff file should exist
  local diffpath="$3"
	## Backup dir - Where we should store the backup
  local backupdir="$4"

	local create_diff="$5"
	local clobber="$6"

	#info "srcpath=${srcpath}"
	#info "srcfile=${srcfile}"
	#info "curpath=${curpath}"
	#info "curfile=${curfile}"
	#info "diffpath=${diffpath}"
	#info "backupdir=${backupdir}"
	#info "create_diff=${create_diff}"
	#info "clobber=${clobber}"
	#return -2

	if [ ! -z "$backupdir" ]; then
		local backuppath="$4"/${srcfile}
	else
		# backupdir isn't set so we do not back this up
		if [ "$create_diff" -ne 1 ]; then
			warn "Intentionally not backing up $(gray)${curpath}$(reset)"
		fi
		local backuppath=
	fi

  local tmppath="$TMPDIR/$curfile"
  local result=0  # Return variable

  if [ -e "$tmppath" ]; then
    warn "Remove old temp file $(gray)${tmppath}$(reset)"
    color_output
    rm -v "$tmppath"
    reset
  fi


	if [ -e "$curpath" -a "$clobber" != 1 ]; then
		if [ "$create_diff" != 1 ]; then
			err "Target file $(gray)${curpath}$(reset) already exists, aborting"
			return 5
		fi
	fi

  if [ ! -e "$srcpath" ]; then
    warn "Source $(gray)${srcfile}$(reset) does not exist"
    return 0
  fi

	local newsrc="$srcpath"
	if [ "$create_diff" == 1 ]; then
		if [ -e "$diffpath" -a "$clobber" != 1 ]; then
			err "Could not generate new diff, old diff already exists"
			return 5
		fi
		if [ -e "$curpath" ]; then
			create_patch_file "$srcpath" "$curpath" "$diffpath"
			result=$?
			if [ $result -eq 0 ]; then
				info "Created new diff file $(gray)${diffpath}$(reset)"
			elif [ $result -eq 2 ]; then
				return 4
			fi
		fi
		return 0
  elif [ -e "$diffpath" ]; then
		create_patched_file "$srcpath" "$diffpath" "$tmppath"
		result=$?
		if [ $result -eq 0 -a -e "$tmppath" ]; then
			newsrc="$tmppath"
		elif [ $result -gt 1 ]; then
			return 3
		fi
	fi
	replace_symlink "$curpath"

	if [ ! -z "$backuppath" ]; then
		backup_target_file "$newsrc" "$curpath" "$backuppath"
	fi

  install_file "$newsrc" "$curpath" "$backuppath"
  result=$?

  if [ $result -eq 0 ]; then
		## Did nothing
		warn "Did not install file"
	elif [ $result -eq 1 ]; then
    info "File successfully installed, $(gray)${target}$(reset)"
  else
    warn "Could not install file"
  fi
  return $result
}

# vim: ts=2 sw=2
