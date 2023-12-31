//
//  vc_info.h

#ifndef vc_info_h
#define vc_info_h
#pragma once

#include "vc_base.h"
#include "vc_keys.h"
#include <list>
#include <memory>
#include <mutex>
#include <vector>

VC_NAMESPACE_BEGIN

typedef enum : int {
    IgnoreInfo = 0,
    MediaInfo = 1,
    LoaderInfo = 2,
    StreamInfo = 3,
    SpeedInfo = 4,
    PlayRecordInfo = 5,
    RequestInfo = 6,
    DubbedInfo = 7,
} VCInfoType;

class VCInfo : public IVCPrintable {
public:
    typedef std::shared_ptr<VCInfo> Ptr;

public:
    explicit VCInfo(int reuseType);
    ~VCInfo() override = default;

public:
    /// set
    virtual int setStrValue(int key, VCStrCRef value);
    virtual int setIntValue(int key, int value);
    virtual int setInt64Value(int key, int64_t value);
    virtual int setPtrValue(int key, intptr_t value);
    virtual int setFloatValue(int key, float value);
    /// get
    virtual VCString getStrValue(int key, VCStrCRef dValue = VCString()) const;
    virtual int getIntValue(int key, int dValue = -1) const;
    virtual int64_t getInt64Value(int key, int64_t dValue = -1) const;
    virtual intptr_t getPtrValue(int key) const;
    virtual float getFloatValue(int key, float dValue = 0.0f) const;
    /// print

    std::string toString() const override;
    /// reset
    virtual void resetInfo();

private:
    int mReuseType{0};
};

class VCMediaInfo;
class VCLoaderInfo;
class VCRepresentationInfo;
class VCPlayRecord;
class VCDubbedAudioInfo;

class VCInfoPool {
private:
    VCInfoPool();
    ~VCInfoPool();

public:
    static VCInfoPool &pool() {
        [[clang::no_destroy]] static VCInfoPool s_singleton;
        return s_singleton;
    }

public:
    void giveBack(const std::shared_ptr<VCInfo> &info);
    std::shared_ptr<VCMediaInfo> obtainMediaInfo(const std::string &mediaId);
    std::shared_ptr<VCLoaderInfo> obtainLoaderInfo(const std::string &cacheKey);
    std::shared_ptr<VCRepresentationInfo>
    obtainStreamInfo(const std::string &fileHash);
    std::shared_ptr<VCDubbedAudioInfo>
    obtainDubbedInfo(const std::string &fileHash);

public:
    std::shared_ptr<VCInfo> obtainInfo(VCInfoType type);

private:
    static const int k_media_max_size = 400;
    static const int k_loader_max_size = 50;
    static const int k_stream_max_size = 800;
    static const int k_speed_max_size = 100;
    static const int k_play_history_max_size = 20;
    static const int k_request_max_size = 500;
    static const int k_dubbed_max_size = 50;

private:
    std::vector<int> mMaxSizeList;
    std::map<int, std::list<std::shared_ptr<VCInfo>>> mPool;
    std::mutex mPoolMutex;
};

VC_NAMESPACE_END

#endif /* vc_info_h */
