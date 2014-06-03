#!/bin/bash

SOURCEDIR=/Users/gtrummell/Source

cd ${SOURCEDIR}
PROJS=`ls -1 ./`

for PROJ in ${PROJS}; do
    cd ${SOURCEDIR}/${PROJ}
    git checkout master
    git pull
    git checkout develop
    git pull
done