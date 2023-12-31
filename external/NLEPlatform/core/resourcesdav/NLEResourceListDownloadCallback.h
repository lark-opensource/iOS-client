//
// Created by panruijie on 2021/7/1.
//

#ifndef NLE_RESOURCE_LIST_DOWNLOAD_CALLBACK_H
#define NLE_RESOURCE_LIST_DOWNLOAD_CALLBACK_H
#include <string>

using namespace std;

namespace TemplateConsumer {

    class NLEResourceListDownloadCallback {

        public:
        NLEResourceListDownloadCallback() = default;

        virtual ~NLEResourceListDownloadCallback() = default;

        virtual void onSuccess() = 0;

        virtual void onProgress(const float progress) = 0;

        virtual void onFailure(const int32_t code, const std::string msg) = 0;
    };

    class StdFunctionResourceListDownloadCallbackWrapper : public NLEResourceListDownloadCallback {
    public:
        StdFunctionResourceListDownloadCallbackWrapper(
                std::function<void()> successFuc,
                std::function<void(float)> progressFuc,
                std::function<void(int32_t, std::string)> failureFuc) :
                successFuc(std::move(successFuc)),
                progressFuc(std::move(progressFuc)),
                failureFuc(std::move(failureFuc)) {}

        void onSuccess() override {
            successFuc();
        }

        void onProgress(const float progress) override {
            progressFuc(progress);
        }

        void onFailure(const int32_t code, const std::string msg) override {
            failureFuc(code, msg);
        }

    private:
        std::function<void()> successFuc;
        std::function<void(const float progress)> progressFuc;
        std::function<void(const int32_t code, const std::string msg)> failureFuc;
    };
}
#endif //NLE_RESOURCE_DOWNLOAD_CALLBACK_H