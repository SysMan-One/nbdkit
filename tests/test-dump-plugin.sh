#!/usr/bin/env bash
# nbdkit
# Copyright (C) 2014 Red Hat Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# * Neither the name of Red Hat nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY RED HAT AND CONTRIBUTORS ''AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL RED HAT OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

set -e
set -x
source ./functions.sh

# Basic check that the name field is present.
output="$(nbdkit example1 --dump-plugin)"
if [[ ! ( "$output" =~ name\=example1 ) ]]; then
    echo "$0: unexpected output from nbdkit example1 --dump-plugin"
    echo "$output"
    exit 1
fi

# example2 overrides the --dump-plugin with extra data.
output="$(nbdkit example2 --dump-plugin)"
if [[ ! ( "$output" =~ example2_extra\=hello ) ]]; then
    echo "$0: unexpected output from nbdkit example2 --dump-plugin"
    echo "$output"
    exit 1
fi

# Get a list of all plugins and run --dump-plugin on all of them.
# However some of these tests are expected to fail.
plugins="$(
    cd ..;
    ls -1 plugins/*/.libs/nbdkit-*-plugin.so plugins/*/nbdkit-*-plugin |
        sed 's,^plugins/\([^/]*\)/.*,\1,'
)"
for p in $plugins; do
    case "$p${NBDKIT_VALGRIND:+-valgrind}" in
        vddk | vddk-valgrind)
            # VDDK won't run without special environment variables
            # being set, so ignore it.
            ;;
        lua-valgrind | perl-valgrind | python-valgrind | \
        ruby-valgrind | tcl-valgrind | \
        example4-valgrind | tar-valgrind)
            # Plugins written in scripting languages can't run under valgrind.
            ;;
        *)
            nbdkit $p --dump-plugin
            ;;
    esac
done
