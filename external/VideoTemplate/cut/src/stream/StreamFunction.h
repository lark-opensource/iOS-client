//
// Created by zhangyeqi on 2019-12-02.
//

#ifndef CUTSAMEAPP_STREAMFUNCTION_H
#define CUTSAMEAPP_STREAMFUNCTION_H

#include <functional>
#include <map>
#include <string>
#include <memory>

#include "StreamCallback.h"
#include "StreamContext.h"

using asve::StreamContext;
using asve::StreamCallback;

using namespace std::placeholders;
using std::function;
using std::map;
using std::string;
using std::shared_ptr;
using std::unique_ptr;
using std::make_unique;
using std::make_shared;

namespace asve {

    /**
     *
     * StreamFunction
     *
     * @tparam IN IN
     * @tparam OUT OUT
     */
    template<typename IN, typename OUT>
    class StreamFunction {
    public:
        StreamFunction() = default;

        StreamFunction(const StreamFunction &copyOther) = delete;

        StreamFunction(const StreamFunction &&moveOther);

        StreamFunction &operator=(const StreamFunction &) = delete;

        virtual ~StreamFunction() = default;

        void dispatchRun(IN in);

        void setCallback(shared_ptr<StreamCallback<OUT>> callback);

        shared_ptr<StreamContext> getContext() const {
            return context;
        }

        template<typename A, typename B> friend class Stream;
        template<typename A, typename B> friend class StreamParallelAndFunction;
        template<typename A, typename B, typename C> friend class StreamSerialAndFunction;

    protected:

        virtual void notifySuccess(const OUT out);

        virtual void notifyError(int32_t errorCode, int32_t subErrorCode, string errorMsg);

        virtual void notifyProgress(int64_t progress);
        
        virtual void onCanceled() {};

        virtual void run(IN& in) = 0;
        virtual void setContext(shared_ptr<StreamContext> streamContext);

        shared_ptr<StreamContext> context;
        shared_ptr<StreamCallback<OUT>> callback;

    private:
        int functionIndex = -1;
    };

    template<typename IN, typename OUT>
    StreamFunction<IN, OUT>::StreamFunction(const StreamFunction &&moveOther) {
        context = moveOther.context;
        callback = moveOther.callback;
    }

    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::notifySuccess(OUT out) {
        this->notifyProgress(PROGRESS_MAX); // progress - 100%

        if (this->callback) {
            this->callback->onSuccess(out);
        }
//        unobserver context
        if (context) {
            context->removeCanceledCallback((std::uintptr_t)this);
        }
    }

    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::notifyError(int errorCode, int subErrorCode, string errorMsg) {
        if (this->callback) {
            this->callback->onError(errorCode, subErrorCode, errorMsg);
        }
//        unobserver context
        if (context) {
            context->removeCanceledCallback((std::uintptr_t)this);
        }
    }

    /**
     * @param progress [0, 1000]  0表示 0.0%，1000表示100.0%
     */
    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::notifyProgress(int64_t progress) {
        if (functionIndex >= 0) {
            progress = progress < PROGRESS_MIN ? PROGRESS_MIN : progress;
            progress = progress > PROGRESS_MAX ? PROGRESS_MAX : progress;
            this->context->updateProgress(functionIndex, progress);
            // LOGGER->i("notifyProgress, index=%d, progress=%d", functionIndex, progress);
        } else {
            // LOGGER->i("notifyProgress, xx index=%d, progress=%d", functionIndex, progress);
        }
        if (this->callback) {
            this->callback->onProgress(this->context->getProgress());
        }
    }

    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::dispatchRun(IN in) {
        if (context->isCancel()) {
            this->onCanceled();
            return;
        }
        //observer context
        if (context) {
            context->addCanceledCallback((std::uintptr_t)this, [&, this](){ onCanceled(); });
        }
        this->run(in);
    }

    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::setCallback(shared_ptr<StreamCallback<OUT>> callback) {
        this->callback = callback;
    }

    template<typename IN, typename OUT>
    void StreamFunction<IN, OUT>::setContext(shared_ptr<StreamContext> streamContext) {
        this->context = streamContext;
        if (this->functionIndex == -1) {
            this->functionIndex = this->context->streamFunctionCount;
            this->context->streamFunctionCount++;
            LOGGER->i("Function:%s index:%d", typeid(this).name(), this->functionIndex);
        }
    }
}

#endif //CUTSAMEAPP_STREAMFUNCTION_H
