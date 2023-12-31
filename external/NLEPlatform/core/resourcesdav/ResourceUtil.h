//
// Created by Bytedance on 2021/9/15.
//

#ifndef SMARTMOVIEDEMO_RESOURCEUTIL_H
#define SMARTMOVIEDEMO_RESOURCEUTIL_H

#if __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEResourceNode.h>
#else
#include "NLEResourceNode.h"
#endif

#include <string>

#endif //SMARTMOVIEDEMO_RESOURCEUTIL_H

namespace TemplateConsumer {

    namespace ResourceDav {

        class ResourceUtil {

            public:
            /**
            * 对于字体资源需要特殊处理
            * @param nleResourceNode
            * @param resourceFile
            */
            static void updateResourceFile(const std::shared_ptr<cut::model::NLEResourceNode> &nleResourceNode,
                                           const std::string &resourceFile);
        };
    }
}