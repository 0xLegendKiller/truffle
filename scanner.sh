#!/bin/bash

show_help() {
  echo "Usage: $0 <input_file>"
}

if [[ $1 == "-h" || $1 == "--help" ]]; then
  show_help
  exit 0
fi

if [ -z "$1" ]; then
  echo "Error: no input file provided"
  exit 1
fi

input_file="$1"
if [ ! -f "$input_file" ]; then
  echo "Error: input file '$input_file' not found"
  exit 1
fi

parent_dir=$(pwd)

while true; do
  while IFS= read -r line || [ -n "$line" ]; do
    url=$(echo "$line" | cut -d " " -f 1)
    
    if [[ $url == https://* ]]; then
      repo=$(echo "$url" | sed -e 's#.*github.com/##' -e 's/\.git//')

      if [ -d "$repo" ]; then
        cd "$repo" || continue
        
        git fetch

        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})

        if [ "$LOCAL" != "$REMOTE" ]; then
          git -c credential.helper='cache --timeout=3600' pull
          cd "$parent_dir"
          trufflehog filesystem "$repo" | tee -a detected_secrets.log
        fi
        
        cd "$parent_dir"
      else
        git -c credential.helper='cache --timeout=3600' clone "$url" "$repo" || continue
        
        cd "$parent_dir"
        trufflehog filesystem "$repo" | tee -a detected_secrets.log
      fi
    fi
  done < "$input_file"
  
  sleep 10
done
