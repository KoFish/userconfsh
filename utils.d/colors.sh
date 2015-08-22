#!/bin/sh

blue() {
  echo -ne "\033[1;34m"
}

gray() {
  echo -ne "\033[1;30m"
}

green() {
  echo -ne "\033[32m"
}

yellow() {
  echo -ne "\033[33m"
}

red() {
  echo -ne "\033[31m"
}

reset() {
  echo -ne "\033[0m"
}

# vim: ts=2 sw=2
