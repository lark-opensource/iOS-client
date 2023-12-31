//
// Created by wangchengyi.1 on 2021/4/8.
//

#ifndef DAVINCIRESOURCEDEMO_DAVRESOURCEPROTOCOL_H
#define DAVINCIRESOURCEDEMO_DAVRESOURCEPROTOCOL_H

#include <string>
#include <unordered_map>
#include "DAVResource.h"
#include "DAVPubDefine.h"

namespace davinci {
    namespace resource {

#define DAVINCI_RESOURCE_SCHEMA "urs://"

        class DAV_EXPORT DAVResourceProtocol {

        public:
            virtual ~DAVResourceProtocol() = default;
            
            /**
             * The platform source of the resource.
             * @return
             */
            virtual std::string getSourceFrom() = 0;

            /**
             * The parameters to identify the unique resource.
             * @return
             */
            virtual std::unordered_map<std::string, std::string> getParameters() = 0;

            virtual davinci::resource::DavinciResourceId toResourceId();
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DAVRESOURCEPROTOCOL_H
