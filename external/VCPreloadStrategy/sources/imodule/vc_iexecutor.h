//
// Created by 黄清 on 5/1/21.
//

#ifndef PRELOAD_VC_IEXECUTOR_H
#define PRELOAD_VC_IEXECUTOR_H
#pragma once

#include "av_player_interface.h"
#include "vc_base.h"
#include "vc_imodule.h"
#if __has_include(<MDLMediaDataLoader/AVMDLIOManager.h>)
#include <MDLMediaDataLoader/AVMDLIOManager.h>
#else
#include "AVMDLIOManager.h"
#endif

VC_NAMESPACE_BEGIN

using AVMDLIOManager = com::ss::ttm::medialoader::AVMDLIOManager;
using AVMDLIOTaskListener = com::ss::ttm::medialoader::AVMDLIOTaskListener;
using IPlayer = com::ss::ttm::player::IPlayer;

class VCPlayerManager;
class MessageTaskRunner;

class IVCExecutor : public IVCResultItemListener, public IVCRunner {
public:
    IVCExecutor(VCModuleType type, IVCContext &ctx, IVCMessageSender &msd);
    ~IVCExecutor() override;

public:
    virtual void setIOManager(AVMDLIOManager *ioManager);
    virtual void setIOTaskListener(AVMDLIOTaskListener *listener);
    virtual void setPlayerManager(VCPlayerManager *playerManager);
    void setRunner(const std::shared_ptr<MessageTaskRunner> &runner) override;
    void onResult(const std::shared_ptr<VCResultItem> &item) override;
    VCModuleType getType() const;

public:
    inline bool operator==(const IVCExecutor &o) {
        return &o == this || o.mType == mType;
    }

protected:
    VCModuleType mType;
    AVMDLIOManager *mIOManager{nullptr};
    AVMDLIOTaskListener *mIOTaskListener{nullptr};
    IVCContext &mContext;
    IVCMessageSender &mMsgSender;
    VCPlayerManager *mPlayerManager{nullptr};
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_IEXECUTOR_H
