#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-
#
# Rename screenshot files to cleaner names, names for which a
# lexicographic sort is equivalent to a time-based sort.
#
# 
# Created: <Wed Dec  4 10:24:15 2013>
# Last Updated: <2013-December-04 13:57:46>
#

IFS=$'\n'
targdir=/Users/${USER}/Documents/screenshot
mvdir=/Users/${USER}/Dropbox/www/wiki/files
pattern=Screen\ Shot\ ????-??-??\ at\ *M.png 

cd $mvdir
today="$( date +"%Y_%m_%d_img" )"
number=1
fname=${today}01.png

while [ -e "$fname" ]; do
    printf -v fname -- '%s%02d.png' "$today" "$(( ++number ))"
done

printf 'Will use "%s" as filename\n' "$fname"

cd $targdir
files="$(find . -iname "$pattern" -type f -print)"
if [ -n "$files" ]; then
  count=$(echo "$files" | wc -l)
else 
  count=0
fi


if [ $count -gt 0 ]; then
  ix=1
  for item in ${files} ; do
      printf "%d. %-18s\n" $ix "$item"
      mv "${item}" "${mvdir}/${fname}"
      printf -v fname -- '%s%02d.png' "$today" "$(( ++number ))"
      printf 'Will use "%s" as next filename\n' "$fname"
  done
fi


