#!/bin/bash

shopt -s nullglob

traverse_dir() {
    local dir=$1
    local prefix=$2

    local children=("$dir"/*)
    local child_count=${#children[@]}

    for index in "${!children[@]}"; do
        local child=${children[$index]}

        local child_prefix="│ "
        local child_pointer="├─"

        if [ $index -eq $((child_count -1)) ]; then
            child_pointer="└─"
            child_prefix="  "
        fi

        echo "${prefix}${child_pointer}${child##**/}"
        [ -d "$child" ] && 
            traverse_dir "$child" "${prefix}$child_prefix" ||
            file_count=$((file_count + 1))
    done
}

root="."
[ "$#" -ne 0 ] && root="$1"
echo $root

traverse_dir $root ""

shopt -u nullglob