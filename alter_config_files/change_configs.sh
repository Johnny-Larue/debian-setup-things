#!/bin/bash

# Expand the tilde to $HOME in the input paths
expand_path() {
    local path=$1
    echo $(eval echo $path)
}

# Define the URL where the change instructions file is located
CONFIG_CHANGES_URL="https://raw.githubusercontent.com/Johnny-Larue/debian-setup-things/main/alter_config_files/change_config_data.txt"

# Function to download the change instructions file
download_config_changes() {
    echo "Downloading configuration changes file..."
    if curl -o change_config_data.txt "$CONFIG_CHANGES_URL"; then
        echo "Configuration changes file downloaded successfully."
    else
        echo "Failed to download the configuration changes file."
        exit 1
    fi
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

# Check if dry run mode is activated
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "\e[33mDry run mode activated. No changes will be made.\e[0m"
fi

# Download the configuration changes file before processing
download_config_changes

# Read the configuration changes file line by line
while IFS='|' read -r change_type target_file search_text modification_text comment_text; do
    target_file=$(expand_path "$target_file")

    # Perform a dry run or make actual changes
    if [ "$DRY_RUN" = true ]; then
        print_modification "$change_type" "$target_file" "$modification_text" "$comment_text"
    else
        # Check if the target file exists
        if [ ! -f "$target_file" ]; then
            echo -e "\e[31mTarget file does not exist:\e[0m $target_file"
            continue
        fi

        # Backup the file before changes
        backup_file "$target_file"

        # Apply the change based on the type
        case $change_type in
            add)
                if ! grep -Fq "$search_text" "$target_file"; then
                    # Use printf instead of echo to handle special characters
                    printf "%s\n" "$modification_text # $comment_text" >> "$target_file"
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
