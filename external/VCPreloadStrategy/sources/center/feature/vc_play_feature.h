//
// Created by 黄清 on 2022/9/18.
//

#ifndef PRELOAD_VCPLAYFEATURE_H
#define PRELOAD_VCPLAYFEATURE_H
#pragma once

#include "vc_feature_produce.h"
#include "vc_play_record.h"

VC_NAMESPACE_BEGIN

namespace FeatureName {
extern const char *stall_count_int;
extern const char *last_stall_distance_int;
extern const char *app_session_count_int;
extern const char *play_count_seq;
extern const char *play_count_int;
extern const char *buffer_label_int;
} // namespace FeatureName

namespace FeatureParam {
extern const char *window_duration_sec; // int
extern const char *window_size;         // int
extern const char *contain_current;     // int
extern const char *current_scene;       // int
extern const char *current_session;     // int
extern const char *last_session_count;  // int
};                                      // namespace FeatureParam

class VCManager;

class VCPlayFeature : public IVCFeatureProducer {
public:
    VCPlayFeature();
    ~VCPlayFeature() override = default;

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
    VCPlayRecordHolder &getRecordHolder() {
        return mRecordHolder;
    }

public:
    void setSerializedImp(IVCSerializedData *serializedData) override;
    void serializedDataUpdate(VCStrCRef info) override;

private:
    static int const s_max_duration_sec = 7 * 24 * 60 * 60;
    int64_t stallCount(const Dict &option) const;
    int64_t lastStallDistance(const Dict &option) const;
    void saveRecord(const std::shared_ptr<VCPlayRecord> &record);
    int sessionCount(const Dict &option) const;
    int playCount(const Dict &option) const;
    VCSeqFeature::Ptr playCountSeq(const Dict &option) const;

private:
    VCManager *mContext{nullptr};
    IVCSerializedData *mSerializedImp{nullptr};
    const std::unordered_map<
            VCString,
            std::function<int(const VCPlayFeature &, const Dict &option)>>
            mIntFeatures;
    const std::unordered_map<VCString,
                             std::function<VCFeature::Ptr(const VCPlayFeature &,
                                                          const Dict &option)>>
            mComplexFeatures;
    VCPlayRecordHolder mRecordHolder;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayFeature);
};

VC_NAMESPACE_END

#endif // PRELOAD_VCPLAYFEATURE_H
