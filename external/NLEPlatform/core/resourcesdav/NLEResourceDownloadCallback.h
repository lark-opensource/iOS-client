//
// Created by panruijie on 2021/7/1.
//

#ifndef NLE_RESOURCE_DOWNLOAD_CALLBACK_H
#define NLE_RESOURCE_DOWNLOAD_CALLBACK_H
#include <string>
#include "NLESequenceNode.h"

using namespace std;

namespace TemplateConsumer {

    class NLEResourceDownloadCallback {

        public:
        NLEResourceDownloadCallback() = default;

        virtual ~NLEResourceDownloadCallback() = default;
        
        virtual void onSuccess(const shared_ptr<cut::model::NLEModel> &nleModel) = 0;

        virtual void onProgress(const float progress) = 0;

        virtual void onNeedFetch(const vector<std::string> &fetchList) = 0;

        virtual void onFailure(const int32_t code, const std::string msg) = 0;
    };

    class StdFunctionNLEModelDownloadCallbackWrapper : public NLEResourceDownloadCallback {
    public:
        StdFunctionNLEModelDownloadCallbackWrapper(
                std::function<void(const shared_ptr<cut::model::NLEModel> &)> successFuc,
                std::function<void(float)> progressFuc,
                std::function<void(int32_t, std::string)> failureFuc,
                std::function<void(const vector<std::string>&)> needFetchFuc=nullptr) :
                successFuc(std::move(successFuc)),
                progressFuc(std::move(progressFuc)),
                failureFuc(std::move(failureFuc)),
                needFetchFuc(std::move(needFetchFuc)) {}

        void onSuccess(const shared_ptr<cut::model::NLEModel> &nleModel) override {
            successFuc(nleModel);
        }

        void onProgress(const float progress) override {
            progressFuc(progress);
        }

        void onNeedFetch(const vector<std::string> &fetchList) override {
            if (needFetchFuc) {
                needFetchFuc(fetchList);
            }
        }

        void onFailure(const int32_t code, const std::string msg) override {
            failureFuc(code, msg);
        }

    private:
        std::function<void(const shared_ptr<cut::model::NLEModel> &nleModel)> successFuc;
        std::function<void(const float progress)> progressFuc;
        std::function<void(const vector<std::string>&)> needFetchFuc;
        std::function<void(const int32_t code, const std::string msg)> failureFuc;
    };
}
#endif //NLE_RESOURCE_DOWNLOAD_CALLBACK_H
