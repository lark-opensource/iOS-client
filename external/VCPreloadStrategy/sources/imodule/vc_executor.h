//
// Created by 黄清 on 4/20/21.
//

#ifndef PRELOAD_VC_EXECUTOR_H
#define PRELOAD_VC_EXECUTOR_H
#pragma once

#include "av_player_interface.h"
#include "vc_base.h"
#include "vc_iexecutor.h"
#include "vc_imodule.h"

VC_NAMESPACE_BEGIN

/// MARK: - VCExecutor
class MessageTaskRunner;
class VCStrategyResult;

class VCExecutor final : public IVCRunner, public IVCResultListener {
public:
    VCExecutor();
    ~VCExecutor() override;

public:
    void start() override;
    void stop() override;

public:
    void initParam(IVCContext *ctx, IVCMessageSender *msd);

public:
    void onResult(const IVCResultListener *listener,
                  const std::shared_ptr<VCStrategyResult> &result) override;
    void setIOManager(AVMDLIOManager *ioManager);
    void setPlayerManager(VCPlayerManager *manager);
    void setIOTaskListener(AVMDLIOTaskListener *listener);

public:
    friend class VCModuleFactory;
    bool addExecutor(IVCExecutor *executor);
    /// type is single value.
    IVCExecutor *getExecutor(VCModuleType type) const;

private:
    IVCContext *mContext{nullptr};
    IVCMessageSender *mMsgSender{nullptr};
    std::list<IVCExecutor *> mExecutors;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCExecutor);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_EXECUTOR_H
