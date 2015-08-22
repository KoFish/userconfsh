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

	if [ -e "$diff" -a -z "${CLOBBER}" ]; then
		warn "Diff file $(gray)${diff}$(color_reset) already exists"
		return 2
	fi

	info "Diff new=$new current=$current"

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
		rm --force "$diff"
		return 1
	fi
}

patch_file() {
	local current=$1
	local new=$2
	local diff=$3

	if [ -e "$current" -a -z "${CLOBBER}" ]; then
		warn "File $(gray)${current}$(color_reset) already exists"
		return 2
	fi

	if [ -e "$diff" ]; then
		color_output
		patch -p1 "$new" "$diff" -o "$current"
		local result=$?
		color_reset
		if [ $result -ne 0 ]; then
			warn "Could not apply diff!"
		else
			return 0
		fi
	fi
	return 1
}

COMMAND=$1
CURR="$2"
NEW="$3"
DIFF="$4"
case "$COMMAND" in
	create)
		create_diff "$CURR" "$NEW" "$DIFF"
		;;
	patch)
		patch_file "$CURR" "$NEW" "$DIFF"
		;;
	*) ;;
esac

# vim: ts=2 sw=2 tw=100
