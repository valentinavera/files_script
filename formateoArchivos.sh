#!/bin/bash

# Global variables for directory path and new folder
PDF_DIR="$1"
NEW_FOLDER="${PDF_DIR}/FormatFiles"

# Function to keep string found
find_string() { 
    local text="$1" 
    local substrings=("Poder" "Sentencia" "ActaAudiencia" "ConstanciaEjecutoria" "OficioDevolucion" "ConstanciaDevolucion" "NotificacionProcurador" "Auto" "DemandaCasacion" "OficioACorteSuprema") 
    for substring in "${substrings[@]}"; do 
        if echo "$text" | grep -q "$substring"; then 
            echo "$substring" 
            return 
        fi 
    done 
    echo "$text"
}

to_pascal_case() {
    local input="$1"
    local sanitized
    local prefix
    local rest
    local newname
    local fixed_text
    local final_name

    # Extract the first two characters (assuming they are numbers)
    prefix=$(printf '%s' "$input" | grep -oE '^[0-9]{2}')

    # Remove the first two characters from the input
    rest=$(printf '%s' "$input" | sed -E 's/^[0-9]{2}//')

    # Remove numbers, commas, dots, hyphens, underscores
    sanitized=$(printf '%s' "$rest" | tr -d '[:digit:],._-')

    if printf '%s' "$sanitized" | grep -q ' '; then
        # Convert the entire input to lowercase
        input=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')

        # Convert to PascalCase
        sanitized=$(printf '%s' "$sanitized" | sed -E 's/(^|[[:space:]])([a-z])/\U\2/g')

        # Remove any remaining spaces
        sanitized=$(printf '%s' "$sanitized" | tr -d ' ')
    fi

    # Remove substring "De" followed by a uppercase letter for non-space input
    newname=$(sed 's/De\([A-Z]\)/\1/g' <<< "$sanitized")
    # Remove substring "Del" followed by a uppercase letter for non-space input
    newname=$(sed 's/Del\([A-Z]\)/\1/g' <<< "$sanitized")

    # Correct incomplete words
    fixed_text=$(echo "$newname" | sed -e 's/Devoluc/Devolucion/g' -e 's/Devolviendo/Devolucion/g')

    # Apply find_string to the corrected name
    final_name=$(find_string "$fixed_text")

    # Combine the prefix with the processed part
    printf '%s' "${prefix}${final_name}"
}

copy_and_rename_pdfs() {
    local pdf_file
    local new_name
    local base_name
    local pascal_case_name
    local dir
    local new_dir

    find "$PDF_DIR" -type f -name '*.pdf' | while read -r pdf_file; do
        dir=$(dirname "$pdf_file")
        
        # Skip processing if the directory is FormatFiles
        if [[ "$dir" == "$NEW_FOLDER" || "$dir" == "$NEW_FOLDER"/* ]]; then
            continue
        fi
        base_name=$(basename "$pdf_file" .pdf)
        pascal_case_name=$(to_pascal_case "$base_name")

        # Create the corresponding directory structure in the NEW_FOLDER
        relative_path="${dir#$PDF_DIR/}"
        new_dir="${NEW_FOLDER}/${relative_path}"
        mkdir -p "$new_dir"

        new_name="${new_dir}/${pascal_case_name}.pdf"

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
