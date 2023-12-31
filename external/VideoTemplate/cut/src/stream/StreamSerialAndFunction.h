//
// Created by zhangyeqi on 2019-12-10.
//

#ifndef CUTSAMEAPP_STREAMSERIALANDFUNCTION_H
#define CUTSAMEAPP_STREAMSERIALANDFUNCTION_H

#include "StreamFunction.h"
#include "StreamCallback.h"

using asve::StreamFunction;
using asve::StreamCallback;

using std::shared_ptr;
using std::bind;

namespace asve {

    /**
     *
     * And : 与操作，多个 StreamFunction 都成功才成功
     * Serial : 多个 StreamFunction 串行执行，前一个成功后才会触发下一个执行
     *
     * @tparam IN IN
     * @tparam ANY ANY
     * @tparam OUT OUT
     */
    template<typename IN, typename ANY, typename OUT>
    class StreamSerialAndFunction : public StreamFunction<IN, OUT>, public std::enable_shared_from_this<StreamSerialAndFunction<IN, ANY, OUT>> {
    public:
        StreamSerialAndFunction(shared_ptr<StreamFunction<IN, ANY>> first,
                              shared_ptr<StreamFunction<ANY, OUT>> second) : first(first),
                                                                             second(second) {
        }

        void run(IN& in) override {
            std::weak_ptr<StreamSerialAndFunction> weakRef(this->shared_from_this());
            auto errorFunc = [weakRef](int errorCode, int subErrorCode, string errorMsg) {
                if (auto thisptr = weakRef.lock()) {
                    thisptr->notifyError(errorCode, subErrorCode, errorMsg);
                }
            };
            auto progressFunc = [weakRef] (int64_t progress) {
                if (auto thisptr = weakRef.lock()) {
                    thisptr->notifyProgress(progress);
                }
            };
            first->setCallback(make_shared<StreamCallback<ANY>>([weakRef](ANY any){
                if (auto thisptr = weakRef.lock()) {
                    thisptr->hasFirstResult = true;
                    thisptr->any = any;
                    thisptr->latch.countDown();
                }
            }, errorFunc, progressFunc));
            first->dispatchRun(in);

            latch.wait();

            if (this->hasFirstResult) {
                second->setCallback(make_shared<StreamCallback<OUT>>(
                [weakRef](OUT out){
                    if (auto thisptr = weakRef.lock()) {
                        thisptr->notifySuccess(out);
                    }
                }, errorFunc, progressFunc));
                second->dispatchRun(this->any);
            }
        }

    protected:
        void setContext(shared_ptr<StreamContext> streamContext) override {
            // StreamFunction::setContext(streamContext);
            this->context = streamContext;
            first->setContext(streamContext);
            second->setContext(streamContext);
        }

        void notifySuccess(const OUT out) override {
            // StreamFunction::notifySuccess(out);
            // 一般的顺序：onProgress:MAX -> onChildSuccess; 所以这里不调用父类，不再触发一次 onProgress:MAX
            if (this->callback) {
                this->callback->onSuccess(out);
            }
        }

    private:
        void firstSuccess(ANY any) {
            this->hasFirstResult = true;
            this->any = any;
            this->latch.countDown();
        }

        void secondSuccess(OUT out) {
            this->notifySuccess(out);
        }

        void onError(int errorCode, string errorMsg) {
            this->notifyError(errorCode, errorMsg);
        }

        void onProgress(int32_t childIndex, int64_t progress) {
            this->notifyProgress(progress);
        }

        shared_ptr<StreamFunction<IN, ANY>> first;
        shared_ptr<StreamFunction<ANY, OUT>> second;

        bool hasFirstResult = false;
        ANY any;
        asve::CountDownLatch latch{1};
    };

}
#endif //CUTSAMEAPP_STREAMSERIALANDFUNCTION_H
