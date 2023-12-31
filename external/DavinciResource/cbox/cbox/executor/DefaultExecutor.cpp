//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "DefaultExecutor.h"
#include "IdGenerator.h"

using davinci::executor::ExecWrapper;
using davinci::executor::DefaultExecutor;

void ExecWrapper::run() {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    if (executable != nullptr) {
        executable();
    }
}

void ExecWrapper::cancel() {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    if (executable != nullptr) {
        executable = nullptr;
    }
}

int64_t DefaultExecutor::commit(const std::function<void()> &executable) {
    auto execWrapper = std::make_shared<ExecWrapper>(executable);
    int64_t execId = IDGenerator::get().generateId();
    {
        std::unique_lock<std::recursive_mutex> lock(mutex);
        execMap[execId] = execWrapper;
    }
    auto self = this->shared_from_this();
    pool.submit(DefaultExecutor::executeFunc, execWrapper, self, execId);
    return execId;
}

void DefaultExecutor::cancel(int64_t execId) {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    if (execMap.find(execId) != execMap.end()) {
        execMap[execId]->cancel();
        execMap.erase(execId);
    }
}

void DefaultExecutor::remove(int64_t execId) {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    if (execMap.find(execId) != execMap.end()) {
        execMap.erase(execId);
    }
}

void
DefaultExecutor::executeFunc(const std::shared_ptr<ExecWrapper> &execWrapper, const std::shared_ptr<Executor> &executor,
                             int64_t execId) {
    if (execWrapper) {
        execWrapper->run();
    }
    if (executor) {
        (std::dynamic_pointer_cast<DefaultExecutor>(executor))->remove(execId);
    }
}

int64_t
DefaultExecutor::postDelayed(const std::function<void()> &executable, long long int delayMillis) {
    auto execWrapper = std::make_shared<ExecWrapper>(executable);
    int64_t execId = IDGenerator::get().generateId();
    {
        std::unique_lock<std::recursive_mutex> lock(mutex);
        execMap[execId] = execWrapper;
    }
    auto self = this->shared_from_this();
    pool.postDelay(delayMillis, DefaultExecutor::executeFunc, execWrapper, self, execId);
    return execId;
}

void davinci::executor::DefaultExecutor::cancelAll() {
    {
        std::unique_lock<std::recursive_mutex> lock(mutex);
        execMap.clear();
    }
}

void davinci::executor::DefaultExecutor::shutdown() {
    pool.shutdown();
}
