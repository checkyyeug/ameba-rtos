#
# Copyright (c) 2016, ARM Limited and Contributors. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#

# OS specific definitions for builds in a Mingw32 MSYS environment.
# Mingw32 allows us to use some unix style commands on a windows platform.

ifndef MSYS_MK
    MSYS_MK := $(lastword $(MAKEFILE_LIST))

    # Use windows.mk when make is invoked via cmd.exe (ninja), not bash
    # unix.mk uses "mkdir -p" which fails in cmd.exe
    ifdef OS
        ifneq ($(findstring ${OS}, Windows_NT),)
            include ${MAKE_HELPERS_DIRECTORY}windows.mk
        else
            include ${MAKE_HELPERS_DIRECTORY}unix.mk
        endif
    else
        include ${MAKE_HELPERS_DIRECTORY}unix.mk
    endif

    # In MSYS executable files have the Windows .exe extension type.
    BIN_EXT := .exe

endif

