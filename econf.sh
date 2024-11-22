# This file should be source-d

ECONF_CONFIG_DIR=${ECONF_CONFIG_DIR:=$HOME/.econf}
export ECONF_CONFIG_DIR

if ! mkdir -p $ECONF_CONFIG_DIR; then
  echo "econf: failed to create config directory '$ECONF_CONFIG_DIR'"
  return 1;
fi

__econf_help() {
  echo "econf: environment configuration tool"
  echo
  echo "Usage:"
  echo "  econf <config-name>                     # apply config"
  echo "  econf <command> <command-options...>    # manage configs"
  echo
  echo "Basic commands:"
  echo "  econf -l|--ls|--list                    # list available configs"
  echo "  econf -e|--edit <config-name>           # open config in editor"
  echo "  econf -c|--cat <config-name>            # print contents of config"
  echo
  echo "Rename/Copy/Remove commands:"
  echo "  econf --mv <src-name> <dst-name>        # rename config"
  echo "  econf --cp <src-name> <dst-name>        # copy config"
  echo "  econf --cpe <src-name> <dst-name>       # copy and edit config"
  echo "  econf --rm|--remove <config-name>       # remove config"
  echo "  econf --realpath <config-name>          # get path to config file"
  echo
  echo "Helper commands:"
  echo "  econf -b|-lb|--bins                     # show contents of \$PATH"
  echo "  econf -ll|--libs                        # show contents of \$LD_LIBRARY_PATH"
  echo "  econf --loadenv <env-file>              # load environment printed by 'env' tool"
  echo
  echo "API commands:"
  echo "  econf -pb|--pp|--ppath|--prepend-bin-dir <directory>"
  echo "                                          # prepend path to \$PATH"
  echo "  econf -pl|--prepend-lib-dir <directory> # prepend library to \$LD_LIBRARY_PATH"
  echo "  econf --append-bin-dir <directory>      # append path to \$PATH"
  echo
  echo "User configs directory: $ECONF_CONFIG_DIR"
}

__econf_expect_zero_args() {
  if [ "$#" -gt 1 ]; then
    echo "econf $1: too many arguments specified, zero expected"
    return 1
  fi
}

__econf_expect_one_arg() {
  if [ "$#" -gt 2 ]; then
    echo "econf $1: too many arguments specified, only one expected"
    return 1
  fi
  if [ "$#" -lt 2 ]; then
    echo "econf $1: expected 1 argument, got 0"
    return 1
  fi
}

__econf_expect_two_args() {
  if [ "$#" -gt 3 ]; then
    echo "econf $1: too many arguments specified, two expected"
    return 1
  fi
  if [ "$#" -lt 3 ]; then
    echo "econf $1: expected 2 arguments, got $(expr $# - 1)"
    return 1
  fi
}

__econf_loadenv() {
  # bruh...
  local script="
    (\$k, \$v) = /^([^=]+)=(.*)\$/;
    \$v =~ s/'/'\\\\''/g;
    print \"export \$k='\$v'\n\"
  "
  eval "$(perl -ne "$script" < $2)"
  cd $PWD
}

__econf_list_configs() {
  # if [ "$1" == "-l" ]; then
  #   ls "$ECONF_CONFIG_DIR"
  #   return
  # fi
  local cfg header configs
  if [ "$#" = 1 ]; then
    configs=$(ls $ECONF_CONFIG_DIR)
  else
    configs=$(ls $ECONF_CONFIG_DIR | grep "$2")
  fi
  for cfg in $configs; do
    header=$(head -1 $ECONF_CONFIG_DIR/$cfg)
    if [ "$1" == "--list" ] && echo $header | grep -qP "^# INFO: "; then
      header=$(echo "$header" | sed 's|^# INFO: ||')
      printf "%-40s -- %s\n" "$cfg" "$header"
    else
      echo $cfg
    fi
  done
}

__econf_config_exists() { test -f "$ECONF_CONFIG_DIR/$1"; }

econf() {
  if [ "$#" = 0 -o "$1" = "-h" -o "$1" = "--help" ]; then 
    __econf_help
  elif [ "$1" = "-l" -o "$1" = "--ls" -o "$1" = "--list" ]; then
    echo "Available configs:"
    __econf_list_configs | sed 's/^/  /'
  elif [ "$1" = "-lp" -o "$1" = "--lp" ]; then
    econf -l profile
  elif [ "$1" = "-e" -o "$1" = "--edit" ]; then
    __econf_expect_one_arg "$@" || return
    mkdir -p $(dirname -- "$ECONF_CONFIG_DIR/$2")
    $EDITOR "$ECONF_CONFIG_DIR/$2"
  elif [ "$1" = "--mv" ]; then
    __econf_expect_two_args "$@" || return
    mv "$ECONF_CONFIG_DIR/$2" "$ECONF_CONFIG_DIR/$3"
  elif [ "$1" = "--cp" ]; then
    __econf_expect_two_args "$@" || return
    cp "$ECONF_CONFIG_DIR/$2" "$ECONF_CONFIG_DIR/$3"
  elif [ "$1" = "--cpe" ]; then
    __econf_expect_two_args "$@" || return
    cp "$ECONF_CONFIG_DIR/$2" "$ECONF_CONFIG_DIR/$3"
    $EDITOR "$ECONF_CONFIG_DIR/$3"
  elif [ "$1" = "--rm" -o "$1" = "--remove" ]; then
    __econf_expect_one_arg "$@" || return
    if ! __econf_config_exists "$2"; then
      echo "econf $1: no such config '$2'"
      return 1
    fi
    rm "$ECONF_CONFIG_DIR/$2"
  elif [ "$1" = "-c" -o "$1" = "--cat" ]; then
    __econf_expect_one_arg "$@" || return
    cat $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "--realpath" ]; then
    __econf_expect_one_arg "$@" || return
    mkdir -p $(dirname -- "$ECONF_CONFIG_DIR/$2")
    realpath $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "-b" -o "$1" = "-lb" -o "$1" = "--bins" ]; then
    __econf_expect_zero_args "$@" || return
    echo $PATH | tr ':' '\n'
  elif [ "$1" = "-ll" -o "$1" = "--libs" ]; then
    __econf_expect_zero_args "$@" || return
    echo $LD_LIBRARY_PATH | tr ':' '\n'
  elif [ "$1" = "-pb" -o "$1" = "--pp" -o "$1" = "--ppath" -o $1 = "--prepend-bin-dir" ]; then
    __econf_expect_one_arg "$@" || return
    if ! [ -e "$2" ]; then
      echo "econf $1: error: directory '$2' does not exists"; return 1
    fi
    if ! [ -d "$2" ]; then
      echo "econf $1: error: '$2' is not a directory"; return 1
    fi
    export PATH="$(realpath $2):$PATH"
  elif [ "$1" = "-pl" -o "$1" = "--prepend-lib-dir" ]; then
    __econf_expect_one_arg "$@" || return
    if ! [ -e "$2" ]; then
      echo "econf $1: error: directory '$2' does not exists"; return 1
    fi
    if ! [ -d "$2" ]; then
      echo "econf $1: error: '$2' is not a directory"; return 1
    fi
    export LD_LIBRARY_PATH="$(realpath $2):$LD_LIBRARY_PATH"
  elif [ "$1" = "--append-bin-dir" ]; then
    __econf_expect_one_arg "$@" || return
    export PATH="$PATH:$2"
  elif [ "$1" = "-p" ]; then
    __econf_expect_one_arg "$@" || return
    source $ECONF_CONFIG_DIR/profile/$2
  elif [ "$1" = "--loadenv" ]; then
    __econf_expect_one_arg "$@" || return
    __econf_loadenv "$@"
  elif [ "${1:0:1}" = "-" ]; then
    echo "econf: unknown command '$1'"
    echo "econf: try 'econf --help'"
    return 1
  elif ! [ -f "$ECONF_CONFIG_DIR/$1" ]; then
    echo "econf: no such config '$1'"
    echo
    echo "Available configs:"
    __econf_list_configs | sed 's/^/  /'
  else
    source $ECONF_CONFIG_DIR/$1
  fi
}
