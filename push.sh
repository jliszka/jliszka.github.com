#!/bin/sh

shopt -s extglob && \
git checkout master && \
rm -rf !\(_site\) && \
cp -a _site/* . && \
git add . && \
git commit -m 'Site updated' && \
git push origin master && \
git checkout source && \
shopt -u extglob
