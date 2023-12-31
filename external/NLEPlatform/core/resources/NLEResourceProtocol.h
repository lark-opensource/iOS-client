//
// Created by bytedance.1 on 2021/4/8.
//

#ifndef NLE_NLERESOURCEPROTOCOL_H
#define NLE_NLERESOURCEPROTOCOL_H

#include "nle_export.h"
#include <string>
#include <unordered_map>
#include "NLEResourcePubDefine.h"

namespace nle {
    namespace resource {

#define NLE_RESOURCE_SCHEMA "urs://"

        class NLE_EXPORT_CLASS NLEResourceProtocol {

        public:

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

            virtual nle::resource::NLEResourceId toResourceId();
        };
    }
}
#endif //NLE_NLERESOURCEPROTOCOL_H
