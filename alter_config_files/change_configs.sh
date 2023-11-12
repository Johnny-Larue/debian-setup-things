#!/bin/bash

# Function to expand the tilde to $HOME in the input paths
expand_path() {
    local path=$1
    echo $(eval echo $path)
}

# Function to backup a file with a timestamp
backup_file() {
    local file=$1
    local backup="${file}.$(date +%Y%m%d%H%M%S)"
    echo -e "\e[36mBackup created:\e[0m $backup"
    cp "$file" "$backup"
}

# Function to print modification message
print_modification() {
    local change_type=$1
    local target_file=$2
    local text=$3
    local comment=$4
    echo -e "\e[32m[MODIFICATION]\e[0m \e[1mType:\e[0m $change_type \e[1mFile:\e[0m $target_file \e[1mText:\e[0m \"$text\" \e[1mComment:\e[0m \"$comment\""
}

# Function to append a comment to a line
append_comment() {
    local text=$1
    local comment=$2
    # Prepend # to comment text if it's not empty
    [[ ! -z "$comment" ]] && comment="# $comment"
    echo "$text $comment"
}

# Function to add or replace text in the target file
modify_file() {
    local target_file=$1
    local search_text=$2
    local modification_text=$3
    local comment_text=$4
    local change_type=$5

    if ! grep -Fq "$search_text" "$target_file"; then
        case $change_type in
            add)
                printf "%s\n" "$(append_comment "$modification_text" "$comment_text")" >> "$target_file"
                ;;
            change)
                sed -i "s|${search_text}|$(append_comment "$modification_text" "$comment_text")|g" "$target_file"
                ;;
            # Other change types can be added here
        esac
        print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
    fi
}

# Check if dry run mode is activated
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "\e[33mDry run mode activated. No changes will be made.\e[0m"
fi

# Download the configuration changes file before processing
# Function to download should be defined here if needed

# Check if the configuration changes file exists
if [ ! -f "change_config_data.txt" ]; then
    echo "Configuration changes file does not exist."
    exit 1
fi

# Read the configuration changes file line by line
while IFS='|' read -r change_type target_file search_text modification_text comment_text; do
    target_file=$(expand_path "$target_file")

    if [ "$DRY_RUN" = true ]; then
        print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
    else
        if [ ! -f "$target_file" ]; then
            echo -e "\e[31mTarget file does not exist:\e[0m $target_file"
            continue
        fi

        backup_file "$target_file"
        modify_file "$target_file" "$search_text" "$modification_text" "$comment_text" "$change_type"
    fi
done < "change_config_data.txt"

exit 0
