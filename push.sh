#!/bin/sh

git checkout master && \
rm -rf 201*/ assets/ *.xml *.html *.txt
cp -a _site/* . && \
git add . && \
git commit -m 'Site updated' && \
git push origin master && \
git checkout source
