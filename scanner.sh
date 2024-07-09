#!/bin/bash

# Check if the help option was provided
if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "Usage: $0 <input_file>"
  echo "This script takes an input file containing GitHub URLs and scans each repository using TruffleHog."
  exit 0
fi

# Check that an input file path was provided
if [ -z "$1" ]; then
  echo "Error: no input file provided"
  echo "Run '$0 -h' or '$0 --help' for usage information."
  exit 1
fi

# Check that the input file exists
if [ ! -f "$1" ]; then
  echo "Error: input file not found"
  echo "Run '$0 -h' or '$0 --help' for usage information."
  exit 1
fi

# Prompt the user for the access token
#read -p "Enter your GitHub personal access token: " token

# Loop through each line in the input file
while read -r line
do
  # Extract the GitHub URL from the line
  url=$(echo "$line" | cut -d " " -f 2)
  #echo $url
  # Check that the URL starts with "https://"
  if [[ $url == https://* ]]; then
    # Extract the repository name from the URL
    repo=$(echo "$url" | sed -e 's#.*github.com/##' -e 's/\.git//')
    #echo $repo
    #pwd
    # Check if the repository has already been cloned
    if [ -d "$repo" ]; then
      # Pull any new changes from the repository
      cd "$repo" || continue
      git -c credential.helper='cache --timeout=3600' pull
      
      cd ..
      echo $repo
      # Check if there are any changes
      
      if [ -n "$(git -C ../$repo status --porcelain)" ]; then
        # Use TruffleHog to scan the GitHub repository for secrets
        trufflehog filesystem $repo | notify -silent
        #trufflehog --regex --entropy=False --clone-path "$repo" --github-access-token "$token" "$url"
      else
        echo "No new changes for $url"
        cd ..
        
      fi
    else
      # Clone the repository and use TruffleHog to scan it for secrets
      git -c credential.helper='cache --timeout=3600' clone "$url" "$repo"
      trufflehog filesystem $repo | notify -silent
      #trufflehog --regex --entropy=False --clone-path "$repo" --github-access-token "$token" "$url"
    fi
  else
    echo "Error: invalid URL format for line: $line"
  fi
done < "$1"
