//
// vc_state_supplier.h

#ifndef vc_state_supplier_h
#define vc_state_supplier_h
#pragma once

#include "vc_base.h"
#include "vc_define.h"
#include <stdio.h>

VC_NAMESPACE_BEGIN

class IVCSelectBitrateContext {
public:
    typedef std::shared_ptr<IVCSelectBitrateContext> Ptr;

public:
    virtual void *getContext() = 0;
    virtual ~IVCSelectBitrateContext(){};
};

class IVCStateSupplier {
public:
    virtual ~IVCStateSupplier(){};

public:
    virtual LongValueMap userActionInfo(std::string sceneId,
                                        std::string mediaId) = 0;
    /// map.insert(std::make_pair(VCConstString::Stream_VIDEO,videoBitrate));
    /// map.insert(std::make_pair(VCConstString::Stream_AUDIO,audioBitrate));
    virtual LongValueMap selectBitrate(const std::string &mediaId,
                                       int type) = 0;
    virtual LongValueMap selectBitrate(const std::string &mediaId,
                                       const std::string &sceneId,
                                       int type) = 0;
    virtual void onBeforeSelect(const std::string &mediaInfo,
                                StringValueMap &extraInfo,
                                int type,
                                IVCSelectBitrateContext::Ptr context) = 0;
    virtual void onAfterSelect(const std::string &mediaInfo,
                               StringValueMap &extraInfo,
                               int type,
                               IVCSelectBitrateContext::Ptr context) = 0;

public:
    virtual NetState getNetworkType() = 0;
    /// KBps
    virtual double getNetworkSpeed() = 0;
    // Mbps
    virtual double getNetworkScore() = 0;
};

VC_NAMESPACE_END
#endif /* vc_state_supplier_h */
