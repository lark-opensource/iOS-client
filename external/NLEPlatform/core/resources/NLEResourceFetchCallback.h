//
// Created by bytedance.1 on 2021/4/11.
//

#ifndef NLEPLATFORM_RESOURCE_RESOURCEFETCHCALLBACK_H
#define NLEPLATFORM_RESOURCE_RESOURCEFETCHCALLBACK_H

#include <string>
#include <memory>
#include "NLEResourcePubDefine.h"

namespace nle {
    namespace resource {
        class NLEResourceFetchCallback {
        public:
            virtual ~NLEResourceFetchCallback() = default;

            virtual void onSuccess(NLEResourceId nleResourceId, NLEResourceFile nleResourceFile) = 0;

            virtual void onError(NLEResult error) = 0;

            virtual void onProgress(long progress) = 0;
        };


//        class StdFunctionNLEResourceFetchCallback : public NLEResourceFetchCallback {
//        public:
//            StdFunctionNLEResourceFetchCallback(std::function<void(NLEResourceId, NLEResourceFile)> successFuc,
//                                                std::function<void(long)> progressFuc,
//                                                std::function<void(NLEResult)> failFuc) : successFuc(
//                    std::move(successFuc)),
//                                                                                          progressFuc(std::move(
//                                                                                                  progressFuc)),
//                                                                                          failFuc(std::move(failFuc)) {}
//
//            void onSuccess(NLEResourceId nleResourceId, NLEResourceFile nleResourceFile) override {
//                successFuc(nleResourceId, nleResourceFile);
//            }
//
//            void onError(NLEResult error) override {
//                failFuc(error);
//            }
//
//            void onProgress(long progress) override {
//                progressFuc(progress);
//            }
//
//        private:
//            std::function<void(NLEResourceId, NLEResourceFile)> successFuc;
//            std::function<void(long progress)> progressFuc;
//            std::function< void(NLEResult error)> failFuc;
//        };
    }
}
#endif //NLEPLATFORM_RESOURCE_RESOURCEFETCHCALLBACK_H
