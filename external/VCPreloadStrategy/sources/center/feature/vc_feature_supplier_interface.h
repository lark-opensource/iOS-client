#pragma once
#ifndef PRELOAD_VC_FEATURE_SUPPLIER_INTERFACE_H
#define PRELOAD_VC_FEATURE_SUPPLIER_INTERFACE_H

#include "vc_base.h"

VC_NAMESPACE_BEGIN

class IVCFeatureSupplier {
public:
    virtual ~IVCFeatureSupplier() = default;

    virtual IVCFeatureProducer &getPlayFeature() = 0;
    virtual IVCFeatureProducer &getSettingsFeature() = 0;

    virtual VCFeature::Ptr getFeature(VCStrCRef name, VCStrCRef group) = 0;
    virtual VCKVFeature::Ptr getKVFeature(VCStrCRef name, VCStrCRef group) = 0;
    virtual VCSeqFeature::Ptr
    getSeqFeature(VCStrCRef name, VCStrCRef group, size_t num) = 0;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_FEATURE_SUPPLIER_INTERFACE_H
