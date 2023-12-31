//
// Created by wangchengyi.1 on 2021/4/13.
//

#ifndef DAVINCIRESOURCEDEMO_DAVRESOURCEIDPARSER_H
#define DAVINCIRESOURCEDEMO_DAVRESOURCEIDPARSER_H

#include "DAVPubDefine.h"
#include <string>
#include <unordered_map>

namespace davinci {
    namespace resource {

        class DAV_EXPORT DAVResourceIdParser {
        public:
            explicit DAVResourceIdParser(const DavinciResourceId &resourceId);

        public:
            std::string protocol, host, query;
            std::unordered_map<std::string, std::string> queryParams;
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_DAVRESOURCEIDPARSER_H
