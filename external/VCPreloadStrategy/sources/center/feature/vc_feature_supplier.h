//
// Created by 黄清 on 2022/9/4.
//

#ifndef PRELOAD_VC_FEATURE_SUPPLIER_H
#define PRELOAD_VC_FEATURE_SUPPLIER_H

#pragma once
#include "vc_feature.h"
#include "vc_feature_produce.h"
#include "vc_feature_supplier_interface.h"
#include "vc_message.h"
#include "vc_play_feature.h"
#include "vc_vod_server_feature.h"
#include <vector>

VC_NAMESPACE_BEGIN

class VCManager;

class VCFeatureSupplier :
        public IVCFeatureSupplier,
        public IVCSerializedData,
        public IVCMessageHandle,
        public IVCPrintable {
public:
    VCFeatureSupplier();
    ~VCFeatureSupplier() override = default;

public:
    IVCFeatureProducer &getPlayFeature() override;
    IVCFeatureProducer &getSettingsFeature() override;

public:
    VCFeature::Ptr getFeature(VCStrCRef name, VCStrCRef group) override;
    VCKVFeature::Ptr getKVFeature(VCStrCRef name, VCStrCRef group) override;
    VCSeqFeature::Ptr
    getSeqFeature(VCStrCRef name, VCStrCRef group, size_t num) override;

public:
    void registerProducer(IVCFeatureProducer *producer);
    void unregisterProducer(IVCFeatureProducer *producer);
    VCPlayRecordHolder &getPlayRecordHolder();
    std::string toString() const override;

public:
    void saveData(VCStrCRef cacheKey, VCStrCRef info) override;
    void removeData(VCStrCRef cacheKey) override;

public:
    void embedContext(VCManager *context);
    void loadSerializedData();
    void serializedDataUpdate(VCStrCRef info);

public:
    void receiveMessage(std::shared_ptr<VCMessage> &msg) override;

private:
    IVCFeatureProducer *getProducer(VCStrCRef groupId);

private:
    VCPlayFeature mPlayFeature;
    VCSettingsFeature mSettingsFeature;
    VCManager *mContext{nullptr};
    std::vector<IVCFeatureProducer *> mProducers;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCFeatureSupplier);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_FEATURE_SUPPLIER_H
