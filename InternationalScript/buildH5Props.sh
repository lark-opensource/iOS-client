#!/bin/sh

function protos_file_is_modifed {
    local return_=0
    local CHANGED=$(git diff --cached --name-only --diff-filter=M Libs/LarkModel/Protos/Entities.proto)
	if [ ! -z $CHANGED ]; then
		local return_=1
	fi
    if [ $return_ -eq 1 ]; then
        local CHANGED=$(git status Libs/LarkModel/Protos/Entities.proto)
        if [ -z "$CHANGED" ]; then
            local return_=1
        fi
    fi
	echo "$return_"
}

function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

GREEN='\033[0;32m'

if [ $(protos_file_is_modifed) -eq 0 ]; then
    exit 0
fi

# check npm
if [ $(program_is_installed npm) -eq 0 ]; then
	brew install npm
fi

# check pbjs pbts
ROOTSRC="$(pwd)"
PROTOSRC="$ROOTSRC/Libs/LarkModel/Protos"
BINSRC="$ROOTSRC/node_modules/protobufjs/bin"
PROTOC_GEN_SWIFT="$ROOTSRC/InternationalScript/protoc-gen-swift"
if [ ! -d "$BINSRC" ]; then
    npm install
fi

# build .swift .js .ts
echo "build proto to .swift"
"$ROOTSRC/InternationalScript/protoc" --swift_opt=Visibility=Public --plugin=protoc-gen-swift="$PROTOC_GEN_SWIFT" --swift_out="$PROTOSRC/Lark" --proto_path="$PROTOSRC" "$PROTOSRC"/Entities.proto
echo "build proto to .js .d.ts"
echo $($BINSRC/pbjs -t static-module -w commonjs -o "$PROTOSRC/H5/Entities.js" "$PROTOSRC/Entities.proto")
echo $($BINSRC/pbts -o "$PROTOSRC/H5/Entities.d.ts" "$PROTOSRC/H5/Entities.js")
echo "${GREEN}build success"
