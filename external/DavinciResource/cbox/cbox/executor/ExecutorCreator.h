//
// Created by wangchengyi.1 on 2021/6/21.
//

#ifndef DAVINCIRESOURCEDEMO_EXECUTORCREATOR_H
#define DAVINCIRESOURCEDEMO_EXECUTORCREATOR_H

#include <memory>
#include "Executor.h"
#include "DAVExecutorExport.h"
namespace davinci {
    namespace executor {

        class DAV_EXECUTOR_EXPORT ExecutorCreator {
        public:
            static std::shared_ptr<Executor> createExecutor();
        };

        class ExecutorWrapper {

        public:
            static void setExecutor(const std::shared_ptr<Executor> &executor);

            static std::shared_ptr<Executor> getExecutor();

            static ExecutorWrapper *obtain();

        private:
            std::shared_ptr<Executor> executorWrapper;
        };
    }
}



#endif //DAVINCIRESOURCEDEMO_EXECUTORCREATOR_H
