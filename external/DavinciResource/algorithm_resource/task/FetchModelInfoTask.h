//
// Created by wangchengyi.1 on 2021/5/10.
//

#ifndef DAVINCIRESOURCEDEMO_FETCHMODELINFOTASK_H
#define DAVINCIRESOURCEDEMO_FETCHMODELINFOTASK_H

#include "BaseUrlFetcherTask.hpp"
#include "../AlgorithmDataModel.h"
#include "../AlgorithmResourceConfig.h"

namespace davinci {
    namespace algorithm {
        class FetchModelInfoTask : public davinci::task::BaseUrlFetcherTask<davinci::algorithm::ModelInfoResponse> {

        public:
            FetchModelInfoTask(const davinci::algorithm::AlgorithmResourceConfig &config,
                               const std::vector<std::string> &modelNames,
                               const std::unordered_map<std::string, std::string> &extraParams = {});

            void processResponse(std::shared_ptr<davinci::algorithm::ModelInfoResponse> response) override;

            void run() override;

        private:
            std::string modelList;
        };
    }
}

#endif //DAVINCIRESOURCEDEMO_FETCHMODELINFOTASK_H
