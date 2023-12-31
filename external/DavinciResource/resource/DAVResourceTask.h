//
// Created by wangchengyi.1 on 2021/4/11.
//

#ifndef DAVINCIRESOURCEDEMO_DRRESOURCETASK_H
#define DAVINCIRESOURCEDEMO_DRRESOURCETASK_H

#include <string>
#include <memory>
#include "DAVPubDefine.h"

namespace davinci {
    namespace executor {
        class DAV_EXPORT Executor;
    }
}

namespace davinci {
    namespace task {
        class DAV_EXPORT Task;
    }
}

namespace davinci {
    namespace resource {
        /**
         * Davinci Resource Task Manager
         */
        class DAV_EXPORT DAVResourceTaskManager : public std::enable_shared_from_this<DAVResourceTaskManager> {
        public:
          virtual ~DAVResourceTaskManager() = default;

            /**
             * can task.
             * @param taskHandle
             * @return
             */
            virtual DRResult cancelTask(DAVResourceTaskHandle taskHandle) = 0;

            virtual DAVResourceTaskHandle commit(const std::shared_ptr<davinci::task::Task> &task) = 0;

            virtual std::shared_ptr<davinci::executor::Executor> getExecutor() = 0;
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DRRESOURCETASK_H
