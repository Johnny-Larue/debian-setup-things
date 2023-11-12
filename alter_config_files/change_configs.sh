#!/bin/bash

# Function to print modification message (dry run mode)
print_modification_dry_run() {
    local change_type=$1
    local target_file=$2
    local text=$3
    local comment=$4
    echo -e "\e[32m[DRY RUN] Would apply \e[0m\e[1mType:\e[0m $change_type \e[1mFile:\e[0m $target_file \e[1mText:\e[0m \"$text\" \e[1mComment:\e[0m \"$comment\""
}

# Function to print modification message
print_modification() {
    local change_type=$1
    local target_file=$2
    local text=$3
    local comment=$4
    echo -e "\e[32m[MODIFICATION]\e[0m \e[1mType:\e[0m $change_type \e[1mFile:\e[0m $target_file \e[1mText:\e[0m \"$text\" \e[1mComment:\e[0m \"$comment\""
}

# Check if dry run mode is activated
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "\e[33mDry run mode activated. No changes will be made.\e[0m"
fi

# Read the configuration changes file line by line
while IFS= read -r line
do
    # Parse the line into variables
    read -ra ADDR <<< "$line"
    change_type=${ADDR[0]}
    target_file=${ADDR[1]}
    search_text=${ADDR[2]}
    modification_text=${ADDR[3]}
    comment_text=${ADDR[4]}

    # Perform a dry run or make actual changes
    if [ "$DRY_RUN" = true ]; then
        print_modification_dry_run "$change_type" "$target_file" "$modification_text" "$comment_text"
    else
        # Check if the target file exists
        if [ ! -f "$target_file" ]; then
            echo -e "\e[31mTarget file does not exist:\e[0m $target_file"
            continue
        fi

        # Backup the file before changes
        local backup_file="${target_file}.$(date +%Y%m%d%H%M%S)"
        cp "$target_file" "$backup_file" && echo -e "\e[36mBackup created:\e[0m $backup_file"

        # Apply the change based on the type
        case $change_type in
            add)
                if ! grep -Fq "$search_text" "$target_file"; then
                    echo "$modification_text # $comment_text" >> "$target_file"
                    print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
                fi
                ;;
            change)
                if grep -Fq "$search_text" "$target_file"; then
                    sed -i "s|${search_text}|${modification_text} # $comment_text|g" "$target_file"
                    print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
                fi
                ;;
            uncomment)
                sed -i "/${search_text}/s/^#[[:space:]]*//g" "$target_file"
                print_modification "$change_type" "$target_file" "$search_text" "$comment_text"
                ;;
            comment)
                sed -i "/${search_text}/s/^/#/g" "$target_file"
                print_modification "$change_type" "$target_file" "$search_text" "$comment_text"
                ;;
            regex_replace)
                sed -E -i "s|${search_text}|${modification_text} # $comment_text|g" "$target_file"
                print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
                ;;
            *)
                echo -e "\e[31mUnsupported change type:\e[0m $change_type"
                ;;
        esac
    fi
done < "change_config_data.txt"

exit 0
