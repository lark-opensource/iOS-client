//
// Created by bytedance.1 on 2021/4/7.
//

#ifndef NLEPLATFORM_RESOURCE_LOKIRESOURCE_H
#define NLEPLATFORM_RESOURCE_LOKIRESOURCE_H

#include "nle_export.h"
#include <string>
#include "NLEResourceProtocol.h"

namespace nle {
    namespace resource {
        class NLE_EXPORT_CLASS NLELokiResourceProtocol : public nle::resource::NLEResourceProtocol {
        public:
            static std::string PLATFORM_STRING();
            static std::string PARAM_EFFECT_ID();
            static std::string PARAM_RESOURCE_ID();
            static std::string PARAM_PANEL();

            explicit NLELokiResourceProtocol(std::string effectId);

            NLELokiResourceProtocol(std::string resourceId, std::string panel);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isLokiResource(const nle::resource::NLEResourceId &resourceId);

        private:
            std::string effectId;
            std::string resourceId;
            std::string panel;
        };
    }
}

#endif //NLEPLATFORM_RESOURCE_LOKIRESOURCE_H
