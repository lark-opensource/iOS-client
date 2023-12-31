#!/bin/sh

CURRENT=`cat output | grep -Eo "Test Coverage: \d+(\.\d+)?" | grep -Eo '\d+(\.\d+)?'`
echo "current code coverage: $CURRENT"

if [ -f /var/coverage/coverage ]; then
  BASE=`cat /var/coverage/coverage`
  echo "base code coverage: $BASE"
  if [ `bc -l <<< "40 <= $CURRENT" ` = "0" ]; then
    echo "failed!"
    exit 1
  fi
fi

if [ $CI_COMMIT_REF_NAME == "develop" ]; then
  echo "saving coverage"
  echo $CURRENT > /var/coverage/coverage
fi
