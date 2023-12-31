//
// Created by bytedance on 2021/4/13.
//
#pragma once
#ifndef DAVINCIRESOURCE_TASK_H
#define DAVINCIRESOURCE_TASK_H

#include <mutex>
#include <memory>
#include <set>
#include <stdexcept>  // std::out_of_range
#include <utility>
#include <vector>     // std::vector
#include "Bundle.h"
#include <functional>

namespace davinci {
    namespace executor {
        class Executor;
    }
}

namespace davinci {
    namespace task {
        class Task : public std::enable_shared_from_this<Task> {
            friend class TaskGraphBuilder;

        private:
            std::string errorMsg;
            bool isDependTaskFailed = false;
            std::set<std::shared_ptr<Task>> behindTasks;
            std::set<std::shared_ptr<Task>> dependTasks;

            void dependOn(const std::shared_ptr<Task> &task);

            void removeDependence(const std::shared_ptr<Task> &task);

            void behind(const std::shared_ptr<Task> &task);

            void removeBehind(const std::shared_ptr<Task> &task);

            void
            onDependTaskFinished(const std::shared_ptr<Task> &task, const std::string &errorMsg = "");

            void notifyBehindTasksFinished(const std::string &errorMsg = "");

        protected:
            std::mutex mutex;
            std::shared_ptr<davinci::executor::Executor> executor;
            std::shared_ptr<Bundle> bundle;
        public:
            virtual void run() = 0;

            virtual void cancel();

            virtual void notifyBehindTasksSuccess();

            virtual void notifyBehindTasksFailed(const std::string &errorMsg);
        };

        class DefaultRootDagTask : public Task {
            friend class TaskGraphBuilder;
        public:
            DefaultRootDagTask(const std::shared_ptr<Bundle> &bundle = nullptr);

        private:
            void run() override;
        };

        class DefaultEndDagTask : public Task {
            friend class TaskGraphBuilder;

        private:
            bool isFailed = false;
            std::function<void()> customOnSuccess = nullptr;
            std::function<void(const std::string &errorMsg)> customOnFail = nullptr;

            void run() override;

            void notifyBehindTasksSuccess() override;

            void notifyBehindTasksFailed(const std::string &errorMsg) override;
        };

        class TaskGraphBuilder {
        public:
            explicit TaskGraphBuilder(const std::shared_ptr<davinci::executor::Executor>& executor, const std::shared_ptr<Bundle> &bundle = nullptr);

            TaskGraphBuilder &add(const std::shared_ptr<Task> &task);

            TaskGraphBuilder &dependOn(const std::shared_ptr<Task> &task);

            TaskGraphBuilder &onSuccess(std::function<void()> onSuccess);

            TaskGraphBuilder &onFail(std::function<void(const std::string &errorMsg)> onFail);

            std::shared_ptr<Task> build();

        private:
            std::shared_ptr<davinci::executor::Executor> executor;
            std::shared_ptr<DefaultRootDagTask> rootTask;
            std::shared_ptr<DefaultEndDagTask> endTask;
            std::shared_ptr<Task> cacheTask;
        };
    }
}

#endif //DAVINCIRESOURCE_TASK_H
