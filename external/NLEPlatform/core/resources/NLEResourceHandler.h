//
// Created by bytedance.1 on 2021/4/9.
//

#ifndef NLEPLATFORM_RESOURCE_NLERESOURCEHANDLER_H
#define NLEPLATFORM_RESOURCE_NLERESOURCEHANDLER_H

#include "nle_export.h"
#include <string>
#include "NLEResourceFetchCallback.h"
#include <memory>
#include <map>
#include <unordered_map>

namespace nle {
    namespace resource {

        class NLEResourceSynchronizer;

        class NLE_EXPORT_CLASS NLEResourceHandler {

        protected:
            std::shared_ptr<NLEResourceSynchronizer> resourceSynchronizer;
        public:

            /**
             * fetch NLE Resource.
             * @param nleResource.
             * @param extraParams: fetch extra parameters.
             * @param callback
             * @return
             */
            virtual int32_t fetchResource(
                    const NLEResourceId &nleResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams = {},
                    const std::shared_ptr<NLEResourceFetchCallback> &callback = nullptr) = 0;

            /**
             * get resource from cache.
             * @param nleResourceId
             * @param extraParams
             * @return
             */
            virtual NLEResourceFile fetchResourceFromCache(
                    const NLEResourceId &nleResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams = {}) = 0;

            /**
             * whether this resource manager can handle this resource.
             * @param nleResource
             * @return
             */
            virtual bool canHandle(const NLEResourceId &nleResourceId) = 0;
        };
    }
}

#endif //NLEPLATFORM_RESOURCE_NLERESOURCEHANDLER_H
