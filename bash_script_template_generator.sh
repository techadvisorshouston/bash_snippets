#!/bin/bash
# ---------------------------------------------------------------------------
# new_script - Bash shell script template generator

# Copyright 2012-2020, William Shotts <bshotts@users.sourceforge.net>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Usage: new_script [-h|--help]
#        new_script [-q|--quiet] [-s|--root] [script]

# Revision history:
# 2020-05-07  Various cosmetic cleanups (3.5.2)
# 2020-05-04  Improved help message formatting (3.5.1)
# 2020-04-02  Updated to new coding standard (3.5)
# 2019-05-09  Added support for shell scripting libraries (3.4)
# 2015-09-14  Minor cleanups suggested by Shellcheck (3.3)
# 2014-01-21  Minor formatting corrections (3.2)
# 2014-01-12  Various cleanups (3.1)
# 2012-05-14  Created
# ---------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="3.5.2"
SCRIPT_SHELL="/usr/bin/env bash"

# Make some pretty date strings
DATE=$(date +'%Y-%m-%d')
YEAR=$(date +'%Y')

# Get user's real name from passwd file
AUTHOR=$(awk -v USER="$USER" \
  'BEGIN { FS = ":" } $1 == USER { print $5 }' < /etc/passwd)
AUTHOR=${AUTHOR%%,,,} # Remove trailing commas on Ubuntu

# Construct the user's email address from the hostname or the REPLYTO
# environment variable, if defined
EMAIL_ADDRESS="<${REPLYTO:-${USER}@$HOSTNAME}>"

# Arrays for command-line options and option arguments
declare -a opt opt_desc opt_long opt_arg opt_arg_desc


clean_up() { # Perform pre-exit housekeeping
  return
}

error_exit() {

  local error_message="$1"

  printf "%s: %s\n" \
    "${PROGNAME}" "${error_message:-"Unknown Error"}" >&2
  clean_up
  exit 1
}

graceful_exit() {
  clean_up
  exit
}

signal_exit() { # Handle trapped signals

  local signal="$1"

  case "$signal" in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      printf "\n%s\n" "$PROGNAME: Program terminated" >&2
      graceful_exit ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal" ;;
  esac
}

usage() {
  printf "%s\n%s\n" \
    "Usage: ${PROGNAME} [-h|--help ]" \
    "       ${PROGNAME} [-q|--quiet] [-s|--root] [script]"
}

help_message() {
  cat <<- _EOF_
${PROGNAME} ${VERSION}
Bash shell script template generator.
$(usage)
  Options:
  -h, --help    Display this help message and exit.
  -q, --quiet   Quiet mode. No prompting. Outputs default script.
  -s, --root    Output script requires root privileges to run.
_EOF_
}

insert_license() {

  if [[ -z "$script_license" ]]; then
    echo "# All rights reserved."
  else
    cat <<- _EOF_

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.
_EOF_
  fi
}

insert_help_message() {

  local arg i long

  printf "help_message() {\n"
  printf "  cat <<- _EOF_\n"
  printf "\$PROGNAME ver. \$VERSION\n"
  printf "%s\n\n" "$script_purpose"
  printf "\$(usage)\n"
  printf "\n  Options:\n"
  i=0
  while [[ -n "${opt[i]}" ]]; do
    long=
    arg=
    [[ -n "${opt_long[i]}" ]] && long=", --${opt_long[i]}"
    [[ -n "${opt_arg[i]}" ]] && arg=" ${opt_arg[i]}"
    printf "%-30s%s\n" \
      "  -${opt[i]}$long$arg"  "${opt_desc[i]^}"
    [[ -n "${opt_arg[i]}" ]] && printf "%s\n" \
      "    Where '${opt_arg[i]}' is the ${opt_arg_desc[i],}."
    ((++i))
  done
  [[ -n "$root_mode" ]] && \
    printf "\n  NOTE: You must be the superuser to run this script.\n"
  printf "\n_EOF_\n"
  printf "  return\n}\n"
}

insert_root_check() {

  if [[ -n "$root_mode" ]]; then
    printf "# Check for root UID\n"
    printf "if [[ \$(id -u) != 0 ]]; then\n"
    printf "  error_exit \"You must be the superuser to run this script.\"\n"
    printf "fi\n"
  fi
}

insert_parser() {

  local i

  printf "while [[ -n \"\$1\" ]]; do\n  case \"\$1\" in\n"
  printf "    -h | --help)\n"
  printf "      help_message\n"
  printf "      graceful_exit\n"
  printf "      ;;\n"
  for (( i = 1; i < ${#opt[@]}; i++ )); do
    printf "%s" "    -${opt[i]}"
    if [[ -n ${opt_long[i]} ]]; then
      printf " | --%s" "${opt_long[i]}"
    fi
    printf ")\n"
    printf "      echo \"%s\"\n" "${opt_desc[i]}"
    if [[ -n ${opt_arg[i]} ]]; then
      printf "      shift; %s=\"\$1\"\n" "${opt_arg[i]}"
      printf "      echo \"%s == \$%s\"\n" "${opt_arg[i]}" "${opt_arg[i]}"
    fi
    printf "      ;;\n"
  done
  printf "    -* | --*)\n      usage >&2\n"
  printf "      error_exit \"Unknown option \$1\"\n      ;;\n"
  printf "    *)\n      printf \"Processing argument %%s...\\\n\" \"\$1\"\n      ;;\n"
  printf "  esac\n  shift\ndone\n"
}

write_script() {

#############################################################################
# START SCRIPT TEMPLATE
#############################################################################
cat << _EOF_
#!$SCRIPT_SHELL
# ---------------------------------------------------------------------------
# $script_name - $script_purpose
# Copyright $YEAR, $AUTHOR $EMAIL_ADDRESS
$(insert_license)
# Usage: $script_name [-h|--help]
#        ${usage_message:+"$script_name$usage_message"}
# Revision history:
# $DATE Created by $PROGNAME ver. $VERSION
# ---------------------------------------------------------------------------
PROGNAME=\${0##*/}
VERSION="0.1"
LIBS=     # Insert pathnames of any required external shell libraries here
clean_up() { # Perform pre-exit housekeeping
  return
}
error_exit() {
  local error_message="\$1"
  printf "%s: %s\n" "\${PROGNAME}" "\${error_message:-"Unknown Error"}" >&2
  clean_up
  exit 1
}
graceful_exit() {
  clean_up
  exit
}
signal_exit() { # Handle trapped signals
  local signal="\$1"
  case "\$signal" in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      error_exit "Program terminated" ;;
    *)
      error_exit "Terminating on unknown signal" ;;
  esac
}
load_libraries() { # Load external shell libraries
  local i
  for i in \$LIBS; do
    if [[ -r "\$i" ]]; then
      source "\$i" || error_exit "Library '\$i' contains errors."
    else
      error_exit "Required library '\$i' not found."
    fi
  done
}
usage() {
  printf "%s\n" "Usage: \${PROGNAME} [-h|--help]"
  printf "%s\n" "${usage_message:+"       \${PROGNAME}$usage_message"}"
}
$(insert_help_message)
# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT
$(insert_root_check)
load_libraries
# Parse command-line
$(insert_parser)
# Main logic
graceful_exit
_EOF_
#############################################################################
# END SCRIPT TEMPLATE
#############################################################################

}

check_filename() {

  local filename=$1
  local pathname=${filename%/*} # Equals filename if no path specified

  if [[ "$pathname" != "$filename" ]]; then
    if [[ ! -d $pathname ]]; then
      [[ -n "$quiet_mode" ]] || printf "Directory %s does not exist.\n" "$pathname"
      return 1
    fi
  fi
  if [[ -n "$filename" ]]; then
    if [[ -e "$filename" ]]; then
      if [[ -f "$filename" && -w "$filename" ]]; then
        [[ -n "$quiet_mode" ]] && return 0
        read -rp "  File '$filename' exists. Overwrite [y/n] > "
        [[ $REPLY =~ ^[yY]$ ]] || return 1
      else
        return 1
      fi
    fi
  else
    [[ -n "$quiet_mode" ]] && return 0 # Empty filename OK in quiet mode
    return 1
  fi
}

read_option() {

  local -i opt_count="$1"
  local -i i=$((opt_count + 1))

  printf "\n%s\n"  "Option $i:"
  read -rp "  Enter short option name [a-z] (Enter to end) -> "
  [[ -n $REPLY ]] || return 1 # prevent array element if REPLY is empty
  opt[i]=$REPLY
  read -rp "  Description of option ------------------------> " opt_desc[i]
  read -rp "  Enter long option name (optional) ------------> " opt_long[i]
  if [[ -n "${opt_long[i]}" ]]; then
    # Long option names and argument names must be valid variable names
    # As embedded spaces are the common error, we try to fix those
    opt_long[i]="${opt_long[i]// /_}"
    # if option name is still invalid, punt and create alternate default name
    [[ "${opt_long[i]}" =~ ^[_[:alpha:]][_[:alnum:]]*$ ]] || opt_long[i]="option_$i"
  fi
  read -rp "  Enter option argument (if any) ---------------> " opt_arg[i]
  if [[ -n "${opt_arg[i]}" ]]; then
    opt_arg[i]="${opt_arg[i]// /_}"
    [[ "${opt_arg[i]}" =~ ^[_[:alpha:]][_[:alnum:]]*$ ]] || opt_arg[i]="arg_$i"
  fi
  [[ -n ${opt_arg[i]} ]] && \
    read -rp "  Description of argument (if any)--------------> " opt_arg_desc[i]
  return 0 # force 0 return status regardless of test outcome above
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Parse command-line
quiet_mode=
root_mode=
script_license=
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      help_message; graceful_exit
      ;;
    -q | --quiet)
      quiet_mode=yes
      ;;
    -s | --root)
      root_mode=yes
      ;;
    -* | --*)
      usage >&2
      error_exit "Unknown option $1"
      ;;
    *)
      tmp_script=$1; break
      ;;
  esac
  shift
done

# Main logic

if [[ -n "$quiet_mode" ]]; then
  script_filename="$tmp_script"
  check_filename "$script_filename" || \
    error_exit "$script_filename is not writable."
  script_purpose="[Enter purpose of script here.]"
else
  cat << _EOF_
  ------------------------------------------------------------------------
  ** Welcome to $PROGNAME version $VERSION **
  ------------------------------------------------------------------------
_EOF_
  # Get script filename
  script_filename=
  while [[ -z $script_filename ]]; do
    if [[ -n $tmp_script ]]; then
      script_filename="$tmp_script"
      tmp_script=
    else
      read -rp "  Enter filename for output script > " script_filename
    fi
    if ! check_filename "$script_filename"; then
      printf "%s\n"  "$script_filename is not writable."
      printf "%s\n\n" "Please choose another name."
      script_filename=
    fi
  done

  # Purpose
  cat << _EOF_
  ------------------------------------------------------------------------
  ** Comment Block **
  The purpose is a one line description of what the script does.
  ------------------------------------------------------------------------
_EOF_
  read -rp "  The purpose of the script is to: > " script_purpose
  script_purpose="${script_purpose^}"

  # License
  cat << _EOF_
  ------------------------------------------------------------------------
  The script may be licensed in one of two ways:
  1. All rights reserved (default) or
  2. GNU GPL version 3 (preferred).
  ------------------------------------------------------------------------
_EOF_

  read -rp "  Include GPL license header [y/n]? > "
  [[ $REPLY =~ ^[yY]$ ]] && script_license="GPL"

  # Requires superuser?
  cat << _EOF_
  ------------------------------------------------------------------------
  ** Privileges **
  The template may optionally include code that will prevent it from
  running if the user does not have superuser (root) privileges.
  ------------------------------------------------------------------------
_EOF_
  read -rp "  Does this script require superuser privileges [y/n]? > "
  [[ $REPLY =~ ^[yY]$ ]] && root_mode="yes"

  # Command-line options
  cat << _EOF_
  ------------------------------------------------------------------------
  ** Command Line Options **
  The generated template supports both short name (1 character), and long
  name (1 word) options. All options must have a short name. Long names
  are optional. The options 'h' and 'help' are provided automatically.
  Further, each option may have a single argument. Argument names must
  be valid variable names.
  Descriptions for options and option arguments should be short (less
  than 1 line) and will appear in the template's comment block and
  help_message function.
  ------------------------------------------------------------------------
_EOF_
  option_count=0
  read -rp "  Does this script support command-line options [y/n]? > "
  [[ $REPLY =~ ^[yY]$ ]] \
    && while read_option "$option_count"; do ((++option_count)); done
fi

script_name=${script_filename##*/} # Strip path from filename
script_name=${script_name:-"[Untitled Script]"} # Set default if enmpty

# "help" option included by default
opt[0]="h"
opt_long[0]="help"
opt_desc[0]="Display this help message and exit."

# Create usage message
usage_message=''
i=1
while [[ -n "${opt[i]}" ]]; do
  arg="]"
  [[ -n "${opt_arg[i]}" ]] && arg=" ${opt_arg[i]}]"
  usage_message="$usage_message [-${opt[i]}"
  [[ -n "${opt_long[i]}" ]] \
    && usage_message="$usage_message|--${opt_long[i]}"
  usage_message="$usage_message$arg"
  ((++i))
done

# Generate script
if [[ -n "$script_filename" ]]; then # Write script to file
  write_script > "$script_filename"
  chmod +x "$script_filename"
else
  write_script # Write script to stdout
fi
graceful_exit