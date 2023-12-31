//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_DAVINCIRESOURCE_H
#define DAVINCIRESOURCE_DAVINCIRESOURCE_H

#include <string>
#include <map>
#include "DAVPubDefine.h"

namespace davinci {
    namespace resource {

        class DAV_EXPORT DAVResource {
        RESOURCE_PROPERTY_DEC(DavinciResourceId, ResourceId);
        RESOURCE_PROPERTY_DEC(DavinciResourceFile, ResourceFile);

        public:
          virtual ~DAVResource() = default;

          explicit DAVResource(DavinciResourceId davinciResourceId);
          std::string toString();
        };
    }
}

#endif //DAVINCIRESOURCE_DAVINCIRESOURCE_H
