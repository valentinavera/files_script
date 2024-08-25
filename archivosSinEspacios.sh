#!/bin/bash

# Global variables for directory path and new folder
PDF_DIR="$1"
NEW_FOLDER="${PDF_DIR}/FormatFiles"

# Function to convert a string to PascalCase
remove_characters() {
    local input="$1"
    local sanitized

    # Extract the first two characters (assuming they are numbers)
    local prefix
    prefix=$(printf '%s' "$input" | grep -oE '^[0-9]{2}')

    # Remove the first two characters from the input
    local rest
    rest=$(printf '%s' "$input" | sed -E 's/^[0-9]{2}//')

    # Remove numbers, commas, dots, hyphens, underscores
    sanitized=$(printf '%s' "$rest" | tr -d '[:digit:],._-')

    #Remove string and fix text
    newname=$(sed -E 's/\b(De|Del)([A-Z])/\2/g'<<<"sanitized")

    # Combine the prefix with the PascalCase part
    printf '%s' "0$prefix$newname"
}

# Function to copy and rename PDF files
copy_and_rename_pdfs() {
    local pdf_file new_name base_name pascal_case_name dir new_dir

    find "$PDF_DIR" -type f -name '*.pdf' | while read -r pdf_file; do
        dir=$(dirname "$pdf_file")
        base_name=$(basename "$pdf_file" .pdf)
        pascal_case_name=$(remove_characters "$base_name")
        new_name="${NEW_FOLDER}/$(basename "$dir")/${pascal_case_name}.pdf"

        # Create the corresponding directory in the NEW_FOLDER
        new_dir="${NEW_FOLDER}/$(basename "$dir")"
        mkdir -p "$new_dir"

        # Copy and rename the file to the new directory
        if cp "$pdf_file" "$new_name"; then
            printf 'Copied and renamed %s to %s\n' "$pdf_file" "$new_name"
        else
            printf 'Failed to copy and rename %s to %s\n' "$pdf_file" "$new_name" >&2
            return 1
        fi
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
