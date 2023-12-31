// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_DEFAULT_EXECUTOR_H
#define DAVINCIRESOURCE_DEFAULT_EXECUTOR_H

#include <functional>
#include <memory>
#include <unordered_map>
#include "Executor.h"
#include "DAVThreadPool.h"

namespace davinci {
    namespace executor {

        class DAV_EXECUTOR_EXPORT DefaultExecutor : public Executor {
        private:
            DAVThreadPool pool;
            std::unordered_map<int64_t, std::shared_ptr<ExecWrapper>> execMap;
            std::recursive_mutex mutex;

            void remove(int64_t execId);

        public:
            explicit DefaultExecutor(int worker_count = 10, int task_limit = 100) : pool(worker_count) {
                pool.init();
            }

            ~DefaultExecutor() {
                cancelAll();
                pool.shutdown();
            }

            int64_t commit(const std::function<void()> &executable) override;

            int64_t postDelayed(const std::function<void()> &executable, long long delayMillis) override;

            void cancel(int64_t execId) override;

            void cancelAll();

            void shutdown();

        private:
            static void executeFunc(const std::shared_ptr<ExecWrapper> &execWrapper, const std::shared_ptr<Executor> &executor,
                                    int64_t execId);
        };
    }
}



#endif //DAVINCIRESOURCE_DEFAULT_EXECUTOR_H
