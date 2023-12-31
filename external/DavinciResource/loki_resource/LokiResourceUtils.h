//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_LOKIRESOURCEUTILS_H
#define DAVINCIRESOURCE_LOKIRESOURCEUTILS_H

#include <string>
#include "LokiDataModel.h"

namespace davinci {
    namespace loki {
        class LokiResourceUtils {
        public:
            static std::shared_ptr<davinci::loki::Effect>
            getEffectInfoFromExtraParams(const std::unordered_map<std::string, std::string> &extraParams);
        };
    } }


#endif //DAVINCIRESOURCE_LOKIRESOURCEUTILS_H
