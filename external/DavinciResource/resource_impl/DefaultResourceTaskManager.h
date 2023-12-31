//
// Created by wangchengyi.1 on 2021/4/13.
//

#ifndef DAVINCIRESOURCEDEMO_DEFAULTRESOURCETASKMANAGER_H
#define DAVINCIRESOURCEDEMO_DEFAULTRESOURCETASKMANAGER_H

#include <unordered_map>
#include "DAVResourceTask.h"
#include "DAVResourceHandler.h"
#include <atomic>
#include <memory>

namespace davinci {
    namespace executor {
        class Executor;
    }
}

namespace davinci {
    namespace resource {
        class DefaultResourceTaskManager : public davinci::resource::DAVResourceTaskManager {
        private:
            std::shared_ptr<davinci::executor::Executor> executor;
        public:

            DefaultResourceTaskManager();

            DRResult cancelTask(DAVResourceTaskHandle taskHandle) override;

            DAVResourceTaskHandle commit(const std::shared_ptr<davinci::task::Task> &task) override;

            std::shared_ptr<davinci::executor::Executor> getExecutor() override;
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_DEFAULTRESOURCETASKMANAGER_H
