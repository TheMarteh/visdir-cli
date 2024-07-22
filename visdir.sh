#!/bin/bash

# VISDIR - a cli tool to create beautiful visualisations of your
# directories. 

# Usage: visdir [OPTION]... [DIRECTORY]...
# Visualize the DIRECTORY structure (the current directory by default)
# 
# -s, --show-file-sha256    append the calculated SHA256 hash of the file contents to the filename. Defaults to 6 characters.
#                           see [-q, --hashes-length=NUM] to specify the amount of characters
# -c, --show-file-contents  show the contents of the files in the visualization. Defaults to max 5 lines.
#                           see [-l, --content-length=NUM] to specify the max amount of lines to show
# -h, --help                print usage and this help message and exit.
# 
# -d, --depth=NUM           stop handling directories nested deeper than NUM directories
# -q, --hashes-length=NUM   constrain the calculated hash to NUM characters. See [-s, --show-file-sha256]
# -l, --content-length=NUM  constrain the max amount of lines to show per file to NUM lines. See [-c, --show-file-contents]
# -o, --output=FILENAME     output the visualization to FILENAME instead of stdout

# helptext
usage() {
    local usageText="VISDIR - a cli tool to create beautiful visualisations of your
directories. 

Usage: visdir [OPTION]... [DIRECTORY]...
Visualize the DIRECTORY structure (the current directory by default)

-s, --show-file-sha256    append the calculated SHA256 hash of the file contents to the filename. Defaults to 6 characters.
                          see [-q, --hashes-length=NUM] to specify the amount of characters
-c, --show-file-contents  show the contents of the files in the visualization. Defaults to max 5 lines.
                          see [-l, --content-length=NUM] to specify the max amount of lines to show
-h, --help                print usage and this help message and exit.

-d, --depth=NUM           stop handling directories nested deeper than NUM directories
-q, --hashes-length=NUM   constrain the calculated hash to NUM characters. See [-s, --show-file-sha256]
-l, --content-length=NUM  constrain the max amount of lines to show per file to NUM lines. See [-c, --show-file-contents]
-o, --output=FILENAME     output the visualization to FILENAME instead of stdout
    "
    echo "$usageText"
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

        # object is the last entry of the directory
        if [ $index -eq $((child_count -1)) ]; then
            child_prefix="  "
            child_pointer="└─"
        fi

        # object is a directory
        if [ -d "$child" ]; then 
            echo "${prefix}${child_pointer}${child##**/}"
            if [ $depth -lt $max_recursion_depth ]; then
                traverse_dir "$child" "${prefix}$child_prefix" $((depth + 1))
            fi
        fi

        # object is a file
        if [ -f "$child" ]; then
            # calculate and show file content hash if flag is set
            local hashString=""
            if [ $show_hashes = true ]; then
                local hash=$(sha256sum "$child" | cut -c1-$hashes_length)
                local hashString="  [${hash}]"
            fi

            # print the line containing the filename (and optional hash)
            echo "${prefix}${child_pointer}${child##**/}${hashString}"

            # show file contents line by line if flag is set
            if [ $show_file_content = true ]; then
                local line_number=0
                while IFS= read -r line; do
                    echo "${prefix}$child_prefix >> ${line}"
                    line_number=$((line_number + 1))

                    # handle large files
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
OPTSTRING=":schd:q:l:o:"

# default behaviour
root="."                # [DIRECTORY]
show_hashes=false       # -s, --show-file-sha256
show_file_content=false # -c, --show-file-contents
max_recursion_depth=3   # -d, --depth=NUM           [non-negative int]
hashes_length=6         # -q, --hashes-length=NUM   [non-negative int < 16]
max_file_lines_toshow=5 # -l, --content-length=NUM  [non-negative int]
outputfile=""           # -o, --output=FILENAME     [string]

# transform long options into short options
for arg in "$@"; do
    shift
    case "$arg" in
        '--show-file-sha256')   set -- "$@" '-s'    ;;
        '--show-file-contents') set -- "$@" '-c'    ;;
        '--depth')              set -- "$@" '-d'    ;;
        '--hashes-length')      set -- "$@" '-q'    ;;
        '--content-length')     set -- "$@" '-l'    ;;
        '--help')               set -- "$@" '-h'    ;;
        '--output')             set -- "$@" '-o'    ;;
        *)                      set -- "$@" "$arg"  ;;
    esac
done
shift $(expr $OPTIND - 1)

# handling options
while getopts ${OPTSTRING} opt; do
    case ${opt} in
        d)
            # the arg passed to [-d, --depth] should be a non-negative int
            if [[ ! ${OPTARG} =~ ^[0-9]+$ ]]; then
                echo "Error: -${OPTARG} requires a non-negative integer as an argument" >&2
                usage
            fi
            max_recursion_depth=${OPTARG}
            ;;

        s)
            show_hashes=true ;;
        c)
            show_file_content=true ;;
        q)
            # the arg passed to [-q, --hashes-length] should be a non-negative int <= 16
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] && [[ ${OPTARG} -le 16 ]] && [[ ${OPTARG} -ge 1 ]]; then
                hashes_length=${OPTARG}
            else
                echo "Error: -${OPTARG} requires an integer in the range of 1-16 as an argument" >&2
                usage
            fi
            ;;
        l)
            # the arg passed to [-l, --content-length] should be a non-negative int
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] && [[ ${OPTARG} -ge 1 ]]; then
                max_file_lines_toshow=${OPTARG}
            else
                echo "Error: -${OPTARG} requires non-negative integer as an argument" >&2
                usage
            fi
            ;;
        h) usage ;;
        o) 
            echo "Error, output is not implemented yet" >&2
            usage ;;
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