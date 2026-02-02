#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

source ../helpers/env.sh
source "$XILINX_VIVADO_ROOT/settings64.sh"
git submodule init adi-hdl
git submodule update adi-hdl
cd ./adi-hdl/
git reset --hard
git fetch
git checkout main
git reset --hard main
cd library/
make