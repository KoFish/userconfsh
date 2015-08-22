SCRIPT_HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
UTIL_HERE="$(dirname $SCRIPT_HERE)/utils.d"

source "$(dirname $UTIL_HERE)/utils.d/debug.sh"

CMD=$1

clone_repo() {
	local root=$1
	local name=$2
	local url=$3

	color_output
	mkdir -v -p $root
	color_reset

	if [ -d "$root/$name" ]; then
		info "Repo ${name} already cloned, pulling for update"
		color_output
		git -C $root/$name pull --ff-only
		local result=$?
		color_reset
		if [ $result -ne 0 ]; then
			return 2
		fi
	else
		info "Cloning a fresh copy of the repo ${name} into ${root}/${name}"
		color_output
		git -C $root clone $url $name
		local result=$?
		color_reset
		if [ $result -ne 0 ]; then
			return 3
		fi
	fi
}

case "$CMD" in
	clone_repo)
		clone_repo $2 $3 $4
		exit $?
		;;
	*)
		err "Unknown command"
		;;
esac

# vim: sw=2 ts=2:
