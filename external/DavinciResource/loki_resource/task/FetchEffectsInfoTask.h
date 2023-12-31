//
// Created by bytedance on 2021/4/16.
//
#ifndef DAVINCIRESOURCE_FETCHEFFECTSINFOTASK_H
#define DAVINCIRESOURCE_FETCHEFFECTSINFOTASK_H

#include "Task.h"
#include "../LokiDataModel.h"
#include "BaseUrlFetcherTask.hpp"
#include <utility>
#include "DAVPublicUtil.h"
#include "../LokiConstanceDefine.h"
#include "../LokiResource.h"
#include "DAVResourceIdParser.h"
#include "../LokiResourceConfig.h"
#include "../LokiResourceUtils.h"

namespace davinci {
    namespace loki {
        class FetchEffectsInfoTask : public davinci::task::BaseUrlFetcherTask<EffectListResponse> {
        public:
            FetchEffectsInfoTask(const LokiResourceConfig &config,
                                 const std::shared_ptr<davinci::resource::DAVResource> &davinciResource,
                                 const std::unordered_map<std::string, std::string> &extraParams);

        private:
            std::unordered_map<std::string, std::string> extraParams;
            std::string cacheDir;

            void run() override;

            std::string buildRequestUrl(const LokiResourceConfig &config,
                                                                const std::shared_ptr<davinci::resource::DAVResource> &davinciResource);

            void processResponse(std::shared_ptr<EffectListResponse> response) override;
        };
    }
}
#endif//DAVINCIRESOURCE_FETCHEFFECTSINFOTASK_H
