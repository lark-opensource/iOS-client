//
// Created by bytedance.1 on 2021/4/27.
//

#ifndef NLEPLATFORM_RESOURCE_URLRESOURCEPROTOCOL_H
#define NLEPLATFORM_RESOURCE_URLRESOURCEPROTOCOL_H

#include "NLEResourceProtocol.h"
#include <string>
#include "nle_export.h"

namespace nle {
    namespace resource {
        class NLE_EXPORT_CLASS NLEUrlResourceProtocol : public NLEResourceProtocol {
        public:
            static std::string PLATFORM_STRING();
            static std::string KEY_URL();
            static std::string EXTRA_PARAM_SAVE_PATH();
            static std::string EXTRA_PARAM_MD5();

            explicit NLEUrlResourceProtocol(std::string url);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isUrlResource(const NLEResourceId &resourceId);

        private:
            std::string httpUrl;
        };
    }
}


#endif //NLEPLATFORM_RESOURCE_URLRESOURCEPROTOCOL_H
