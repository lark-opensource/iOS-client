cd "../"


git checkout ${REBASE_SOURCE}
git fetch 
git reset --hard origin/${REBASE_SOURCE}
git rebase origin/${REBASE_TARGET}
if [ $? -eq 0 ]; then
    git push -f http://${RUNNER_USER_NAME}:${RUNNER_USER_TOKEN}@${PROJECT_GIT_LOCATION} ${REBASE_SOURCE}
     #git push -f  origin HEAD:${REBASE_SOURCE}
else
     git rebase --abort
     exit 1
fi

