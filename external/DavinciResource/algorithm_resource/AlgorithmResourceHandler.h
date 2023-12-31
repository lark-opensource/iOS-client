//
// Created by wangchengyi.1 on 2021/5/7.
//

#ifndef DAVINCIRESOURCEDEMO_ALGORITHMRESOURCEHANDLER_H
#define DAVINCIRESOURCEDEMO_ALGORITHMRESOURCEHANDLER_H

#include "DAVResourceHandler.h"
#include "AlgorithmResourceConfig.h"

namespace davinci {
    namespace algorithm {

        class DAV_EXPORT AlgorithmResourceHandler : public davinci::resource::DAVResourceHandler {

        public:
            explicit AlgorithmResourceHandler(AlgorithmResourceConfig config);

            virtual davinci::resource::DAVResourceTaskHandle fetchResource(
                    const std::shared_ptr<davinci::resource::DAVResource> &davinciResource,
                    const std::unordered_map<std::string, std::string> &extraParams = {},
                    const std::shared_ptr<davinci::resource::DAVResourceFetchCallback> &callback = nullptr) override;

            virtual std::shared_ptr<davinci::resource::DAVResource> fetchResourceFromCache(
                    const davinci::resource::DavinciResourceId &davinciResourceId,
                    const std::unordered_map<std::string, std::string> &extraParams = {}) override;

            virtual bool canHandle(const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) override;

            std::string findModelUri(const std::string &modelName);

        private:
            davinci::algorithm::AlgorithmResourceConfig config;

        public:
            class DAV_EXPORT Builder {
            private:
                davinci::algorithm::AlgorithmResourceConfig config;
            public:
                Builder &appID(const std::string &appID);

                Builder &accessKey(const std::string &accessKey);

                Builder &sdkVersion(const std::string &sdkVersion);

                Builder &appVersion(const std::string &appVersion);

                Builder &deviceType(const std::string &deviceType);

                Builder &deviceId(const std::string &deviceId);

                Builder &cacheDir(const std::string &cacheDir);

                Builder &platform(const std::string &platform);

                Builder &host(const std::string &host);

                Builder &busiId(const std::string &busiId);

                Builder &status(const std::string &status);

                std::shared_ptr<davinci::algorithm::AlgorithmResourceHandler> build();
            };
        };


    }
}


#endif //DAVINCIRESOURCEDEMO_ALGORITHMRESOURCEHANDLER_H
