#!/bin/bash
set -e

CMD="source $(pwd -P)/econf.sh"
if grep -q "^$CMD" ~/.bashrc; then
  echo "install.sh: econf is already installed to your ~/.bashrc"
else
  echo "$CMD" >> ~/.bashrc
  echo "install.sh: added econf.sh to ~/.bashrc"
fi

echo "install.sh: sourcing econf.sh..."
$CMD
echo "install.sh: OK!"
