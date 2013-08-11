#!/bin/sh

FILES=$(\ls -1 .)

git checkout master && \
for f in $FILES; do git rm -r $f; done && \
cp -a _site/* . && \
git add . && \
git commit -m 'Site updated' && \
git push origin master && \
git checkout source
