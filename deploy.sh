#!/bin/bash -ex
###############################################################################
## Stigmee: The art to sanctuarize knowledge exchanges.
## Copyright 2021-2022 Quentin Quadrat <lecrapouille@gmail.com>
##
## This file is part of Stigmee.
##
## Stigmee is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
###
### This bash script allows to transfer Stigmee release on our server.
###
###############################################################################

if [ $# -ne 4 ] ; then
  echo "Usage: $0 url port pswd file1" >&2
  exit 1
fi

export SSHPASS="$3"
sshpass -e sftp -oBatchMode=no -oPort=$2 -b - $1 <<END_SCRIPT
pwd
put $4
quit
END_SCRIPT
