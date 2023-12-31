//
//  VCVodStrategyBridge.hpp
//  VCPreloadStrategy
//
//  Created by 黄清 on 2021/7/13.
//

#ifndef VCVodStrategyBridge_hpp
#define VCVodStrategyBridge_hpp
#pragma once

#include "vc_event_listener.h"
#include "vc_state_supplier.h"
#include "vc_iportrait_supplier.h"
#import <Foundation/Foundation.h>

/// MARK: - GearStrategyContextBridge

VC_NAMESPACE_BEGIN

class GearStrategyContextBridge : public IVCSelectBitrateContext {
  public:
    explicit GearStrategyContextBridge(__strong id context);

    ~GearStrategyContextBridge() override = default;

  public:
    void *getContext() override;
    id getOCContext();

  private:
    id mContext{nil};
};

VC_NAMESPACE_END

/// MARK: - StateSupplierBridge

@protocol VCVodStrategyStateSupplier;
@class VCVodStrategyManager;
VC_NAMESPACE_BEGIN

class StateSupplierBridge : public IVCStateSupplier {
  public:
    StateSupplierBridge(__weak VCVodStrategyManager *manager,
                        __weak id<VCVodStrategyStateSupplier> supplier);
    ~StateSupplierBridge() override;

  public:
    LongValueMap userActionInfo(std::string sceneId,
                                std::string mediaId) override;
    LongValueMap selectBitrate(const std::string &mediaId, int type) override;
    LongValueMap selectBitrate(const std::string &mediaId,
                               const std::string &sceneId, int type) override;
    void onBeforeSelect(const std::string &mediaInfo, StringValueMap &extraInfo,
                        int type,
                        IVCSelectBitrateContext::Ptr context) override;
    void onAfterSelect(const std::string &mediaInfo, StringValueMap &extraInfo,
                       int type, IVCSelectBitrateContext::Ptr context) override;
    NetState getNetworkType(void) override;
    double getNetworkSpeed(void) override;
    double getNetworkScore(void) override;
  public:
    id<VCVodStrategyStateSupplier> getOCSupplier(void);

  private:
    __weak id<VCVodStrategyStateSupplier> mOCSupplier{nil};
    __weak VCVodStrategyManager *mManager{nil};
};

VC_NAMESPACE_END

/// MARK: - EventDelegateBridge

@protocol VCVodStrategyEventDelegate;
VC_NAMESPACE_BEGIN
class EventDelegateBridge : public IVCEventListener {
  public:
    EventDelegateBridge(__weak VCVodStrategyManager *manager,
                        __weak id<VCVodStrategyEventDelegate> delegate);
    ~EventDelegateBridge();

  public:
    void onEventLog(const std::string &eventName,
                    const std::string &logInfo) override;
    void onEvent(const std::string &mediaId, int key, int value,
                 const std::string &info) override;

  public:
    id<VCVodStrategyEventDelegate> getOCDelegate(void);

  private:
    __weak id<VCVodStrategyEventDelegate> mOCDelegate{nil};
    __weak VCVodStrategyManager *mManager{nil};
};

VC_NAMESPACE_END

/// MARK: - LogBridge

@protocol VCVodStrategyLogProtocol;
VC_NAMESPACE_BEGIN
class LogBridge {
  private:
    LogBridge() = delete;
    ~LogBridge() = delete;

  public:
    static void setHandle(__weak VCVodStrategyManager *manager,
                          __weak id<VCVodStrategyLogProtocol> log);

  public:
    static void log(const char *logInfo);

  private:
    static __weak id<VCVodStrategyLogProtocol> s_OCLog;
    static __weak VCVodStrategyManager *s_Manager;
};
VC_NAMESPACE_END

@protocol VCVodStrategyAppService;
VC_NAMESPACE_BEGIN
class AppServiceBridge : public IVCPortraitSupplier {
  public:
    AppServiceBridge(__weak VCVodStrategyManager *manager,
                        __weak id<VCVodStrategyAppService> service);
    ~AppServiceBridge() override;

public:
    VCJson getPortraits() override;
    VCJson getServePortraits() override;
    std::string getPortrait(VCStrCRef key) override;
    VCJson getGroupPortraits(VCStrCRef group) override;

public:
    id<VCVodStrategyAppService> getOCAppService(void);

  private:
    __weak id<VCVodStrategyAppService> mAppService{nil};
    __weak VCVodStrategyManager *mManager{nil};
};

VC_NAMESPACE_END

#endif /* VCVodStrategyBridge_hpp */
