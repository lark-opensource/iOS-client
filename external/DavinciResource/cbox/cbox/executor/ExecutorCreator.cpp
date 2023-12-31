//
// Created by wangchengyi.1 on 2021/6/21.
//

#include "ExecutorCreator.h"
#include "DefaultExecutor.h"

void davinci::executor::ExecutorWrapper::setExecutor(
        const std::shared_ptr<Executor> &executor) {
    ExecutorWrapper::obtain()->executorWrapper = executor;
}

std::shared_ptr<davinci::executor::Executor> davinci::executor::ExecutorWrapper::getExecutor() {
    auto executor = ExecutorWrapper::obtain()->executorWrapper;
    if (executor == nullptr) {
        executor = std::make_shared<DefaultExecutor>();
        ExecutorWrapper::setExecutor(executor);
    }
    return executor;
}

davinci::executor::ExecutorWrapper *davinci::executor::ExecutorWrapper::obtain() {
    static ExecutorWrapper _wrapper;
    return &_wrapper;
}

std::shared_ptr<davinci::executor::Executor> davinci::executor::ExecutorCreator::createExecutor() {
    return ExecutorWrapper::getExecutor();
}
