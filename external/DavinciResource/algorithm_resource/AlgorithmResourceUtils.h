//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_ALGOTITHMRESOURCEUTILS_H
#define DAVINCIRESOURCE_ALGOTITHMRESOURCEUTILS_H

#include <string>
#include "AlgorithmDataModel.h"
#include "AlgorithmResourceConfig.h"

namespace davinci {
    namespace algorithm {
        class AlgorithmResourceUtils {
        public:
            AlgorithmResourceUtils() = delete;
            ~AlgorithmResourceUtils() = delete;

            static std::string getNormalizedNameOfModel(const std::string &modelName);

            static std::string getFullNameOfModel(const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo);

            static bool isModelDownloaded(const std::string &cacheDir,
                                          const std::string &modelName,
                                          const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo);

            static void clearOldVersionOfModel(const std::string &cacheDir,
                                               const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo);

            static std::string getModelPathFromModelUri(const std::string &modelUri);
        };
    }
}

#endif //DAVINCIRESOURCE_ALGOTITHMRESOURCEUTILS_H
