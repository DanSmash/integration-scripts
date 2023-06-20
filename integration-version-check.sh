#!/bin/bash

##############################################################################
## Script Name:  integration-version-check.sh
## Author:  DC (Smash)
## Copyright (c) 2023 - Polarity.IO / Breach Intelligence, Inc.
##
## Script Description:
##     Checks integration current versions & fetches latest release numbers
##     for comparison.
##
## Inputs:
##     None
##
## Outputs:
##     - all installed integrations
##     - all installed integration version numbers
##     - corresponding integration latest available release numbers
##
##############################################################################

##### GLOBAL VARIABLES #####
POLARITYSERVER=/app/polarity-server
green=$'\033[32m'
red=$'\033[31m'
bold=$'\033[1m'
normal=$'\033[0m'
italic=$'\033[3m'
declare -a updateAvailable
declare -a upToDate
declare -a noData

##### FUNCTIONS #####
function GetLatest ()                                           ## Gets the latest available version of the integration
{
  # latest=$(curl --silent "https://api.github.com/repos/polarityio/$1/releases/latest" | grep '"tag_name":' | cut -d\" -f4)                    ## This line utilizes the GitHub API
  latest=$(curl -sSI https://github.com/polarityio/$1/releases/latest | grep "location:" | grep -e "[0-9{1,2}].[0-9{1,2}].[0-9{1,2}]" -o)     ## This line uses a standard HTTP call
}

function GetCurrent ()                                          ## Pulls current version of the installed integration
{
  current=$(grep version $POLARITYSERVER/integrations/$1/package.json | cut -d\" -f4 | cut -d- -f1)
}


########## MAIN #########
if [[ $# -gt 0 ]]                                               ## Check if any arguments passed
then
  case "$1" in
    -u|--update-only)                                           ## DISPLAY INTEGRATIONS WITH UPDATES AVAILABLE
      printf "\n\t${bold}%s\n\n${normal}" "Checking Integration Versions . . ."

      for intName in $(ls $POLARITYSERVER/integrations)
      do
        GetLatest $intName
        GetCurrent $intName

        if [[ $latest > $current ]]
        then
          updateAvailable=( "${updateAvailable[@]}" "$intName" )          ## If an update is available, add it to the list
        fi
      done

      printf "\n${red}${bold}%s\n${normal}${bold}" "UPDATE AVAILABLE:"
      for i in "${updateAvailable[@]}"
      do
        echo $i
      done
    ;;

    -f|--full)                                                  ## DISPLAY ALL INTEGRATION VERSIONS
      printf "\n\t${bold}%s\n\n${normal}" "Checking Integration Versions . . ."

      for intName in $(ls $POLARITYSERVER/integrations)
      do
        GetLatest $intName
        GetCurrent $intName

        if [[ "$latest" > "$current" ]]
        then
          printf "${red}${bold}%s\t\t${normal}${bold}%s\n" "UPDATE AVAILABLE" "$intName"
          printf "\t${normal}%s ${red}${bold}%s\n" "Installed Version:  " "$current"
          printf "\t${normal}%s ${green}${bold}%s\n" "Available Version:  " "$latest"
        elif [[ $latest = '' ]]
        then
          printf "${red}${bold}${italic}%s %s${normal}\n" "$intName" "HAS NO UPDATE DATA!"
          printf "\t${normal}%s ${bold}%s\n" "Installed Version:  " "$current"
        elif [[ "$latest" == "$current" ]]
        then
          printf "${green}${bold}%s\t\t\t${normal}${bold}%s\n" "UP TO DATE" "$intName"
          printf "\t${normal}%s ${bold}%s\n" "Installed Version:  " "$current"
          printf "\t${normal}%s ${bold}%s\n" "Available Version:  " "$latest"
        fi
      done
    ;;

    *)                                                          ## CATCH-ALL HELP TEXT FOR ARGUMENTS
      printf "\n${bold}%s\n" "Integration Version Check Script Help"
      printf "${normal}%s\n" "-------------------------------------"
      printf "%s\t\t%s\n" "-? | --help" "This help dialog"
      printf "${italic}%s\t\t\t${normal}%s\n" "blank" "Standard output (listed status of all installed integrations)"
      printf "%s\t%s\n" "-u | --update-only" "Only display integrations with available updates"
      printf "%s\t\t%s\n\n" "-f | --full" "Display all integrations, installed versions, and available versions"

      exit
    ;;
  esac
else
  printf "\n\t${bold}%s\n\n${normal}" "Checking Integration Versions . . ."

  for intName in $(ls $POLARITYSERVER/integrations)
  do
    GetLatest $intName
    GetCurrent $intName

    if [[ $latest > $current ]]
    then
      updateAvailable=( "${updateAvailable[@]}" "$intName" )          ## If an update is available, add it to the list
    elif [[ $latest = '' ]]
    then
      noData=( "${noData[@]}" "$intName" )                            ## If there is no data for an integration, add it to the list
    else
      upToDate=( "${upToDate[@]}" "$intName" )                        ## If integration is up-to-date, add it to the list
    fi
  done

  ### RUN THROUGH THE LISTS ###

  printf "${green}${bold}%s\n${normal}" "UP TO DATE:"
  for i in "${upToDate[@]}"
  do
    echo $i
  done

  printf "\n${red}${bold}%s\n${normal}${bold}" "UPDATE AVAILABLE:"
  for i in "${updateAvailable[@]}"
  do
    echo $i
  done

  if [[ ${#noData[@]} > 0 ]]
  then
    printf "\n${bold}${italic}%s\n" "NO UPDATE DATA:"
    for i in "${noData[@]}"
    do
      echo $i
    done
  fi
fi

### RETURN ALL TEXT TO NORMAL ###
printf "${normal}"

### ADD CR/LF ###
echo