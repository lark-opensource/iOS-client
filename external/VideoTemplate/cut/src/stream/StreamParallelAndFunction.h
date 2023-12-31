//
// Created by zhangyeqi on 2019-12-15.
//

#ifndef CUTSAMEAPP_STREAMPARALLELANDFUNCTION_H
#define CUTSAMEAPP_STREAMPARALLELANDFUNCTION_H

#include <cut/ComLogger.h>
#include "StreamFunction.h"
#include "StreamCallback.h"
#include <string>
#include <memory>

using asve::StreamFunction;
using asve::StreamCallback;

using namespace std::placeholders;
using std::shared_ptr;
using std::bind;
using std::string;

namespace asve {

    /**
     *
     * And : 与操作，多个 StreamFunction 都成功才成功
     * Parallel : 多个 StreamFunction 同时触发执行；需要满足 IN,OUT 参数相同
     *
     * @tparam IN IN
     * @tparam OUT OUT
     */
    template<typename IN, typename OUT>
    class StreamParallelAndFunction : public StreamFunction<IN, OUT>, public std::enable_shared_from_this<StreamParallelAndFunction<IN, OUT>> {
    public:
        StreamParallelAndFunction(vector<shared_ptr<StreamFunction<IN, OUT>>> children)
                : children(children) {
            LOGGER->d("StreamParallelAndFunction, count = %d", this->children.size());
        }

        virtual ~StreamParallelAndFunction() {
        }

    protected:
        void setContext(shared_ptr<StreamContext> streamContext) override {
            // StreamFunction::setContext(streamContext);
            this->context = streamContext;
            for (shared_ptr<StreamFunction<IN, OUT>> child : children) {
                child->setContext(streamContext);
            }
        }

        void run(IN& in) override {
            size_t size = children.size();
            std::weak_ptr<StreamParallelAndFunction> weakRef(this->shared_from_this());
            auto errorFunc = [weakRef](int errorCode, int errorSubCode, string errorMsg) {
                if (auto thisptr = weakRef.lock()) {
                    if (!thisptr->hasError) {
                        thisptr->hasError = true;
                        thisptr->notifyError(errorCode, errorSubCode, errorMsg);
                    }
                }
            };
            auto progressFunc = [weakRef] (int64_t progress) {
                if (auto thisptr = weakRef.lock()) {
                    if (!thisptr->hasError) {
                        thisptr->notifyProgress(progress);
                    }
                }
            };
            for (int32_t index = 0; index < size; index ++) {
                shared_ptr<StreamFunction<IN, OUT>> child = children[index];
                child->setCallback(make_shared<StreamCallback<OUT>>([weakRef](OUT out) {
                    if (auto thisptr = weakRef.lock()) {
                        if (!thisptr->hasError) {
                            int currentSuccessCount = ++(thisptr->successCount);
                            LOGGER->i("StreamParallelAndFunction onChildSuccess currentSuccessCount = %d",
                                      currentSuccessCount);
                            if (currentSuccessCount == thisptr->children.size()) {
                                thisptr->notifySuccess(out);
                            }
                        }
                    }
                }, errorFunc, progressFunc));
                child->dispatchRun(in);
            }
        }

        void notifySuccess(const OUT out) override {
            // StreamFunction::notifySuccess(out);
            // 一般的顺序：onProgress:MAX -> onChildSuccess; 所以这里不调用父类，不再触发一次 onProgress:MAX
            if (this->callback) {
                this->callback->onSuccess(out);
            }
        }

    private:
        void onChildSuccess(int32_t childIndex, OUT out) {
            if (!hasError) {
                int currentSuccessCount = ++successCount;
                LOGGER->i("StreamParallelAndFunction onChildSuccess currentSuccessCount = %d",
                          currentSuccessCount);
                if (currentSuccessCount == children.size()) {
                    this->notifySuccess(out);
                }
            }
        }

        void onError(int32_t childIndex, int errorCode, string errorMsg) {
            if (!hasError) {
                hasError = true;
                this->notifyError(errorCode, errorMsg);
            }
        }

        void onProgress(int32_t childIndex, int64_t progress) {
            if (!hasError) {
                this->notifyProgress(progress);
            }
        }

        vector<shared_ptr<StreamFunction<IN, OUT>>> children;
        std::atomic<int> successCount = {0};

        bool hasError = false;
    };


    template<typename IN, typename OUT>
    shared_ptr<StreamFunction<IN, OUT>> operator+(const shared_ptr<StreamFunction<IN, OUT>> &first, const shared_ptr<StreamFunction<IN, OUT>> &second) {
        vector<shared_ptr<StreamFunction<IN, OUT>>> container;
        container.push_back(first);
        container.push_back(second);
        return shared_ptr<StreamFunction<IN, OUT>>(new StreamParallelAndFunction<IN, OUT>(container));
    }

}

#endif //CUTSAMEAPP_STREAMPARALLELANDFUNCTION_H
