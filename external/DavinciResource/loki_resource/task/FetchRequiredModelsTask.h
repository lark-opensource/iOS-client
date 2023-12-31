//
// Created by wangchengyi.1 on 2021/5/6.
//

#ifndef DAVINCIRESOURCEDEMO_FETCHREQUIREDMODELSTASK_H
#define DAVINCIRESOURCEDEMO_FETCHREQUIREDMODELSTASK_H

#include <vector>
#include <string>
#include "DAVResourceManager.h"
#include "Task.h"
#include "../LokiResourceConfig.h"
#include "../LokiDataModel.h"

namespace davinci {
    namespace loki {
        class FetchRequiredModelsTask : public davinci::task::Task {
        public:
            explicit FetchRequiredModelsTask(std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager);

            void run() override;

        private:
            std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager;
        };
    } }


#endif //DAVINCIRESOURCEDEMO_FETCHREQUIREDMODELSTASK_H
