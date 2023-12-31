//
// Created by wangchengyi.1 on 2021/4/13.
//

#ifndef DAVINCIRESOURCEDEMO_DEFAULTRESOURCEMANAGER_H
#define DAVINCIRESOURCEDEMO_DEFAULTRESOURCEMANAGER_H

#include "DAVResourceManager.h"
#include <vector>

namespace davinci {
    namespace resource {
    class DefaultResourceManager : public davinci::resource::DAVResourceManager, public std::enable_shared_from_this<DefaultResourceManager> {
        public:
            DefaultResourceManager();
            DAVResourceTaskHandle fetchResource(
                    std::shared_ptr<DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams = {},
                    const std::shared_ptr<DAVResourceFetchCallback> &callback = nullptr) override;

            std::shared_ptr<DAVResource> fetchResourceFromCache(
                    const DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams) override;

            DRResult
            registerResourceHandler(const std::shared_ptr<DAVResourceHandler> &resourceHandler) override;

            std::shared_ptr<DAVResourceTaskManager> getTaskManager() override;

        private:
            std::shared_ptr<DAVResourceTaskManager> taskManager;
            std::vector<std::shared_ptr<DAVResourceHandler>> resourceHandlers;
        };
    }
}

#endif //DAVINCIRESOURCEDEMO_DEFAULTRESOURCEMANAGER_H
