//
// Created by bytedance on 2021/4/13.
//

#include "Task.h"
#include <utility>
#include "Executor.h"

using davinci::task::Task;
using davinci::task::TaskGraphBuilder;
using davinci::task::DefaultEndDagTask;
using davinci::task::DefaultRootDagTask;

void Task::notifyBehindTasksSuccess() {
    notifyBehindTasksFinished();
}

void Task::notifyBehindTasksFailed(const std::string &error) {
    notifyBehindTasksFinished(error);
}

void Task::dependOn(const std::shared_ptr<Task> &task) {
    if (task.get() != this) {
        {
            std::lock_guard<std::mutex> lock(mutex);
            dependTasks.insert(task);
        }
        task->behind(this->shared_from_this());
    }
}

void Task::removeDependence(const std::shared_ptr<Task> &task) {
    if (task.get() != this) {
        {
            std::lock_guard<std::mutex> lock(mutex);
            dependTasks.erase(task);
        }
        task->removeBehind(this->shared_from_this());
    }
}

void Task::behind(const std::shared_ptr<Task> &task) {
    if (task.get() != this) {
        {
            std::lock_guard<std::mutex> lock(mutex);
            behindTasks.insert(task);
        }
    }
}

void Task::removeBehind(const std::shared_ptr<Task> &task) {
    if (task.get() != this) {
        {
            std::lock_guard<std::mutex> lock(mutex);
            behindTasks.erase(task);
        }
    }
}

void Task::onDependTaskFinished(const std::shared_ptr<Task> &dependTask, const std::string &error) {
    {
        std::lock_guard<std::mutex> lock(mutex);
        if (dependTasks.empty()) {
            return;
        }
        dependTasks.erase(dependTask);
        if (!error.empty()) {
            isDependTaskFailed = true;
            errorMsg = error;
        }
    }
    if (dependTasks.empty()) {
        if (isDependTaskFailed) {
            notifyBehindTasksFailed(errorMsg);
        } else {
            auto self = this->shared_from_this();
            executor->commit([self]() {
                self->run();
            });
        }
    }
}

void Task::notifyBehindTasksFinished(const std::string& e) {
    std::set<std::shared_ptr<Task>> tempList;
    {
        std::lock_guard<std::mutex> lock(mutex);
        if (behindTasks.empty()) {
            return;
        }
        tempList = behindTasks;
    }
    for (const auto &task : tempList) {
        task->onDependTaskFinished(this->shared_from_this(), e);
    }
}

void Task::cancel() {
}

TaskGraphBuilder &TaskGraphBuilder::add(const std::shared_ptr<Task> &task) {
    task->executor = executor;
    task->dependOn(rootTask);
    task->bundle = rootTask->bundle;
    endTask->dependOn(task);
    cacheTask = task;
    return *this;
}

TaskGraphBuilder &TaskGraphBuilder::dependOn(const std::shared_ptr<Task> &task) {
    cacheTask->dependOn(task);
    endTask->removeDependence(task);
    cacheTask->removeDependence(rootTask);
    return *this;
}

TaskGraphBuilder &TaskGraphBuilder::onSuccess(std::function<void()> onSuccess) {
    endTask->customOnSuccess = std::move(onSuccess);
    return *this;
}

TaskGraphBuilder &TaskGraphBuilder::onFail(std::function<void(const std::string &)> onFail) {
    endTask->customOnFail = std::move(onFail);
    return *this;
}

std::shared_ptr<Task> TaskGraphBuilder::build() {
    return rootTask;
}

TaskGraphBuilder::TaskGraphBuilder(const std::shared_ptr<davinci::executor::Executor> &executor, const std::shared_ptr<Bundle> &bundle)
        : executor(executor) {
    rootTask = std::make_shared<DefaultRootDagTask>(bundle);
    rootTask->executor = executor;
    endTask = std::make_shared<DefaultEndDagTask>();
    endTask->executor = executor;
    cacheTask = rootTask;

}

void DefaultEndDagTask::notifyBehindTasksSuccess() {
    if (customOnSuccess != nullptr) {
        customOnSuccess();
    }
}

void DefaultEndDagTask::notifyBehindTasksFailed(const std::string &errorMsg) {
    if (isFailed) {
        return;
    }
    isFailed = true;
    if (customOnFail != nullptr) {
        customOnFail(errorMsg);
    }
}

void DefaultEndDagTask::run() {
    notifyBehindTasksSuccess();
}

void DefaultRootDagTask::run() {
    notifyBehindTasksSuccess();
}

DefaultRootDagTask::DefaultRootDagTask(const std::shared_ptr<Bundle> &bundle) {
    if (bundle == nullptr) {
        this->bundle = std::make_shared<Bundle>();
    } else {
        this->bundle = bundle;
    }
}
