#!/bin/bash

#liveGitStatus.sh - by Jody Salani

	# Keeps a running track of $(git status) for a given repository. Can be used to instantly show changes to the repo or, for machines with 
	# less resources, can simply refresh on a time-interval. It's pretty lightweight, meant to keep open to the side or on another monitor
	# while you work. I hope it's an effective tool for you!

		# Optional Arguments:

			# -b, --branchList: lists all repo branches with status, current branch displays with an asterisk '*'.
			# -g, --gitTrack: instead of running solely on a time interval, this option will parse differences in tracked files, as well
				# as new untracked files and changes to the active branch, and refresh status in any of those scenarios. 
				# It will also refresh on a time interval if no activity is detected prior.
				# Note: In this mode, refresh will not occur on user input to prevent interruptions to updating the tracking.
			# -p, --path [ filepath ]: designates the root directory of the git repository. Defaults to the current directory.
			# -t, --time [ refreshInterval ]: designates the number of seconds between status refreshes, defaults to '10'.
				# In this mode, refresh will also occur on user input.

		# Exit Codes:

			# 1: optional argument not recognized
			# 2: directory not found
			# 3: directory does not contain a git repository
			# 4: time interval provided is not an integer

	# Please send any inquiries or feedback to <dc831010@protonmail.ch>

function getStatus {
	clear

	#heading
	num_dashes=$((`tput cols` - 4))
	topline=`printf "/*"; for (( i=1; i<=$num_dashes; i++)); do printf "-"; done; printf "*/"`

	#repo info
	printf "$topline\n${bold}$(basename -s .git `git config --get remote.origin.url`)${normal} repository - $(date)\n\n"

	#branch info
	if [ "${display_branches}" = true ]; then
		printf "Branches:\n"
		git branch -a
		echo
	fi

	#status
	git status
	echo
}

#formatting
bold=$(tput bold) #text bold
normal=$(tput sgr0) #text std

#Define default values (overwritten by optional parameters)
directory="."
display_branches=false
gitDiff_refresh=false
interval_time=10

#parse optional parameters
while [ "${1}" != '' ]; do

	case "${1}" in
		-b | --branchList )
			display_branches=true
			shift
			;;
		-g | --gitTrack )
			gitDiff_refresh=true
			shift
			;;
		-p | --path )
			if [ ! -z "$2" ]; then directory="$2"; else directory="."; fi
			shift 2
			;;
		-t | --time )
			if [ ! -z "$2" ]; then interval_time="$2"; else interval_time=10; fi
			shift 2
			;;
		*)
			echo "ERROR: optional argument ${1} not recognized. Exiting..."
		 	exit 1
		 	;;
	esac

done

if [ -d "$directory" ]; then

	cd "$directory"

	if [ -d .git ]; then
		
		if [ "$gitDiff_refresh" = true ]; then

			#tracked file differences
			gitDiff=`git diff`
			old_gitDiff=''

			#untracked file differences
			gitUntracked=`git ls-files --others --exclude-standard`
			old_gitUntracked=''

			#branch name differece
			gitBranch=`git rev-parse --abbrev-ref HEAD`
			old_gitBranch=''

			passCount=0

			while True; do 

				passCount=$((passCount+1))

				if [ "$gitDiff" != "$old_gitDiff" \
					-o "$gitUntracked" != "$old_gitUntracked" \
					-o "$gitBranch" != "$old_gitBranch" \
					-o "$passCount" -eq "1" ]; then

					getStatus
					printf "Refreshing on differences found in the repo, or after ${interval_time} seconds. Press CTRL + C to quit."
					passCount=1
				fi

				sleep 1

				old_gitDiff="$gitDiff"
				gitDiff=`git diff`

				old_gitUntracked="$gitUntracked"
				gitUntracked=`git ls-files --others --exclude-standard`

				old_gitBranch="$gitBranch"
				gitBranch=`git rev-parse --abbrev-ref HEAD`

				if [ "$passCount" -eq "$interval_time" ]; then passCount=0; fi

			done

		elif [[ $interval_time =~ ^[0-9]+$ ]]; then

			while True; do 
				getStatus
				read -t $interval_time -p "Refreshing every ${interval_time} seconds, Press ENTER to get git status immediately, or CTRL + C to quit."
			done

		else
			printf "Time Interval -t must be an integer. Exiting...\n"
			exit 4
		fi

	else
		printf "Directory ${directory} does not contain a git repository. Exiting...\n"
		exit 3
	fi

else
	printf "Directory ${directory} was not found on this machine. Exiting...\n"
	exit 2
fi
