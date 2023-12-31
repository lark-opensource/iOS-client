//
// Created by panruijie on 2021/7/1.
//

#ifndef NLE_SINGLE_RESOURCE_DOWNLOAD_CALLBACK_H
#define NLE_SINGLE_RESOURCE_DOWNLOAD_CALLBACK_H
#include <string>
#include "NLESequenceNode.h"

using namespace std;

namespace TemplateConsumer {

    class NLESingleResourceDownloadCallback {

        public:
        NLESingleResourceDownloadCallback() = default;

        virtual ~NLESingleResourceDownloadCallback() = default;
        
        virtual void onSuccess(const std::string path) = 0;

        virtual void onFailure(const int32_t code, const std::string msg) = 0;
    };

    class StdFunctionSingleResourceDownloadCallbackWrapper : public NLESingleResourceDownloadCallback {
    public:
        StdFunctionSingleResourceDownloadCallbackWrapper(
                std::function<void(std::string)> successFuc,
                std::function<void(int32_t, std::string)> failureFuc) :
                successFuc(std::move(successFuc)),
                failureFuc(std::move(failureFuc)) {}

        void onSuccess(const std::string path) override {
            successFuc(path);
        }

        void onFailure(const int32_t code, const std::string msg) override {
            failureFuc(code, msg);
        }

    private:
        std::function<void(const std::string path)> successFuc;
        std::function<void(const int32_t code, const std::string msg)> failureFuc;
    };
}
#endif //NLE_RESOURCE_DOWNLOAD_CALLBACK_H