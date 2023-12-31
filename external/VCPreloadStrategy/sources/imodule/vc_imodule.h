//
// Created by 黄清 on 4/20/21.
//

#ifndef PRELOAD_VC_IMODULE_H
#define PRELOAD_VC_IMODULE_H
#pragma once

#include "vc_base.h"
#include "vc_context.h"
#include "vc_message.h"
#include "vc_strategy_result.h"
#include "vc_time_util.h"

#include <functional>

VC_NAMESPACE_BEGIN

typedef enum : int {
    VCRunStateInit = 0,
    VCRunStateStarted = 1,
    VCRunStateStopped = 3,
    VCRunStateError = 100,
} VCRunState;

using closure = std::function<void()>;

class MessageTaskRunner;

class IVCRunner {
public:
    virtual ~IVCRunner() {
        LOGD("~IVCRunner");
    }

    virtual void start() {
        mState = VCRunStateStarted;
    }

    virtual void stop() {
        mState = VCRunStateStopped;
    }

    virtual void setRunner(const std::shared_ptr<MessageTaskRunner> &runner) {
        mTaskRunner = runner;
    }

    VCRunState getState() const {
        return mState;
    }

protected:
    void sendTask(const closure &task);
    void postTask(const closure &task);
    void postDelayTask(const closure &task, const VCTimeDuration &duration);

protected:
    std::shared_ptr<MessageTaskRunner> mTaskRunner{nullptr};
    volatile VCRunState mState{VCRunStateInit};
};

VC_NAMESPACE_END

/// MARK: - IModule

VC_NAMESPACE_BEGIN

class VCStrategyResult;
class VCResultItem;

class IVCResultListener {
public:
    virtual void onResult(const IVCResultListener *listener,
                          const std::shared_ptr<VCStrategyResult> &result) = 0;
    virtual ~IVCResultListener(){};
};

class IVCResultItemListener {
public:
    virtual void onResult(const std::shared_ptr<VCResultItem> &item) = 0;
    virtual ~IVCResultItemListener(){};
};

class IVCModule : public IVCMessageHandle, public IVCRunner {
public:
    IVCModule(IVCContext *context, IVCResultListener *listener);
    ~IVCModule() override;

public:
    // void start() override;
    // void stop() override;

public: /// get common field
    IVCContext *getContext() const;
    IVCResultListener *getResultListener() const;

public:
    inline bool operator==(const IVCModule &o) const {
        return &o == this || o.mType == mType;
    }

public:
    /* module type.*/
    VCModuleType getModuleType() const;

protected:
    VCModuleType mType{VCModuleTypeUnknown};
    IVCContext *mContext{nullptr};
    IVCResultListener *mListener{nullptr};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(IVCModule);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_IMODULE_H
