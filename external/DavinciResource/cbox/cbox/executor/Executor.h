// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_EXECUTOR_H
#define DAVINCIRESOURCE_EXECUTOR_H

#include <functional>
#include <memory>
#include <unordered_map>
#include <mutex>
#include "DAVExecutorExport.h"
namespace davinci {
    namespace executor {
        class DAV_EXECUTOR_EXPORT Executor : public std::enable_shared_from_this<Executor> {
        public:
            virtual int64_t commit(const std::function<void()> &executable) = 0;

            virtual int64_t postDelayed(const std::function<void()> &executable, long long delayMillis) = 0;

            virtual void cancel(int64_t execId) = 0;
        };

        class ExecWrapper {
        public:
            explicit ExecWrapper(std::function<void()> executable) : executable(std::move(executable)) {
            }

            void run();

            void cancel();

        private:
            std::function<void()> executable;
            std::recursive_mutex mutex;
        };
    }
}

#endif //DAVINCIRESOURCE_EXECUTOR_H
