//
// Created by wangchengyi.1 on 2021/4/9.
//

#ifndef DAVINCIRESOURCEDEMO_DRESOURCEHANDLER_H
#define DAVINCIRESOURCEDEMO_DRESOURCEHANDLER_H

#include <string>
#include "DAVResource.h"
#include "DAVResourceTask.h"
#include "DAVResourceFetchCallback.h"
#include "DAVPubDefine.h"
#include <memory>
#include <map>
#include <unordered_map>

namespace davinci {
    namespace resource {

        class DAV_EXPORT DAVResourceManager;
        class DAV_EXPORT DAVResourceHandler {
            friend class DefaultResourceManager;

        protected:
            std::shared_ptr<DAVResourceTaskManager> taskManager;
            std::shared_ptr<DAVResourceManager> resourceManager;
        public:
            virtual ~DAVResourceHandler() = default;
            
            /**
             * fetch Davinci Resource.
             * @param davinciResource.
             * @param extraParams: fetch extra parameters.
             * @param callback
             * @return
             */
            virtual DAVResourceTaskHandle fetchResource(
                    const std::shared_ptr<DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams = {},
                    const std::shared_ptr<DAVResourceFetchCallback> &callback = nullptr) = 0;

            /**
             * get resource from cache.
             * @param davinciResourceId
             * @param extraParams
             * @return
             */
            virtual std::shared_ptr<DAVResource> fetchResourceFromCache(
                    const DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams = {}) = 0;

            /**
             * whether this resource manager can handle this resource.
             * @param davinciResource
             * @return
             */
            virtual bool canHandle(const std::shared_ptr<DAVResource> &davinciResource) = 0;
        };
    }
}

#endif //DAVINCIRESOURCEDEMO_DRESOURCEHANDLER_H
