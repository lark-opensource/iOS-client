//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_LOKIRESOURCE_H
#define DAVINCIRESOURCE_LOKIRESOURCE_H

#include "DAVResourceProtocol.h"
#include <string>

namespace davinci {
    namespace loki {
        class DAV_EXPORT LokiResourceProtocol : public davinci::resource::DAVResourceProtocol {
        public:
            ENUM_STR_INTERFACE(PLATFORM_STRING);
            ENUM_STR_INTERFACE(PARAM_EFFECT_ID);
            ENUM_STR_INTERFACE(PARAM_RESOURCE_ID);
            ENUM_STR_INTERFACE(PARAM_PANEL);

            explicit LokiResourceProtocol(std::string effectId);

            LokiResourceProtocol(std::string resourceId, std::string panel);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isLokiResource(const davinci::resource::DavinciResourceId &resourceId);

        private:
            std::string effectId;
            std::string resourceId;
            std::string panel;
        };
    }
}

#endif //DAVINCIRESOURCE_LOKIRESOURCE_H
