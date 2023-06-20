#!/bin/bash

##############################################################################
## Script Name:  integration-version-check.sh
## Author:  DC (Smash)
## Version/Date:  3.0.20230619
##
## Script Description:
##     Checks integration current versions & fetches latest release numbers
##     for visual comparison.
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
function GetLatest ()
{
  # latest=$(curl --silent "https://api.github.com/repos/polarityio/$1/releases/latest" | grep '"tag_name":' | cut -d\" -f4)                    ## This line utilizes the GitHub API
  latest=$(curl -sSI https://github.com/polarityio/$1/releases/latest | grep "location:" | grep -e "[0-9{1,2}].[0-9{1,2}].[0-9{1,2}]" -o)     ## This line uses a standard HTTP call
}

function GetCurrent ()
{
  current=$(grep version $POLARITYSERVER/integrations/$1/package.json | cut -d\" -f4 | cut -d- -f1)
}


########## MAIN ##########

echo -e "\n\tChecking Integration Versions . . .\n\n"

for intName in $(ls $POLARITYSERVER/integrations)
do
  GetLatest $intName
  GetCurrent $intName

  if [[ $latest > $current ]]
  then
    # printf "${red}${bold}%s\t\t${normal}${bold}%s\n" "UPDATE AVAILABLE" "$intName"
    # printf "\t${normal}%s ${red}${bold}%s\n" "Installed Version:  " "$current"
    # printf "\t${normal}%s ${green}${bold}%s\n" "Available Version:  " "$latest"

    updateAvailable=( "${updateAvailable[@]}" "$intName" )

  elif [[ $latest = '' ]]
  then
    # printf "${normal}${bold}%s %s\n" "$intName" "HAS NO DATA!"

    noData=( "${noData[@]}" "$intName" )

  else
    # printf "${normal}${bold}%s ${normal}%s\n" "$intName" "is up to date"

    upToDate=( "${upToDate[@]}" "$intName" )

  fi

done

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
  printf "\n${bold}${italic}%s\n" "NO DATA:"
  for i in "${noData[@]}"
  do
    echo $i
  done
fi

printf "${normal}"

echo
