#!/bin/bash
set -e

# fix-trailing-whitespace.sh: Cross-platform script to remove trailing whitespace
#
# This script removes trailing whitespace from text files where it's safe to do so.
# It skips binary files, version control directories, and files with specific extensions
# that shouldn't be modified (e.g., binary formats).
#
# Usage:
#   ./scripts/fix-trailing-whitespace.sh [file1 file2 ...]
#   If no files are specified, processes all tracked files in the repository.
#
# Options:
#   -d, --dry-run  Show what would be changed without making changes
#   -v, --verbose  Show files being processed
#   -h, --help     Show this help message

DRY_RUN=false
VERBOSE=false
FILES=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [FILES...]"
            echo "Remove trailing whitespace from text files."
            echo ""
            echo "Options:"
            echo "  -d, --dry-run  Show what would be changed without making changes"
            echo "  -v, --verbose  Show files being processed"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "If no files are specified, processes all tracked files in the repository."
            exit 0
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Function to check if a file is text
is_text_file() {
    local file="$1"

    # Skip if file doesn't exist
    [ -f "$file" ] || return 1

    # Skip symlinks
    [ -L "$file" ] && return 1

    # Skip binary files using file command if available
    if command -v file >/dev/null 2>&1; then
        if file -b --mime-type "$file" | grep -q -v '^text/'; then
            return 1
        fi
    fi

    # Skip files with extensions that are likely binary
    case "$file" in
        *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.ico|*.pdf|*.zip|*.tar|*.gz|*.tgz|*.bz2|*.xz|*.jar|*.war|*.class|*.pyc|*.o|*.so|*.dylib|*.dll|*.exe)
            return 1
            ;;
        *.git/*|*.hg/*|*.svn/*)
            return 1
            ;;
    esac

    return 0
}

# Function to remove trailing whitespace from a file
fix_file() {
    local file="$1"

    if ! is_text_file "$file"; then
        [ "$VERBOSE" = true ] && echo "Skipping non-text file: $file"
        return
    fi

    # Check if file has trailing whitespace
    if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
        if [ "$DRY_RUN" = true ]; then
            echo "Would fix trailing whitespace in: $file"
        else
            [ "$VERBOSE" = true ] && echo "Fixing trailing whitespace in: $file"

            # Platform-specific sed commands
            if sed --version 2>/dev/null | grep -q GNU; then
                # GNU sed (Linux)
                sed -i 's/[[:space:]]*$//' "$file"
            elif command -v gsed >/dev/null 2>&1; then
                # GNU sed installed as gsed (macOS with brew install gnu-sed)
                gsed -i 's/[[:space:]]*$//' "$file"
            else
                # BSD sed (macOS)
                sed -i '' 's/[[:space:]]*$//' "$file"
            fi
        fi
    else
        [ "$VERBOSE" = true ] && echo "No trailing whitespace in: $file"
    fi
}

# Main execution
if [ ${#FILES[@]} -eq 0 ]; then
    # Process all tracked files in the repository
    [ "$VERBOSE" = true ] && echo "Processing all tracked files..."

    # Get list of tracked files (excluding deleted files)
    while IFS= read -r file; do
        [ -n "$file" ] && FILES+=("$file")
    done < <(git ls-files 2>/dev/null || find . -type f -name '*' | grep -v '\.git/' | head -1000)
fi

# Process each file
for file in "${FILES[@]}"; do
    # Handle glob patterns
    if [[ "$file" == *"*"* ]]; then
        for expanded_file in $file; do
            [ -e "$expanded_file" ] && fix_file "$expanded_file"
        done
    else
        [ -e "$file" ] && fix_file "$file"
    fi
done

echo "Done."
if [ "$DRY_RUN" = true ]; then
    echo "This was a dry run. Run without -d to apply changes."
fi