//
// Created by wangchengyi.1 on 2021/4/11.
//

#ifndef DAVINCIRESOURCEDEMO_DRRESOURCEFETCHCALLBACK_H
#define DAVINCIRESOURCEDEMO_DRRESOURCEFETCHCALLBACK_H

#include <string>
#include <memory>
#include <functional>
#include "DAVPubDefine.h"

namespace davinci {
    namespace resource {
        class DAV_EXPORT DAVResourceFetchCallback {
        public:
            virtual ~DAVResourceFetchCallback() = default;

            virtual void onSuccess(std::shared_ptr<DAVResource> davinciResource) = 0;

            virtual void onError(DRResult error) = 0;

            virtual void onProgress(long progress) = 0;
        };

        class DAV_EXPORT StdFunctionDAVResourceFetchCallback : public DAVResourceFetchCallback {
        public:
            StdFunctionDAVResourceFetchCallback(std::function<void(std::shared_ptr<DAVResource>)> successFuc,
                                         std::function<void(long)> progressFuc,
                                         std::function<void(DRResult)> failFuc) : successFuc(std::move(successFuc)),
                                                                                  progressFuc(std::move(progressFuc)),
                                                                                  failFuc(std::move(failFuc)) {}

            void onSuccess(std::shared_ptr<DAVResource> davinciResource) override {
                successFuc(davinciResource);
            }

            void onError(DRResult error) override {
                failFuc(error);
            }

            void onProgress(long progress) override {
                progressFuc(progress);
            }

        private:
            std::function<void(std::shared_ptr<DAVResource> davinciResource)> successFuc;
            std::function<void(long progress)> progressFuc;
            std::function<void(DRResult error)> failFuc;
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DRRESOURCEFETCHCALLBACK_H
