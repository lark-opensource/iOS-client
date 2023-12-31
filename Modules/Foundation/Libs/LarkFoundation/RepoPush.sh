RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;35m'

usage()
{
    echo "
Usage: 
    $ RepoPush.sh [-t]
Options: 
    -t: tag name"
    exit 1
}

while getopts "t:" arg
do
    case $arg in
        t) #Version
            echo "${GREEN}RepoPush the specific tag: $OPTARG"
            git tag $OPTARG
            git push origin $OPTARG
            pod repo push byted-ee-lark-ios-larkspecrepo LarkFoundation.podspec --allow-warnings --skip-import-validation --skip-tests
            ;;
		?) #Unknow Arg
            usage
            ;;
    esac
done

if [ $# -eq 0 ]; then
    usage
fi