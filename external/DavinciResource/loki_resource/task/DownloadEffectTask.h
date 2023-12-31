//
// Created by wangchengyi.1 on 2021/4/28.
//

#ifndef DAVINCIRESOURCEDEMO_DOWNLOADEFFECTTASK_H
#define DAVINCIRESOURCEDEMO_DOWNLOADEFFECTTASK_H

#include "Task.h"
#include "DAVResourceManager.h"
#include "../LokiResourceConfig.h"
#include "../LokiDataModel.h"

namespace davinci {
    namespace loki {
        class DownloadEffectTask : public davinci::task::Task {

        public:
            DownloadEffectTask(std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager,
                               std::shared_ptr<davinci::resource::DAVResource> davinciResource,
                               std::function<void(
                                       std::shared_ptr<davinci::resource::DAVResource> davinciResource)> onSuccess = nullptr,
                               std::function<void(int, long)> onProgress = nullptr,
                               std::function<void(const std::string &)> onFail = nullptr);

            void run() override;

        private:
            std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager;
            std::shared_ptr<davinci::resource::DAVResource> davinciResource;
            std::function<void(std::shared_ptr<davinci::resource::DAVResource>)> onSuccess;
            std::function<void(int, long)> onProgress;
            std::function<void(const std::string &)> onFail;

            void fetchUrlListWithIndex(const std::vector<std::string> &file_url,
                                       int index,
                                       const std::string &filePath,
                                       const std::string &md5);
        };
    } }


#endif //DAVINCIRESOURCEDEMO_DOWNLOADEFFECTTASK_H
