#!/bin/bash

ROOTDIR=$(realpath $(dirname $BASH_SOURCE))
CMD="source $ROOTDIR/econf.sh"

if grep -q "^$CMD" ~/.bashrc; then
  echo "install.sh: econf is already installed to your ~/.bashrc"
else
  echo "$CMD" >> ~/.bashrc
  echo "install.sh: added econf.sh to ~/.bashrc"
fi

echo "install.sh: sourcing econf.sh..."
$CMD && echo "install.sh: OK!"
