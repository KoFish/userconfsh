#!/bin/sh

UTIL_HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${UTIL_HERE}/colors.sh"

info() {
  >&2 echo -e "$(green) --$(reset) " $*
}

warn() {
  >&2 echo -e "$(yellow) --$(reset) " $*
}

err() {
  >&2 echo -e "$(red) EE$(reset) " $*
}

color_output() {
  echo -ne "\033[3;36m"
}

# vim: ts=2 sw=2
