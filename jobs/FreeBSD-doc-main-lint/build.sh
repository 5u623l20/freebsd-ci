#!/bin/sh

cd doc
vale .

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
