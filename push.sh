#!/bin/sh

git checkout master && \
cp -a _site/* . && \
git add . && \
git commit -m 'Site updated' && \
git push origin master && \
git checkout source
