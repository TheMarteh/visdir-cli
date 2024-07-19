#!/bin/bash

# error handling
usage() {
    echo "visdir: use in your cwd, or pass a directory path using -d". 1>&2
    exit 1
}

# traversal logic
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

shopt -s nullglob

# defining flag options
OPTSTRING=":r:d:s::c::h"

# -r [--max-recursion]
# optional, requires non-negative integer as argument
# specifies the maximum depth the visualization will show
# defaults to 3
max_recursion_depth=3
#
# -d [--directory]
# optional, requires a valid filepath as argument
# specifies the directory to visualize. 
# defaults to the current working directory
# 
# -h [--show-content-hashes]
# optional, accepts optional integer 'n' in range 1-16 as argument
# specifies whether to append the calculated filecontent hash
# in the visualization. The hash will consist of 'n' characters
# defaults to not show any hashes. If the -h flag is passed without an
# integer specified, the hash length will default to 6
show_hashes=false
hashes_length=6
#
# -c [--show-file-contents]
# optional, accepts optional non-negative integer 'n' as argument
# specifies whether to show the file contents underneath the file name.
# defaults to not show any contents. If the -c flag is passed without an
# integer specified, the max amount of lines that will be shown is 5
show_file_content=false
max_file_lines_toshow=5

while getopts ${OPTSTRING} opt; do
    case ${opt} in
        r)
            # the arg passed to -r or --max-recursion should be a non-negative int
            if [[ ! ${OPTARG} =~ ^[0-9]+$ ]]; then
                echo "Error: -r requires a non-negative integer as an argument"
                usage
            fi
            max_recursion_depth=${OPTARG}
            ;;
        d) 
            echo "this is not handled yet"
            usage
            ;;
        s)
            show_hashes=true

            # optional arg passed to -h should be an int in range 1-16
            if [[ -n ${OPTARG} ]]; then
                # handle the possibility of passing a string arg
                if [[ ${OPTARG} =~ ^[0-9]+$ ]] && [ ${OPTARG} -le 16]; then
                    hashes_length=${OPTARG}
                else
                    echo "Error: -s requires an integer in the range of 1-16 as an argument"
                    usage
                fi
            fi    
            ;;
        c)
            show_file_content=true

            # optional arg passed to -c should be a non-negative int
            if [[ -n ${OPTARG} ]]; then
                # handle the possibility of passing a string arg
                if [[ ${OPTARG} =~ ^[0-9]+$ ]]; then
                    max_file_lines_toshow=${OPTARG}
                else
                    echo "Error: -c requires non-negative integer as an argument"
                    usage
                fi
            fi
            ;;
        h) usage ;;
        \?)
            # handle unknown flags
            echo "Error: invalid option: -${OPTARG}" >&2
            usage
            ;;
        :)
            # a valid option has been passed, but the required argument hasn't been
            echo "Error: option -${OPTARG} requires an argument" >&2
            usage
            ;;
    esac;
done
shift $((OPTIND -1))

root="."
[ "$#" -ne 0 ] && root="$1"
echo $root

traverse_dir $root ""

shopt -u nullglob