#!/bin/zsh

function gcmt() {
  find_type() {
    for reference in "${@:3}"; do
      unset shortcut
      unset type
      IFS=$1 read shortcut type <<<$reference

      if [[ "$shortcut" = "$2" ]]
        then
          echo "$type"
      fi
    done
  }

  get_ticket() {
    if [[ $2 =~ $1 ]]; then
      echo $match[1]
    fi
  }

  print_missing_message() {
    printf "\e[31mMissing commit message\e[0m\n"
  }

  print_invalid_type_shortcut() {
    printf "\e[31mUnsupported type shortcut: $1\e[0m\n"
  }

  print_unknown_ticket() {
    printf "\e[31mCan't extract ticket from $1 branch\e[0m\n"
  }

  print_shortcuts() {
    printf "The following type shortcuts are available:\n"
    for reference in "${@:2}"; do
      unset shortcut
      unset type
      IFS=$1 read shortcut type <<<$reference
      printf " * \e[32m$shortcut\e[0m: $type\n";
    done
  }

  print_examples() {
    printf "\e[4mUsage examples\e[0m:\n"
    for example in "${@:2}"; do
      printf " * \e[1;32m$1  \"\e[0m\e[32m$example\e[0m\e[1;32m\"\e[0m\n";
    done
  }

  COMMAND=$0

  BRANCH=$(gb "--show-current")
  BRANCH_TYPE_SEPARATOR="/"
  RE_BRANCH_TICKET="(^[A-Z]+\-[0-9]+)"
  IFS=$BRANCH_TYPE_SEPARATOR read BRANCH_TYPE BRANCH_REFERENCE <<<$BRANCH

  MESSAGE=$1
  MESSAGE_TYPE_SEPARATOR=": "
  RE_MESSAGE_TYPE="^[a-z]:"
  IFS=$MESSAGE_TYPE_SEPARATOR read MESSAGE_TYPE MESSAGE_TEXT <<<$MESSAGE

  TYPES=(
    "f/feat"
    "b/fix"
    "r/refactor"
    "s/style"
    "d/docs"
    "t/test"
    "c/chore"
  )

  EXAMPLES=(
    "Adds receiver name validation"
    "r: Abstracts account type for clarity"
    "t: #getOwnAccount()"
  )

  TICKET=$(get_ticket $RE_BRANCH_TICKET $BRANCH_REFERENCE)

  if [ ! -n "$MESSAGE" ]; then
    print_missing_message
    $COMMAND "--help"

  elif [[ $MESSAGE == "--help" ]]; then
    echo -e "\n- - - - - - - - - - -"
    print_examples $COMMAND ${EXAMPLES[@]}
    printf "\n"
    print_shortcuts $BRANCH_TYPE_SEPARATOR ${TYPES[@]}

  elif [ ! -n "$TICKET" ]; then
    print_unknown_ticket $BRANCH_REFERENCE

  elif [[ $MESSAGE =~ $RE_MESSAGE_TYPE ]]; then
    TARGET_TYPE=$(find_type $BRANCH_TYPE_SEPARATOR $MESSAGE_TYPE ${TYPES[@]})

    if [ -n "${TARGET_TYPE}" ]; then
      git commit -m "$TARGET_TYPE: $TICKET $MESSAGE_TEXT" ${@:2}
    else
      print_invalid_type_shortcut $MESSAGE_TYPE
      $COMMAND "--help"
    fi

  else
    git commit -m "$BRANCH_TYPE: $TICKET $MESSAGE" ${@:2}
  fi
}
