#!/bin/sh

git checkout master && \
for f in $(\ls -1 .); do git rm -r $f; done && \
cp -a _site/* . && \
git add . && \
git commit -m 'Site updated' && \
git push origin master && \
git checkout source
