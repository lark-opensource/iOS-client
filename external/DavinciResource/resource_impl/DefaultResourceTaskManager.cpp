//
// Created by wangchengyi.1 on 2021/4/13.
//

#include "DefaultResourceTaskManager.h"
#include "Task.h"
#include <ExecutorCreator.h>

davinci::resource::DRResult
davinci::resource::DefaultResourceTaskManager::cancelTask(DAVResourceTaskHandle taskHandle) {
    //TODO 取消
    executor->cancel(taskHandle);
    return 0;
}

davinci::resource::DAVResourceTaskHandle
davinci::resource::DefaultResourceTaskManager::commit(const std::shared_ptr<davinci::task::Task> &task) {
    int64_t taskId = executor->commit([task](){
        task->run();
    });
    return taskId;
}

std::shared_ptr<davinci::executor::Executor> davinci::resource::DefaultResourceTaskManager::getExecutor() {
    return executor;
}

davinci::resource::DefaultResourceTaskManager::DefaultResourceTaskManager() {
    executor = davinci::executor::ExecutorCreator::createExecutor();
}
