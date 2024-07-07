# This file should be source-d

ECONF_CONFIG_DIR=${ECONF_CONFIG_DIR:=$HOME/.econf}
export ECONF_CONFIG_DIR

if ! mkdir -p $ECONF_CONFIG_DIR; then
  echo "econf: fatal error occured during initialization"
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
  echo "  econf --cp -e <src-name> <dst-name>     # copy and edit config"
  echo "  econf --rm <config-name>                # remove config"
  echo "  econf --realpath <config-name>          # get full path to config"
  echo
  echo "Helper commands:"
  echo "  econf --bins                            # show contents of \$PATH"
  echo "  econf --libs                            # show contents of \$LD_LIBRARY_PATH"
  echo
  echo "API commands:"
  echo "  econf --prepend-bin-dir <directory>     # prepend path to \$PATH"
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

__econf_list_configs() {
  local cfg header configs
  if [ "$#" = 1 ]; then
    configs=$(find $ECONF_CONFIG_DIR -type f)
  else
    configs=$(find $ECONF_CONFIG_DIR/$2 -type f)
  fi
  for cfg in $configs; do
    header=$(head -1 $cfg)
    cfg=$(echo "$cfg" | sed "s|^$ECONF_CONFIG_DIR/||") 
    if [ "$1" == "--list" ] && echo $header | grep -qP "^# INFO: "; then
      header=$(echo "$header" | sed 's|^# INFO: ||')
      printf "%-40s -- %s\n" "$cfg" "$header"
    else
      echo $cfg
    fi
  done
}

econf() {
  if [ "$#" = 0 -o "$1" = "-h" -o "$1" = "--help" ]; then 
    __econf_help
  elif [ "$1" = "-l" -o "$1" = "--ls" -o "$1" = "--list" ]; then
    __econf_list_configs "$@"
  elif [ "$1" = "-lp" -o "$1" = "--lp" ]; then
    econf -l profile
  elif [ "$1" = "-e" -o "$1" = "--edit" ]; then
    __econf_expect_one_arg "$@" || return
    mkdir -p $(dirname -- "$ECONF_CONFIG_DIR/$2")
    $EDITOR $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "--rm" ]; then
    __econf_expect_one_arg "$@" || return
    rm $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "-c" -o "$1" = "--cat" ]; then
    __econf_expect_one_arg "$@" || return
    cat $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "--realpath" ]; then
    __econf_expect_one_arg "$@" || return
    mkdir -p $(dirname -- "$ECONF_CONFIG_DIR/$2")
    realpath $ECONF_CONFIG_DIR/$2
  elif [ "$1" = "--bins" ]; then
    __econf_expect_zero_args "$@" || return
    echo $PATH | tr ':' '\n'
  elif [ "$1" = "--libs" ]; then
    __econf_expect_zero_args "$@" || return
    echo $LD_LIBRARY_PATH | tr ':' '\n'
  elif [ "$1" = "--prepend-bin-dir" ]; then
    __econf_expect_one_arg "$@" || return
    export PATH="$2:$PATH"
  elif [ "$1" = "--append-bin-dir" ]; then
    __econf_expect_one_arg "$@" || return
    export PATH="$PATH:$2"
  elif [ "$1" = "-p" ]; then
    __econf_expect_one_arg "$@" || return
    source $ECONF_CONFIG_DIR/profile/$2
  elif [ "${1:0:1}" = "-" ]; then
    echo "econf: unknown command '$1'"
    echo "econf: try 'econf --help'"
    return 1
  elif ! [ -f "$ECONF_CONFIG_DIR/$1" ]; then
    echo "econf: no such config '$1'"
    echo "econf: run 'econf --ls' to get list of available configs"
    return 1
  else
    source $ECONF_CONFIG_DIR/$1
  fi
}
