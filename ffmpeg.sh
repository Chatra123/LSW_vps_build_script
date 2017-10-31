#!/bin/sh

about() {
#
#   Script Name: ffmpeg.sh
#
#   Copyright (C) 2017 Chatra
#   base script is
#     Copyright (C) 2015 Yayoi
#       Website: http://mylabo.webcrow.jp/downloads.php
#
#   This script will build FFmpeg for Win32 and Win64 on MinGW/MSYS.
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
  -u, --uninstall         Run uninstall mode only [none]
_EOF_
}
##=================================
##    ffmpeg
##=================================
## URL
readonly FFMPEG_SRC_URL=http://ffmpeg.org/releases/ffmpeg-3.4.tar.bz2

## settings 
BUILD_TARGET="x86"      # x86   x64
JOBS=2
JOBS=`expr ${NUMBER_OF_PROCESSORS} - 1` # number of threads




## fixed setting
readonly LIB_ONLY=yes   # Do not build ffmpeg.exe
readonly LIB_TYPE=0     # 0: statically linked      1: dynamically linked
readonly SHARED=no      # build shared libraries
readonly STATIC=yes     # build static libraries
## Locations
readonly TMP=/home
readonly PREF32=/usr/local/x86
readonly PREF64=/usr/local/x86_64
readonly FFMPEG_DIR=${TMP}/ffmpeg
readonly FFMPRG_LIB_DIR=ffmpeg-lib
readonly FFMPRG_DEF_DIR=ffmpeg-def
## Variables
readonly HOST32=i686-w64-mingw32
readonly HOST64=x86_64-w64-mingw32
readonly CF32="-s -O3 -pipe -mtune=native -ffast-math -fexcess-precision=fast -fno-tree-vectorize -fno-strict-aliasing"
readonly CF64="-s -O3 -pipe -mtune=native -ffast-math -fexcess-precision=fast -fno-tree-vectorize -fno-strict-aliasing"
readonly LIST_LIB=("libmp3lame" \
                   "libopencore-amrnb" \
                   "libopencore-amrwb" \
                   "libvo-aacenc" \
                   "libvo-amrwbenc" \
                   "libfdk-aac" \
                   "libvorbis" \
                   "libtheora" \
                   "libspeex" \
                   "libvpx" \
                   "libx264" \
                   "libx265" \
                   "libxvidcore" \
                   "librtmp" \
                   "libopenjpeg" \
                   "libfreetype")
                   
                   
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

uninstall() {
	echo
	set -u
	for file in bin/ffmpeg-lib \
				include/libavcodec \
				include/libavdevice \
				include/libavfilter \
				include/libavformat \
				include/libavresample \
				include/libavutil \
				include/libpostproc \
				include/libswresample \
				include/libswscale \
				lib/ffmpeg-def \
				lib/libavcodec.*a \
				lib/libavdevice.*a \
				lib/libavfilter.*a \
				lib/libavformat.*a \
				lib/libavresample.*a \
				lib/libavutil.*a \
				lib/libpostproc.*a \
				lib/libswresample.*a \
				lib/libswscale.*a \
				lib/pkgconfig/libavcodec.pc \
				lib/pkgconfig/libavdevice.pc \
				lib/pkgconfig/libavfilter.pc \
				lib/pkgconfig/libavformat.pc \
				lib/pkgconfig/libavresample.pc \
				lib/pkgconfig/libavutil.pc \
				lib/pkgconfig/libpostproc.pc \
				lib/pkgconfig/libswresample.pc \
				lib/pkgconfig/libswscale.pc \
				share/ffmpeg
	do
		echo "Remove ${file}(x86)"
		rm -r ${PREF32}/${file}
		echo "Remove ${file}(x64)"
		rm -r ${PREF64}/${file}
	done
	func_echo "--> Completed"
	set +u
}


download() {
	git config --global core.autocrlf input
    func_delete ${FFMPEG_DIR}
    func_download ${FFMPEG_SRC_URL} ${FFMPEG_DIR}
}

build_ffmpeg() {
    local target=$1
    if [ x"${target}" = x"${HOST32}" ]; then
        local pref=${PREF32}
        local cross=
        local cpu=i686
        local cflag="${CFLAG}"
        local arch=x86
    else
        local pref=${PREF64}
        local cross="${HOST64}-"
        local cpu=x86_64
        local cflag="${CFLAG}"
        local arch=x86_64
    fi
    if [ x"${STATIC}" = x"yes" ]; then
        local conf_static="--enable-static"
    else
        local conf_static="--disable-static"
    fi
    if [ x"${SHARED}" = x"yes" ]; then
        local conf_shared="--enable-shared"
    else
        local conf_shared="--disable-shared"
    fi
    if [ x"${LIB_TYPE}" = x"0" ]; then
        local ldflags="-static"
        local pkgconfig="--pkg-config-flags=--static"
    else
        local ldflags=
        local pkgconfig=
    fi
    cd ${FFMPEG_DIR}
    func_echo "Start building ( FFmpeg[${arch}])..."
    PKG_CONFIG_PATH=${pref}/lib/pkgconfig \
    ./configure \
        --prefix=${pref} \
        --cross-prefix=${cross} \
        --cpu=${cpu} \
        --target-os=mingw32 \
        --arch=${arch} \
        --enable-gpl \
        --enable-version3 \
        --enable-avisynth \
        --enable-avresample \
        --enable-cross-compile \
        --enable-w32threads \
        --disable-debug \
        --disable-doc \
        --disable-dxva2 \
        --disable-ffplay \
        --disable-ffprobe \
        --disable-ffserver \
        --disable-pthreads \
        ${conf_static} \
        ${conf_shared} \
        ${pkgconfig} \
        --optflags="${cflag}" \
        --extra-cflags="-I${pref}/include" \
        --extra-ldflags="-L${pref}/lib ${ldflags}"      
    sleep 4s
    make clean && make -j ${JOBS} && make install || func_error "Failed to make. (FFmpeg[${arch}])"
    move_def ${pref}
    echo
}

build_ffmpeg_lib() {
    local target=$1
    if [ x"${target}" = x"${HOST32}" ]; then
        local pref=${PREF32}
        local cross=
        local cpu=i686
        local cflag="${CFLAG}"
        local arch=x86
    else
        local pref=${PREF64}
        local cross="${HOST64}-"
        local cpu=x86_64
        local cflag="${CFLAG}"
        local arch=x86_64
    fi
    if [ x"${STATIC}" = x"yes" ]; then
        local conf_static="--enable-static"
    else
        local conf_static="--disable-static"
    fi
    if [ x"${SHARED}" = x"yes" ]; then
        local conf_shared="--enable-shared"
    else
        local conf_shared="--disable-shared"
    fi
    if [ x"${LIB_TYPE}" = x"0" ]; then
        local ldflags="-static"
        local pkgconfig="--pkg-config-flags=--static"
    else
        local ldflags=
        local pkgconfig=
    fi
    cd ${FFMPEG_DIR}
    func_echo "Start building ( FFmpeg lib[${arch}])..."
    PKG_CONFIG_PATH=${pref}/lib/pkgconfig \
    ./configure \
        --prefix=${pref} \
        --cross-prefix=${cross} \
        --cpu=${cpu} \
        --target-os=mingw32 \
        --arch=${arch} \
        --enable-gpl \
        --enable-version3 \
        --enable-avresample \
        --enable-cross-compile \
        --enable-w32threads \
        --disable-avisynth \
        --disable-debug \
        --disable-devices \
        --disable-doc \
        --disable-dxva2 \
        --disable-hwaccels \
        --disable-indevs \
        --disable-muxers \
        --disable-network \
        --disable-outdevs \
        --disable-programs \
        --disable-pthreads \
        ${conf_static} \
        ${conf_shared} \
        ${pkgconfig} \
        --optflags="${cflag}" \
        --extra-cflags="-I${pref}/include" \
        --extra-ldflags="-L${pref}/lib ${ldflags}"
    sleep 4s
    make clean && make -j ${JOBS} && make install || func_error "Failed to make. (FFmpeg(lib)[${arch}])"
    move_def ${pref}
    echo
}

move_def() {
    local pref=$1
    local list=("avcodec" \
                "avdevice" \
                "avfilter" \
                "avformat" \
                "avresample" \
                "avutil" \
                "postproc" \
                "swresample" \
                "swscale")
    func_check_dir ${pref}/bin/${FFMPRG_LIB_DIR} ${pref}/lib/${FFMPRG_DEF_DIR}
    for lib in ${list[@]}
    do
        if [ -f ${pref}/bin/${lib}.lib ]; then
            mv ${pref}/bin/${lib}.lib ${pref}/bin/${FFMPRG_LIB_DIR}/
        fi
        if ls ${pref}/lib/${lib}*.def >/dev/null 2>&1; then
            mv ${pref}/lib/${lib}*.def ${pref}/lib/${FFMPRG_DEF_DIR}/
        fi
    done
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
    if [ x"${LIB_ONLY}" = x"yes" ]; then
        build_ffmpeg_lib ${HOST32}
    else
        build_ffmpeg ${HOST32}
    fi
else
    if [ x"${LIB_ONLY}" = x"yes" ]; then
        build_ffmpeg_lib ${HOST64}
    else
        build_ffmpeg ${HOST64}
    fi
fi


## End
END_TIME=`func_settime`
cd ~
echo
echo "Total elapsed time: `func_gettime ${START_TIME} ${END_TIME}`"
echo
func_echo "-------------------------"
func_echo "   $(basename $0) finished."
func_echo "-------------------------"



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
