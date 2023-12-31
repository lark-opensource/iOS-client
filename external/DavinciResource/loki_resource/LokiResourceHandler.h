//
// Created by wangchengyi.1 on 2021/4/13.
//

#ifndef DAVINCIRESOURCEDEMO_LOKIRESOURCEHANDLER_H
#define DAVINCIRESOURCEDEMO_LOKIRESOURCEHANDLER_H

#include <utility>
#include <string>
#include "DAVResourceHandler.h"
#include "LokiResourceConfig.h"

namespace davinci {
    namespace loki {
        class DAV_EXPORT LokiResourceHandler : public davinci::resource::DAVResourceHandler {
        private:
            explicit LokiResourceHandler(LokiResourceConfig config) : config(std::move(config)) {};
        protected:
            LokiResourceConfig config;
        public:
            davinci::resource::DAVResourceTaskHandle fetchResource(
                    const std::shared_ptr<davinci::resource::DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams,
                    const std::shared_ptr<davinci::resource::DAVResourceFetchCallback> &callback) override;

            std::shared_ptr<davinci::resource::DAVResource> fetchResourceFromCache(
                    const davinci::resource::DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams) override;

            bool canHandle(const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) override;

            class DAV_EXPORT Builder {
            private:
                LokiResourceConfig config;
            public:
                Builder &appID(const std::string &appID);

                Builder &accessKey(const std::string &accessKey);

                Builder &channel(const std::string &channel);

                Builder &sdkVersion(const std::string &sdkVersion);

                Builder &appVersion(const std::string &appVersion);

                Builder &deviceType(const std::string &deviceType);

                Builder &deviceId(const std::string &deviceId);

                Builder &effectCacheDir(const std::string &effectCacheDir);

                Builder &platform(const std::string &platform);

                Builder &host(const std::string &host);

                std::shared_ptr<LokiResourceHandler> build();
            };
        };

    }
}

#endif //DAVINCIRESOURCEDEMO_LOKIRESOURCEHANDLER_H
