#!/bin/sh

about() {
#
#   Script Name: lsmash_works.sh
#
#   Copyright (C) 2017 Chatra
#   base script is
#     Copyright (C) 2015 Yayoi
#       Website: http://mylabo.webcrow.jp/downloads.php
#
#   This script will build L-SMASH Works on MinGW/MSYS.
#
#   This script is free, and is released under the MIT License.
#   The MIT License can be found at the end of this file.
#
#
cat <<_EOF_

Usage: sh $0 [options]

Available options:
  -h, --help              Show this help
  -j, --threads <int>     Set number of jobs(1-$((NUMBER_OF_PROCESSORS + 1))) [${JOBS}]
  -t, --target <int>      Set target of build [${BUILD_TARGET}]
                             - 0: build x86
                             - 1: build x64
_EOF_
}
##=================================
##    L-SMASH Works
##=================================
## URL
readonly LSMASH_WORKS_SRC_URL=https://github.com/VFR-maniac/L-SMASH-Works.git

## settings 
BUILD_TARGET="x86"      # x86   x64
JOBS=2
JOBS=`expr ${NUMBER_OF_PROCESSORS} - 1` # number of threads




## Locations
readonly TMP=/home
readonly PREF32=/usr/local/x86
readonly PREF64=/usr/local/x86_64
readonly LSMASH_WORKS_DIR=${TMP}/lsmash_works
## Variables
readonly CFLAG="-s -O3 -pipe -mtune=native -ffast-math -fexcess-precision=fast -fno-tree-vectorize -fno-strict-aliasing"
readonly HOST32=i686-w64-mingw32
readonly HOST64=x86_64-w64-mingw32


parse_opts() {
for OPT in "$@"
do
case "$OPT" in
    '-j'|'--threads'|'--job')
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

download() {
	git config --global core.autocrlf input
    func_delete ${LSMASH_WORKS_DIR}
    func_download ${LSMASH_WORKS_SRC_URL} ${LSMASH_WORKS_DIR}
}


check_ffmpeg_lib() {
    local pref=$1
    if [ ! -f ${pref}/lib/libavresample.a ] ; then
		func_error "not found ffmpeg library"
	fi
	if [ ! -f ${pref}/lib/liblsmash.a ]; then
		func_error "not found L-SMASH library"
	fi
 }
 

build() {
    local target_Host=$1
	local target_App=$2	
    if [ x"${target_Host}" = x"${HOST32}" ]; then
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
    if [ x"${target_App}" = x"AviUtl" ]; then
        local bld_dir=AviUtl
        local target_os=
    else
        local bld_dir=VapourSynth
        local target_os="--target-os=mingw32"
    fi
	local ldflags="--extra-ldflags=-static"
    cd ${LSMASH_WORKS_DIR}/${bld_dir}
    func_echo "Start building ( L-SMASH-Works ${bld_dir}[${arch}])..."
    PKG_CONFIG_PATH=${pref}/lib/pkgconfig \
    ./configure \
        --prefix=${pref} \
        --cross-prefix=${cross} \
        ${target_os} \
        --extra-cflags="${cflag}" \
        ${ldflags}
    make clean && make -j ${JOBS} || func_error "Failed to make. (L-SMASH-Works for ${bld_dir}[${arch}])"
    if [ x"${target_App}" = x"AviUtl" ]; then
        cp -af ./lwcolor.auc  ${pref}/bin/lwcolor.auc
        cp -af ./lwdumper.auf ${pref}/bin/lwdumper.auf
        cp -af ./lwinput.aui  ${pref}/bin/lwinput.aui
        cp -af ./lwmuxer.auf  ${pref}/bin/lwmuxer.auf
    else
        cp -af ./vslsmashsource.dll ${pref}/bin/vslsmashsource.dll
    fi
    echo
}

##=================================
##    main
##=================================
## Prepare
source ${TMP}/common.func
START_TIME=`func_settime`
parse_opts $@
func_check_dir ${TMP} ${SRC} ${PREF32} ${PREF64}

download

## Build
if [ x"${BUILD_TARGET}" = x"x86" ]; then
	check_ffmpeg_lib ${PREF32}
	# build ${HOST32} "AviUtl"    ##skip aviutl
    build ${HOST32} "VapourSynth"
else
	check_ffmpeg_lib ${PREF64}
    # build ${HOST64} "AviUtl"    ##skip aviutl
    build ${HOST64} "VapourSynth"
fi

## End
END_TIME=`func_settime`
cd ~
echo
echo "Total elapsed time: `func_gettime ${START_TIME} ${END_TIME}`"
echo
func_echo "------------------------"
func_echo "    Script finished."
func_echo "------------------------"



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
