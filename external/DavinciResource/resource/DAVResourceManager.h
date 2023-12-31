//
// Created by wangchengyi.1 on 2021/4/11.
//

#ifndef DAVINCIRESOURCEDEMO_DRRESOURCEMANAGER_H
#define DAVINCIRESOURCEDEMO_DRRESOURCEMANAGER_H

#include "DAVResourceHandler.h"
#include "DAVPubDefine.h"

namespace davinci {
    namespace resource {

        class DAV_EXPORT DAVResourceManager {
        public:
            virtual ~DAVResourceManager() = default;
            
            /**
             * fetch davinci resource.
             * @param davinciResource
             * @param extraParams
             * @param callback
             * @return
             */
            virtual DAVResourceTaskHandle fetchResource(
                    std::shared_ptr<DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams = {},
                    const std::shared_ptr<DAVResourceFetchCallback> &callback = nullptr) = 0;

            /**
             * fetch resource from cache.
             * @param davinciResourceId
             * @param extraParams
             * @return
             */
            virtual std::shared_ptr<DAVResource> fetchResourceFromCache(
                    const DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams = {}) = 0;

            /**
             * register resource handler.
             * @param resourceHandler
             * @return
             */
            virtual DRResult registerResourceHandler(const std::shared_ptr<DAVResourceHandler> &resourceHandler) = 0;

            /**
             * get current task manager.
             * @return
             */
            virtual std::shared_ptr<DAVResourceTaskManager> getTaskManager() = 0;
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DRRESOURCEMANAGER_H