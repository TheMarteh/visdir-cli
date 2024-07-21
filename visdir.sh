#!/bin/bash

# error handling
usage() {
    echo "Visualize a directory tree"
    echo "Usage: $0 [-r <max-tree-depth>] [-d <directory>] [-s <max-file-lines>] [-c [n]] [-h] [directory]"
    exit 1
}

# traversal logic
traverse_dir() {
    local dir=$1
    local prefix=$2
    local depth=$3

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

        [ -d "$child" ] && 
            # object is a directory
            echo "${prefix}${child_pointer}${child##**/}"
            if [ $depth -lt $max_recursion_depth ]; then
            traverse_dir "$child" "${prefix}$child_prefix" $((depth + 1))
            fi
        if [ -f "$child" ]; then
            local hashString=""
            # show file content hash if flag is set
            if [ $show_hashes = true ]; then
                local hash=$(sha256sum "$child" | cut -c1-$hashes_length)
                local hashString="  [${hash}]"
            fi
            echo "${prefix}${child_pointer}${child##**/}${hashString}"
            # object is a file
            file_count=$((file_count + 1))
            # show file content line by line if flag is set
            # up to a certain amount of lines
            # if the file is larger, end the line with "..."
            if [ $show_file_content = true ]; then
                local line_number=0
                while IFS= read -r line; do
                    echo "${prefix}$child_prefix >> ${line}"
                    line_number=$((line_number + 1))
                    if [ $line_number -eq $max_file_lines_toshow ]; then
                        echo "${prefix}$child_prefix >> ..."
                        break
                    fi
                done < "$child"
            fi
            
        fi
    done
}

shopt -s nullglob

# defining flag options
OPTSTRING=":hr:d:s::c:"

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
root="."
# -s [--show-content-hashes]
# optional, accepts optional integer 'max_lines' in range 1-16 as argument
# specifies whether to append the calculated filecontent hash
# in the visualization. The hash will consist of 'n' characters
# defaults to not show any hashes. If the -2 flag is passed without an
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
            # the arg passed to -d or --directory should be a valid filepath
            if [[ ! -d ${OPTARG} ]]; then
                echo "Error: -d requires a valid directory as an argument"
                usage
            fi
            root=${OPTARG}

            ;;
        s)
            show_hashes=true

            # optional arg passed to -s should be an int in range 1-16
            if [[ -n ${OPTARG} ]]; then
                # handle the possibility of passing a string arg
                if [[ ${OPTARG} =~ ^[0-9]+$ ]]; then
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

[ "$#" -ne 0 ] && root="$1"
echo $root

traverse_dir $root "" 0

shopt -u nullglob