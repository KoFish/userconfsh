THIS="${BASH_SOURCE[0]}"
SCRIPT_HERE=$( cd "$( dirname "${THIS}" )" && pwd )
UTIL_HERE="$(dirname $SCRIPT_HERE)/utils.d"

source "${UTIL_HERE}/debug.sh"

# create_diff <file A> <file B> <diff-file>
#
# Creates the diff-file if file A and B differs.
create_diff() {
	local current=$1
	local new=$2
	local diff=$3
	local tmp=`mktemp`

	if [ -e "$diff" -a "${CLOBBER}" != 1 ]; then
		warn "Diff file $(gray)${diff}$(color_reset) already exists"
		return 2
	fi

	rm --force "$tmp"
	diff --unified "$new" "$current" > "$tmp"
	local result=$?
	if [ $result -eq 1 ]; then
		# Files where different
		color_output
		mkdir -p -v `dirname "$diff"`
		color_reset
		mv "$tmp" "$diff"
		return 0
	else
		# There where no difference between the files
		rm --force "$tmp"
		return 1
	fi
}

patch_file() {
	local output=$1
	local input=$2
	local diff=$3

	if [ -e "$output" -a "${CLOBBER}" != 1 ]; then
		warn "File $(gray)${output}$(color_reset) already exists"
		return 2
	fi

	if [ -e "$diff" ]; then
		color_output
		patch -p1 "$input" "$diff" -o "$output"
		local result=$?
		color_reset
		if [ $result -ne 0 ]; then
			if [ -e "$output" ]; then
				rm "$output"
			fi
			warn "Could not apply diff!"
		else
			return 0
		fi
	fi
	return 1
}

COMMAND=$1
           #  Patch |  Diff  |
CURR="$2"  # Output | Input  |
SRC="$3"   # Input  | Output |
DIFF="$4"  # Input  | Output |
case "$COMMAND" in
	create)
		create_diff "$CURR" "$SRC" "$DIFF"
		;;
	patch)
		patch_file "$CURR" "$SRC" "$DIFF"
		;;
	*) ;;
esac

# vim: ts=2 sw=2 tw=100
