#!/bin/bash

swift build -c release --arch arm64 --arch x86_64
mv .build/apple/Products/Release/CheckArchs ./CheckArchs