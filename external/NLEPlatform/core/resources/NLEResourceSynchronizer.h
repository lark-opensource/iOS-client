//
// Created by bytedance on 2020/9/2.
//

#ifndef NLEPLATFORM_RESOURCE_RESOURCESYNCHRONIZER_H
#define NLEPLATFORM_RESOURCE_RESOURCESYNCHRONIZER_H

#include "nle_export.h"
#include <string>
#include <functional>
#include "NLEResourceFetchCallback.h"
#include "NLEResourcePubDefine.h"

namespace nle {
    namespace resource {

        class NLE_EXPORT_CLASS NLEResourceSynchronizer {
        public:
            NLEResourceSynchronizer() = default;
            virtual ~NLEResourceSynchronizer() = default;
            /**
             * @param resourceId 输入资源ID, Uri, URS .. 等等
             * @param callback 监听器
             * @return 错误码，0 表示成功发起请求
             */
            virtual int32_t fetch(const NLEResourceId& resourceId, const std::shared_ptr<NLEResourceFetchCallback>& callback) = 0;
            /**
             * @param resourceFile 输入资源文件路径, Uri, URS .. 等等
             * @param callback 监听器
             * @return 错误码，0 表示成功发起请求
             */
            virtual int32_t push(const NLEResourceFile& resourceFile, const std::shared_ptr<NLEResourceFetchCallback>& callback) = 0;
        };
    }
}

#endif //NLEPLATFORM_RESOURCE_RESOURCESYNCHRONIZER_H
