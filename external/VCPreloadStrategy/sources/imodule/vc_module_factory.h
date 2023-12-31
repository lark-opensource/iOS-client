//
// Created by 黄清 on 4/22/21.
//

#ifndef PRELOAD_VC_MODULE_FACTORY_H
#define PRELOAD_VC_MODULE_FACTORY_H
#pragma once

#include "vc_base.h"
#include "vc_json.h"

VC_NAMESPACE_BEGIN

class VCModuleConfig : public IVCPrintable {
public:
    VCModuleConfig() = default;
    ~VCModuleConfig() override = default;

public:
    void assignWithJsonConfig(const std::string &jsonString,
                              const std::string &moduleJson);

public:
    std::string toString() const override;

public:
    bool mPreload{true};
    bool mABR{false};
    bool mSelectBitrate{false};
    bool mPlayLoad{false};
    bool mBandwidth{false};
    bool mPlayBuffer{false};
    bool mPlayRange{true};
    int mTimerInterval{500};
    /// ...
};

class IVCContext;
class VCModule;
class VCExecutor;

class VCModuleFactory {
private:
    VCModuleFactory() = default;
    ~VCModuleFactory() = default;

public:
    static void createModule(VCModuleConfig *config, VCModule *modules);
    static void createExecutor(VCModuleConfig *config, VCExecutor *executor);

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCModuleFactory);
};

VC_NAMESPACE_END
#endif // PRELOAD_VC_MODULE_FACTORY_H
