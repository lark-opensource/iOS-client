//
// Created by wangchengyi.1 on 2021/4/29.
//

#ifndef DAVINCIRESOURCEDEMO_DAVRESOURCECREATOR_H
#define DAVINCIRESOURCEDEMO_DAVRESOURCECREATOR_H

#include "DAVResourceManager.h"
#include "DAVPubDefine.h"
#include <memory>

namespace davinci {
    namespace resource {
        class DAV_EXPORT DAVCreator {
        public:
            static std::shared_ptr<DAVResourceManager> createDefaultResourceManager();

            static std::shared_ptr<DAVResourceTaskManager> createDefaultTaskManager();

        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DAVRESOURCECREATOR_H
