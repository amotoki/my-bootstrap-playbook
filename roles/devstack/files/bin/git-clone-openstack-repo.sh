#!/bin/sh

GIT_BASE=https://git.openstack.org/

usage() {
  cat <<EOF
Usage: $0 <repo> [category]

  repo: repository base name
  category: openstack, openstack-dev, openstack-infra
    If not speciifed, all categories will be tried in this order.
    As shortcuts, dev, infra, stack|forge|sf can be used.
EOF
}

get_category() {
  local category=$1
  if [ -n "$category" ]; then
    case $category in
      openstack)
        echo openstack
        ;;
      openstack-dev|dev)
        echo openstack-dev
        ;;
      openstack-infra|infra)
        echo openstack-infra
        ;;
      *)
        echo "The specified category is not supported."
        usage
        exit 1
    esac
  else
    echo openstack openstack-infra openstack-dev
  fi
}

if [ -z "$1" ]; then
  usage
  exit 1
fi
repo=$1
categories=$(get_category $2)

for category in $categories; do
  git clone $GIT_BASE/$category/$repo
  if [ $? -eq 0 ]; then
    break
  fi
done
