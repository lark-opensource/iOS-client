//
// Created by wangchengyi.1 on 2021/4/27.
//

#ifndef DAVINCIRESOURCEDEMO_URLRESOURCEHANDLER_H
#define DAVINCIRESOURCEDEMO_URLRESOURCEHANDLER_H

#include "DAVResourceHandler.h"

namespace davinci {
    namespace downloader {
        class DAVDownloader;
    }
}
namespace davinci {
    namespace resource {
        class DAV_EXPORT UrlResourceHandler : public davinci::resource::DAVResourceHandler {

        public:
            UrlResourceHandler();

            DAVResourceTaskHandle fetchResource(
                    const std::shared_ptr<DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams,
                    const std::shared_ptr<DAVResourceFetchCallback> &callback) override;

            std::shared_ptr<DAVResource> fetchResourceFromCache(
                    const DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams) override;

            bool canHandle(const std::shared_ptr<DAVResource> &davinciResource) override;

            static std::shared_ptr<UrlResourceHandler> create();

        private:
            std::shared_ptr<davinci::downloader::DAVDownloader> downloader;

        };
    }
}


#endif //DAVINCIRESOURCEDEMO_URLRESOURCEHANDLER_H
