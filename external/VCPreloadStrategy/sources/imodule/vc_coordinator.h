//
// Created by 黄清 on 4/25/21.
//

#ifndef PRELOAD_VC_COORDINATOR_H
#define PRELOAD_VC_COORDINATOR_H
#pragma once

#include "vc_base.h"
#include "vc_imodule.h"

VC_NAMESPACE_BEGIN

class VCModuleConfig;

class VCCoordinator final : public IVCModule {
public:
    VCCoordinator(IVCContext *context, IVCResultListener *listener);
    ~VCCoordinator() override;

public:
    void start() override;
    void stop() override;

    void receiveMessage(std::shared_ptr<VCMessage> &message) override;

public:
    void setConfig(VCModuleConfig *cng);

public:
    void setModules(std::list<IVCModule *> &modules);
    IVCModule *getModule(VCModuleType type);

private:
    std::list<IVCModule *> mModules;
    VCModuleConfig *mConfig{nullptr};
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_COORDINATOR_H
