#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
cd $workdir
echo $workdir
../BuildScript/XcodeEdit ../ ./BuildScript/develop.json internal