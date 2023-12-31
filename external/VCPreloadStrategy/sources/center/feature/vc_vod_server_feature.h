//
// Created by ByteDance on 2022/10/18.
//

#ifndef VIDEOENGINE_VC_VOD_SERVER_FEATURE_H
#define VIDEOENGINE_VC_VOD_SERVER_FEATURE_H
#pragma once

#include "vc_feature_produce.h"

VC_NAMESPACE_BEGIN

namespace FeatureName {
extern const char *frequent_seek_level_factor_double;
extern const char *frequent_seek_view_factor_double;
extern const char *frequent_seek_label_int;
} // namespace FeatureName

class VCManager;

class VCSettingsFeature : public IVCFeatureProducer {
public:
    VCSettingsFeature() = default;
    ~VCSettingsFeature() override = default;

public:
    void embedContext(VCManager *context);

public:
    VCString groupId() override;
    bool containKey(VCStrCRef name) override;
    std::shared_ptr<Dict> getFeatures() override;
    VCFeature::Ptr getFeature(VCStrCRef name,
                              const Dict &option = Dict()) override;
    int getIntFeature(VCStrCRef name,
                      int dVal,
                      const Dict &option = Dict()) override;
    int64_t getInt64Feature(VCStrCRef name,
                            int64_t dVal,
                            const Dict &option = Dict()) override;
    double getDoubleFeature(VCStrCRef name,
                            double dVal,
                            const Dict &option = Dict()) override;
    void receiveMessage(std::shared_ptr<VCMessage> &msg) override;

public:
    void setSerializedImp(IVCSerializedData *serializedData) override;
    void serializedDataUpdate(VCStrCRef info) override;

private:
    bool parseSettingInfoJson(const VCJson &root);

private:
    VCManager *mContext{nullptr};
    IVCSerializedData *mSerializedImp{nullptr};
    std::vector<VCString> mKeys;

    // settings
    // frequent_seek_level_factor_double
    std::atomic<double> mFrequentSeekLevelFactor{1.0};
    // frequent_seek_view_factor_double
    std::atomic<double> mFrequentSeekViewFactor{1.0};
    // frequent_seek_label_int
    int mFrequentSeekLabel{0};
};

VC_NAMESPACE_END

#endif // VIDEOENGINE_VC_VOD_SERVER_FEATURE_H
