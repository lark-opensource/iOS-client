//
// Created by wangchengyi.1 on 2021/5/8.
//

#ifndef DAVINCIRESOURCEDEMO_DOWNLOADMODELTASK_H
#define DAVINCIRESOURCEDEMO_DOWNLOADMODELTASK_H

#include "Task.h"
#include "DAVResourceManager.h"
#include "../AlgorithmResourceGlobalSettings.h"
#include "../AlgorithmResourceConfig.h"
#include "../AlgorithmDataModel.h"

namespace davinci {
    namespace algorithm {
        class DownloadModelTask : public davinci::task::Task {
        public:
            DownloadModelTask(AlgorithmResourceConfig config, std::string modelName,
                              std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager);

            void run() override;

        private:
            std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager;
            std::string modelName;
            AlgorithmResourceConfig config;

            void fetchUrlListWithIndex(const std::vector<std::string> &file_url, int index,
                                       const std::string &uri,
                                       const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo);
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_DOWNLOADMODELTASK_H
