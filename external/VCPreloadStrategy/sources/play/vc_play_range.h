//
// Created by 黄清 on 2021/12/24.
//

#ifndef PRELOAD_VC_PLAY_RANGE_H
#define PRELOAD_VC_PLAY_RANGE_H
#pragma once

#include "vc_imodule.h"
#include "vc_play_range_interface.h"

#ifndef VCMODULE_PLAY_RANGE
#error "VCMODULE_PLAY_RANGE undefined, please check build configuration"
#endif

VC_NAMESPACE_BEGIN

class VCPlayRange final : public IVCModule {
public:
    VCPlayRange(IVCContext *context, IVCResultListener *listener);
    ~VCPlayRange() override = default;

public:
    void start() override;
    void stop() override;
    void receiveMessage(std::shared_ptr<VCMessage> &msg) override;

public:
    IVCPlayRange::Ptr getRangeControl();

    bool getNonBlockEnabled(VCStrCRef mediaId);

private:
    std::string mActiveName;
    std::map<std::string, std::shared_ptr<IVCPlayRange>> mStrategyMap;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayRange);
};

VC_NAMESPACE_END
#endif // PRELOAD_VC_PLAY_RANGE_H
