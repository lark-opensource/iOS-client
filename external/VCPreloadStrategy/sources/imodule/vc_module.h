//
// Created by 黄清 on 4/22/21.
//

#ifndef PRELOAD_VC_MODULE_H
#define PRELOAD_VC_MODULE_H
#pragma once

#include "vc_base.h"
#include "vc_imodule.h"

VC_NAMESPACE_BEGIN

///
/// Api of all strategy modules
///

class VCMediaInfo;
class VCCoordinator;
class VCModuleConfig;
class IVCPlayRange;

class VCModule final : public IVCModule {
public:
    VCModule();
    ~VCModule() override;

public:
    bool addModule(IVCModule *module);
    /// type is single value.
    IVCModule *getModule(VCModuleType type) const;

    void start() override;
    void stop() override;
    void stop(bool isAppTerminate);

    void receiveMessage(std::shared_ptr<VCMessage> &message) override;

public:
    void setContext(IVCContext *ctx);
    void setListener(IVCResultListener *lst);
    void setConfig(VCModuleConfig *cng);

public: /// All modules functions.
    /// invalid value. -1
    float getNetworkSpeedBitPerSec(void) const;
    /// invalid value. map.size == 0
    LongValueMap getSelectBitrate(const VCMediaInfo::Ptr &mediaInfo,
                                  SelectBitrateType selectType,
                                  StringValueMap &param,
                                  IVCSelectBitrateContext::Ptr context);
    ///
    std::shared_ptr<IVCPlayBufferControl> getBufferControl() const;
    ///
    std::shared_ptr<IVCPlayRange> getRangeControl() const;

    bool getNonBlockRangeEnabled(VCStrCRef mediaId) const;

    std::string getPreloadStrategyLogInfo(const std::string vid) const;

private:
    std::list<IVCModule *> mModules;
    VCCoordinator *mCoordinator{nullptr};
    VCModuleConfig *mConfig{nullptr};
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_MODULE_H
