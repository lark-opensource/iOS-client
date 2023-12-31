RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;35m'

debugFile="liblark.a"
releaseFile="liblark_release.a"
simulator_releaseFile="liblark_simulator_release.a"
libhost="http://10.10.56.228:16666/storage"

liburl=
verinfo=
commitIdErr=
isdebug=false

usage()
{
    echo "Usage: ./rust.sh [-v] [-m] [-t <ver>] [-d <commitId>] [-r <commitId>]
 -v     list available versions
 -m     use master to download release lib
 -t     use specific tag to download release lib
 -d     use specific commit id to download debug lib
 -r     use specific commit id to download release lib
 -s     use specific commit id to download simulator release lib
 -l     use master to download simulator release lib"
    exit 1
}

while getopts ":vmt:d:r:s:l" arg
do
    case $arg in
        v) #Version
            echo "${GREEN}Rust-SDK available versions:${NC}"
            curl http://10.10.56.228:16666/storage/version.txt
            ;;
        m) #Master
            verinfo="Head->Master"
            liburl="$libhost/ios/master/$releaseFile"
            ;;
        t) #Tag
            verinfo="Tag v$OPTARG"
            liburl="$libhost/$OPTARG/$releaseFile"
            ;;
        d) #Debug+CommitId
            isdebug=true
            verinfo="commitId $OPTARG for debug version"
            liburl="$libhost/$OPTARG/$debugFile"
            commitIdErr="Please confirm the commitId is for iOS platform."
            ;;
        r) #Release+CommitId
            verinfo="commitId $OPTARG for release version"
            liburl="$libhost/$OPTARG/$releaseFile"
            commitIdErr="Please confirm the commitId is for iOS platform."
            ;;
	l) #Simulator+Mater
	    verinfo="Head->Master"
            liburl="$libhost/ios_simulator/master/$simulator_releaseFile"
            ;;
	s) #Simulator+CommitId
            verinfo="commitId $OPTARG for simulator release version"
            liburl="$libhost/$OPTARG/$simulator_releaseFile"
            commitIdErr="Please confirm the commitId is for iOS platform."
            ;;
	?) #Unknow Arg
            usage
            ;;
    esac
done

if [ $# -eq 0 ]; then
    usage
fi

if [ -z "$liburl" ]; then
    exit 1
fi

debugPath="../app/app/rust/Debug"
releasePath="../app/app/rust/Release"

if [ ! -d "$debugPath" ]; then
    mkdir -p "$debugPath"
fi

if [ ! -d "$releasePath" ]; then
    mkdir -p "$releasePath"
fi

debugFilePath="$debugPath/liblark.a"
releaseFilePath="$releasePath/liblark.a"

echo "${GREEN}Start to download Rust-SDK library with ${CYAN}$verinfo${NC}"

curl -o "$debugFilePath" "$liburl"

if [ -s "$debugFilePath" ]; then
    if [ "$isdebug" == false ]; then
        #debug verson don't need copy to release directory.
        echo "${GREEN}Copy Rust-SDK library(liblark.a) to local release directory: $releaseFilePath${NC}"
        rsync --progress $debugFilePath $releaseFilePath
    fi
    echo "${GREEN}Current Rust-SDK is up-to-date with ${CYAN}$verinfo."
else
    echo "${RED}Update Rust-SDK failed, $verinfo may not existed."
    echo "$commitIdErr\n"
    echo "${GREEN}Rust-SDK available versions:${NC}"
    curl http://10.10.56.228:16666/storage/version.txt
fi



