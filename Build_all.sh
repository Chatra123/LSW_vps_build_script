#!/bin/sh


sh ./lsmash.sh       || exit
sh ./ffmpeg.sh       || exit
sh ./lsmash_works.sh || exit
 
 
 