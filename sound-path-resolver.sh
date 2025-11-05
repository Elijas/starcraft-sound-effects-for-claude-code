#!/bin/bash

# Sound Path Resolver
# Resolves sound paths from config, supporting both individual files and folders
# If a folder is provided, randomly selects a .wav file from it

# Function to resolve a sound path (file or folder)
# Args:
#   $1 - relative path from config (can be file or folder)
#   $2 - optional: JSON array of filenames to exclude (e.g., '["file1.wav","file2.wav"]')
# Returns:
#   Full path to a playable sound file
resolve_sound_path() {
    local relative_path="$1"
    local exclude_json="$2"

    if [ -z "$relative_path" ]; then
        return 1
    fi

    # Construct full path from root
    local full_path="${STARCRAFT_ROOT_DIR}/${relative_path}"

    # Check if it's a file
    if [ -f "$full_path" ]; then
        echo "$full_path"
        return 0
    fi

    # Check if it's a directory
    if [ -d "$full_path" ]; then
        # Build exclude list from JSON array if provided
        local exclude_files=()
        if [ -n "$exclude_json" ]; then
            # Parse JSON array into bash array
            while IFS= read -r filename; do
                exclude_files+=("$filename")
            done < <(echo "$exclude_json" | jq -r '.[]' 2>/dev/null)
        fi

        # Find all .wav files in the directory (non-recursive)
        local wav_files=()
        while IFS= read -r -d '' file; do
            local basename_file=$(basename "$file")

            # Check if file should be excluded
            local should_exclude=false
            for exclude_name in "${exclude_files[@]}"; do
                if [ "$basename_file" = "$exclude_name" ]; then
                    should_exclude=true
                    break
                fi
            done

            # Add to list if not excluded
            if [ "$should_exclude" = false ]; then
                wav_files+=("$file")
            fi
        done < <(find "$full_path" -maxdepth 1 -type f -name "*.wav" -print0 2>/dev/null)

        # Check if we found any wav files
        if [ ${#wav_files[@]} -eq 0 ]; then
            return 1
        fi

        # Pick a random file
        local random_index=$((RANDOM % ${#wav_files[@]}))
        echo "${wav_files[$random_index]}"
        return 0
    fi

    # Path doesn't exist
    return 1
}
