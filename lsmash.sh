#!/bin/sh

about() {
#
#   Script Name: lsmash.sh
#
#   Copyright (C) 2017 Chatra
#   base script is
#     Copyright (C) 2015 Yayoi
#       Website: http://mylabo.webcrow.jp/downloads.php
#
#   This script will build L-SMASH for Win32 and Win64 on MinGW/MSYS.
#
#   This script is free, and is released under the MIT License.
#   The MIT License can be found at the end of this file.
#
#
cat <<_EOF_

Usage: sh $0 [options]

Available options:
  -h, --help              Show this help
  -j, --threads <int>     Set number of jobs(1 to $((NUMBER_OF_PROCESSORS + 1))) [${JOBS}]
  -t, --target <int>      Set target of build [${BUILD_TARGET}]
                             - 0: build x86
                             - 1: build x64
  -u, --uninstall         Run uninstall mode only [none]
_EOF_
}
##=================================
##    L-SMASH
##=================================
## URL
readonly LSMASH_SRC_URL=https://github.com/l-smash/l-smash.git

## settings  
BUILD_TARGET="x86"      # x86   x64
JOBS=2
JOBS=`expr ${NUMBER_OF_PROCESSORS} - 1` # number of threads




## Locations
readonly TMP=/home
readonly PREF32=/usr/local/x86
readonly PREF64=/usr/local/x86_64
readonly LSMASH_DIR=${TMP}/lsmash
## Variables
readonly CFLAG="-s -O3 -pipe -mtune=native -ffast-math -fexcess-precision=fast -fno-tree-vectorize"
readonly HOST32=i686-w64-mingw32
readonly HOST64=x86_64-w64-mingw32


parse_opts() {
for OPT in "$@"
do
case "$OPT" in
    '-j'|'--job')
            if [ -z "$2" ] || [[ "$2" =~ ^-+ ]]; then
                func_error "'$1' requires an argument."
            fi
            expr "$2" + 1 >/dev/null 2>&1
            if [ $? -lt 2 ]; then
                JOBS="$2"
            else
                func_error "Illegal argument: $1 $2"
            fi
            shift 2 ;;
    '-t'|'--target')
            if [ -z "$2" ] || [[ "$2" =~ ^-+ ]]; then
                func_error "'$1' requires an argument."
            fi
            case "$2" in
                0|'x86') BUILD_TARGET="x86" ;;
                1|'x64') BUILD_TARGET="x64" ;;
                *) func_error "Unknown argument: $1 $2" ;;
            esac
            shift 2 ;;
    '-u'|'--uninstall')
            uninstall ; exit 0 ;;
    '-h'|'-help'|'--help')
            about ; exit 0 ;;
    '-'|'--')
            shift 1 ;;
          -*)
            func_error "Unknown option: $1" ;;
           *)
            if [ ! -z "$1" ] && [[ ! "$1" =~ ^-+ ]]; then
                func_error "Unknown option: $1"
                shift 1
            fi ;;
esac
done
echo
}


## uninstall 
uninstall() {
	echo
	set -u
	for file in include/lsmash.h \
				lib/liblsmash.*a \
				lib/pkgconfig/liblsmash.pc
	do
		echo "Remove ${file}(x86)"
		rm -r ${PREF32}/${file}
		echo "Remove ${file}(x64)"
		rm -r ${PREF64}/${file}
	done
	func_echo "--> Completed"
	set +u
	func_delete ${LSMASH_DIR}
}


download() {
    git config --global core.autocrlf input
    func_delete ${LSMASH_DIR}
    func_download ${LSMASH_SRC_URL} ${LSMASH_DIR}
}

build() {
    local target=$1
    if [ x"${target}" = x"${HOST32}" ]; then
        local pref=${PREF32}
        local cross=
        local cflag="${CFLAG}"
        local arch=x86
    else
        local pref=${PREF64}
        local cross="${HOST64}-"
        local cflag="${CFLAG}"
        local arch=x86_64
    fi
    local conf_static=""
    local conf_shared=""
    cd ${LSMASH_DIR}
    func_echo "Start building ( L-SMASH[${arch}])..."
    PKG_CONFIG_PATH=${pref}/lib/pkgconfig \
    ./configure \
        --prefix=${pref} \
        --cross-prefix=${cross} \
        ${conf_static} \
        ${conf_shared} \
        --extra-cflags="${cflag}"
    make clean && make -j ${JOBS} && make install || func_error "Failed to make. (L-SMASH[${arch}])"
    func_check_dir ${pref}/bin/L-SMASH
    mv ${pref}/bin/boxdumper.exe      ${pref}/bin/L-SMASH/boxdumper.exe
    mv ${pref}/bin/muxer.exe          ${pref}/bin/L-SMASH/muxer.exe
    mv ${pref}/bin/remuxer.exe        ${pref}/bin/L-SMASH/remuxer.exe
    mv ${pref}/bin/timelineeditor.exe ${pref}/bin/L-SMASH/timelineeditor.exe
    echo
}

##=================================
##    main
##=================================
## Prepare
source ./common.func
START_TIME=`func_settime`
parse_opts $@
func_check_dir ${TMP} ${SRC} ${PREF32} ${PREF64}

download

## Build
if [ x"${BUILD_TARGET}" = x"x86" ]; then
    build ${HOST32}
else
    build ${HOST64}
fi


## End
END_TIME=`func_settime`
cd ~
echo
echo "Total elapsed time: `func_gettime ${START_TIME} ${END_TIME}`"
echo
func_echo "---------------------------"
func_echo "   $(basename $0) finished."
func_echo "---------------------------"



#
# The MIT License (MIT)
#
# Copyright (c) 2015 Yayoi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
