//
// Created by wangchengyi.1 on 2021/5/10.
//

#ifndef DAVINCIRESOURCEDEMO_ALGORITHMCONSTANTSDEFINE_H
#define DAVINCIRESOURCEDEMO_ALGORITHMCONSTANTSDEFINE_H

#include <string>
#include "DAVPubDefine.h"

namespace davinci {
    namespace algorithm {
        class DAV_EXPORT AlgorithmConstantsDefine {
        public:
            ENUM_STR_INTERFACE(MODEL_NOT_FOUND);
            ENUM_STR_INTERFACE(MODEL_RESOURCE_URI_PREFIX);
            ENUM_STR_INTERFACE(KEY_MODEL_CACHE_DIRS);
        };
    }
}



#endif //DAVINCIRESOURCEDEMO_ALGORITHMCONSTANTSDEFINE_H
