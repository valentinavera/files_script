#!/bin/bash

# Global variables for directory path and new folder
PDF_DIR="$1"
NEW_FOLDER="${PDF_DIR}/FormatFiles"

index_folder() {
    local base_name="$1"
    local index="$2"
    local rest
    local cleaned_name

    # Extract the first two characters (assuming they are numbers)
    local prefix
    prefix=$(printf '%s' "$base_name" | grep -oE '^[0-9]{2}')
    
    # Remove the first two characters from the base_name
    rest=$(printf '%s' "$base_name" | sed -E 's/^[0-9]{2}//')

    # Remove numbers, commas, dots, hyphens, underscores
    cleaned_name=$(printf '%s' "$rest" | tr -d '[:digit:],._-')

    # Prepend the index, formatted as 3 digits (e.g., 001, 002)
    printf '%03d%s' "$index" "$cleaned_name"
}

copy_and_rename_pdfs() {
    local pdf_file
    local new_name
    local base_name
    local indexed_name
    local dir
    local new_dir
    local file_count
    local last_dir=""

    find "$PDF_DIR" -type f -name '*.pdf' | while read -r pdf_file; do
        dir=$(dirname "$pdf_file")

        # Skip processing if the directory is NEW_FOLDER
        if [[ "$dir" == "$NEW_FOLDER" || "$dir" == "$NEW_FOLDER"/* ]]; then
            continue
        fi

        # Reset file_count if we're in a new directory
        if [[ "$dir" != "$last_dir" ]]; then
            file_count=1
            last_dir="$dir"
        fi

        base_name=$(basename "$pdf_file" .pdf)
        indexed_name=$(index_folder "$base_name" "$file_count")

        # Create the corresponding directory structure in the NEW_FOLDER
        relative_path="${dir#$PDF_DIR/}"
        new_dir="${NEW_FOLDER}/${relative_path}"
        mkdir -p "$new_dir"

        new_name="${new_dir}/${indexed_name}.pdf"

        # Copy and rename the file to the new directory
        if cp "$pdf_file" "$new_name"; then
            printf 'Copied and renamed %s to %s\n' "$pdf_file" "$new_name"
        else
            printf 'Failed to copy and rename %s to %s\n' "$pdf_file" "$new_name" >&2
            return 1
        fi

        file_count=$((file_count + 1))
    done
}

# Main function
main() {
    if [[ -z "$PDF_DIR" || ! -d "$PDF_DIR" ]]; then
        printf 'Usage: %s <directory>\n' "$(basename "$0")" >&2
        return 1
    fi

    # Create the new folder
    mkdir -p "$NEW_FOLDER"

    copy_and_rename_pdfs
}

# Run main function
main "$@"
