//
// Created by wangchengyi.1 on 2021/4/27.
//

#ifndef DAVINCIRESOURCEDEMO_URLRESOURCEPROTOCOL_H
#define DAVINCIRESOURCEDEMO_URLRESOURCEPROTOCOL_H

#include "DAVResourceProtocol.h"
#include <string>

namespace davinci {
    namespace resource {
        class DAV_EXPORT UrlResourceProtocol : public DAVResourceProtocol {
        public:
            ENUM_STR_INTERFACE(PLATFORM_STRING);
            ENUM_STR_INTERFACE(KEY_URL);
            ENUM_STR_INTERFACE(EXTRA_PARAM_SAVE_PATH);
            ENUM_STR_INTERFACE(EXTRA_PARAM_MD5);
            ENUM_STR_INTERFACE(EXTRA_PARAM_AUTO_UNZIP);

            explicit UrlResourceProtocol(std::string url);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isUrlResource(const DavinciResourceId &resourceId);

        private:
            std::string httpUrl;
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_URLRESOURCEPROTOCOL_H
