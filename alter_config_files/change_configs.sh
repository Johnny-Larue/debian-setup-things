#!/bin/bash

# Function to backup a file with a timestamp (dry run mode)
backup_file_dry_run() {
    local file=$1
    local backup="${file}.$(date +%Y%m%d%H%M%S)"
    echo -e "\e[36m[DRY RUN] Would create backup:\e[0m $backup"
}

# Function to print formatted output (dry run mode)
print_modification_dry_run() {
    local change_type=$1
    local target_file=$2
    local text=$3
    echo -e "\e[32m[DRY RUN] Would apply \e[0m\e[1mType:\e[0m $change_type \e[1mFile:\e[0m $target_file \e[1mText:\e[0m \"$text\""
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

    # Check if the target file exists (skip if dry run)
    if [ ! -f "$target_file" ] && [ "$DRY_RUN" = false ]; then
        echo -e "\e[31mTarget file does not exist:\e[0m $target_file"
        continue
    fi

    # Perform a dry run or make actual changes
    if [ "$DRY_RUN" = true ]; then
        print_modification_dry_run "$change_type" "$target_file" "$modification_text"
    else
        # Function to backup a file with a timestamp
        backup_file() {
            local file=$1
            local backup="${file}.$(date +%Y%m%d%H%M%S)"
            if cp "$file" "$backup"; then
                echo -e "\e[36mBackup created:\e[0m $backup"
            else
                echo -e "\e[31mFailed to create backup for:\e[0m $file"
                return 1
            fi
        }

        # Backup the file before changes
        backup_file "$target_file"

        # Function to print formatted output
        print_modification() {
            local change_type=$1
            local target_file=$2
            local text=$3
            echo -e "\e[32m[MODIFICATION]\e[0m \e[1mType:\e[0m $change_type \e[1mFile:\e[0m $target_file \e[1mText:\e[0m \"$text\""
        }

        # Apply the change based on the type
        case $change_type in
            add)
                if ! grep -Fq "$search_text" "$target_file"; then
                    echo "$modification_text" >> "$target_file"
                    print_modification "$change_type" "$target_file" "$modification_text"
                fi
                ;;
            change)
                if grep -Fq "$search_text" "$target_file"; then
                    sed -i "s|${search_text}|${modification_text}|g" "$target_file"
                    print_modification "$change_type" "$target_file" "$modification_text"
                fi
                ;;
            uncomment)
                sed -i "/${search_text}/s/^#//g" "$target_file"
                print_modification "$change_type" "$target_file" "$modification_text"
                ;;
            comment)
                sed -i "/${search_text}/s/^/#/g" "$target_file"
                print_modification "$change_type" "$target_file" "$modification_text"
                ;;
            regex_replace)
                sed -E -i "s|${search_text}|${modification_text}|g" "$target_file"
                print_modification "$change_type" "$target_file" "$modification_text"
                ;;
            *)
                echo -e "\e[31mUnsupported change type:\e[0m $change_type"
                ;;
        esac
    fi
done < "change_config_data.txt"

exit 0
