//
// Created by bytedance.1 on 2021/4/13.
//

#ifndef NLEPLATFORM_RESOURCE_NLERESOURCEIDPARSER_H
#define NLEPLATFORM_RESOURCE_NLERESOURCEIDPARSER_H

#include "NLEResourcePubDefine.h"
#include <string>
#include <unordered_map>
#include "nle_export.h"

namespace nle {
    namespace resource {

        class NLE_EXPORT_CLASS NLEResourceIdParser {
        public:
            explicit NLEResourceIdParser(const NLEResourceId &resourceId);

        public:
            std::string protocol, host, query;
            std::unordered_map<std::string, std::string> queryParams;
        };
    }
}


#endif //NLEPLATFORM_RESOURCE_NLERESOURCEIDPARSER_H
