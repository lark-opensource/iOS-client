//
// Created by 黄清 on 2022/9/4.
//

#ifndef PRELOAD_VC_FEATURE_RODUCE_H
#define PRELOAD_VC_FEATURE_RODUCE_H
#pragma once

#include "vc_feature.h"
#include "vc_message.h"

VC_NAMESPACE_BEGIN

class IVCSerializedData {
public:
    typedef std::shared_ptr<IVCSerializedData> Ptr;
    virtual ~IVCSerializedData(){};

public:
    virtual void saveData(VCStrCRef cacheKey, VCStrCRef info) = 0;
    virtual void removeData(VCStrCRef cacheKey) = 0;
};

class IVCFeatureProducer : public IVCMessageHandle {
public:
    typedef std::shared_ptr<IVCFeatureProducer> Ptr;
    virtual ~IVCFeatureProducer(){};

public:
    virtual VCString groupId() = 0;
    virtual bool containKey(VCStrCRef name) = 0;
    // @Nullable
    virtual VCFeature::Ptr getFeature(VCStrCRef name,
                                      const Dict &option = Dict()) = 0;
    virtual int
    getIntFeature(VCStrCRef name, int dVal, const Dict &option = Dict()) = 0;
    virtual double getDoubleFeature(VCStrCRef name,
                                    double dVal,
                                    const Dict &option = Dict()) = 0;
    virtual int64_t getInt64Feature(VCStrCRef name,
                                    int64_t dVal,
                                    const Dict &option = Dict()) = 0;
    // @Nullable
    virtual std::shared_ptr<Dict> getFeatures() = 0;

public:
    virtual void setSerializedImp(IVCSerializedData *serializedData) = 0;
    virtual void serializedDataUpdate(VCStrCRef info) = 0;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_FEATURE_RODUCE_H
