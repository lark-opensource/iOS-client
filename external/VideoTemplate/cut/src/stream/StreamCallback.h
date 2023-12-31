//
// Created by zhangyeqi on 2019-12-10.
//

#ifndef CUTSAMEAPP_STREAMCALLBACK_H
#define CUTSAMEAPP_STREAMCALLBACK_H

#include <memory>

using std::string;
using std::function;

namespace asve {

#define PROGRESS_MIN 0
#define PROGRESS_MAX 1000

    template<typename RESULT>
    class StreamCallback {
    public:

        StreamCallback(const function<void(RESULT)> &successCallback = nullptr,
                       const function<void(int32_t, int32_t, const string &)> &errorCallback = nullptr,
                       const function<void(int64_t)> &progressCallback = nullptr) :
                successCallback(successCallback),
                errorCallback(errorCallback),
                progressCallback(progressCallback) {}

        virtual ~StreamCallback() = default;

        virtual void onSuccess(RESULT result) {
            if (successCallback) {
                successCallback(result);
            }
        }

        virtual void onError(int32_t errorCode, int32_t subErrorCode, const string &errorMsg) {
            if (errorCallback) {
                errorCallback(errorCode, subErrorCode, errorMsg);
            }
        }

        virtual void onProgress(int64_t progress) {
            if (progressCallback) {
                progressCallback(progress);
            }
        }

    private:
        function<void(RESULT)> successCallback;
        function<void(int32_t, int32_t, const string &)> errorCallback;
        function<void(int64_t)> progressCallback;
    };
}
#endif //CUTSAMEAPP_STREAMCALLBACK_H
