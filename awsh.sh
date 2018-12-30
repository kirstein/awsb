#!/usr/bin/env bash

cfg_parser ()
{
  IFS=$'\n' && ini=( $(<$1) ) # convert to line-array
  ini=( ${ini[*]//;*/} )      # remove comments ;
  ini=( ${ini[*]//\#*/} )     # remove comments #
  ini=( ${ini[*]/\	=/=} )  # remove tabs before =
  ini=( ${ini[*]/=\	/=} )   # remove tabs be =
  ini=( ${ini[*]/\ *=\ /=} )   # remove anything with a space around  =
  ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
  ini=( ${ini[*]/%]/ \(} )    # convert text2function (1)
  ini=( ${ini[*]/=/=\( } )    # convert item to array
  ini=( ${ini[*]/%/ \)} )     # close array parenthesis
  ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
  ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
  ini=( ${ini[*]/%\} \)/\}} ) # remove extra parenthesis
  ini[0]="" # remove first element
  ini[${#ini[*]} + 1]='}'    # add the last brace
  eval "$(echo "${ini[*]}")" # eval the result
}

CREDENTIALS=${CREDENTIALS:-~/.aws/credentials}
PROFILE=${PROFILE:-default}

for i in "$@"
do
case $i in
    --credentials=*)
    CREDENTIALS="${i#*=}"
    shift
    ;;
    --c=*)
    CREDENTIALS="${i#*=}"
    shift
    ;;
    --profile=*)
    PROFILE="${i#*=}"
    shift
    ;;
    --p=*)
    PROFILE="${i#*=}"
    shift
    ;;
    *)
    # unknown option
    echo "Unknown option $1"
    exit 1
    ;;
esac
done

cfg_parser "${CREDENTIALS}"
if [[ $? -ne 0 ]]; then
  echo "Parsing credentials file '${CREDENTIALS}' failed"
  exit 4
fi

cfg.section."$PROFILE"
if [[ $? -ne 0 ]]; then
  echo "Profile '${PROFILE}' not found"
  exit 5
fi

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_SESSION_TOKEN=${aws_session_token}
export PS1="AWSCLI (profile: $PROFILE) » "

exec sh

