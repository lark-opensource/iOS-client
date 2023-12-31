//
// Created by 黄清 on 2022/3/27.
//

#ifndef PRELOAD_VC_PLAY_RECORD_H
#define PRELOAD_VC_PLAY_RECORD_H
#pragma once

#include "vc_info.h"
#include "vc_json.h"
#include "vc_shared_mutex.h"
#include "vc_time_util.h"
#include <functional>
#include <list>
#include <unordered_map>

VC_NAMESPACE_BEGIN

class VCPlayDurationTool {
public:
    typedef uint32_t DurationMS; // ms
    typedef uint64_t Timestamp;

    VCPlayDurationTool() = default;
    ~VCPlayDurationTool() = default;

public:
    void start();
    void pause();
    void resume();
    void stop();
    DurationMS getDuration() const;

private:
    Timestamp mLastT{0};
    DurationMS mD{0};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayDurationTool);
};

class VCPlayBufferTime : public IVCPrintable {
public:
    typedef std::shared_ptr<VCPlayBufferTime> Ptr;

    typedef enum : int {
        Network = 1,
        Decode = 2,
    } Reason;

public:
    VCPlayBufferTime() = default;
    explicit VCPlayBufferTime(const VCJson &json);
    ~VCPlayBufferTime() override = default;

    std::string toString() const override;
    VCJson toJsonObject();

public:
    typedef uint64_t Timestamp;  // ms
    typedef uint32_t DurationMS; // ms

    Timestamp mStartT{0}; // ms
    Timestamp mEndT{0};   // ms
    DurationMS mDuration;
    Reason mReason{Network};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayBufferTime);
};

class VCPlayerEvent;

class VCPlayRecord : public VCInfo {
public:
    typedef std::shared_ptr<VCPlayRecord> Ptr;

    VCPlayRecord();
    explicit VCPlayRecord(const VCJson &json);
    ~VCPlayRecord() override = default;

public:
    void resetInfo() override;
    std::string toString() const override;

public:
    VCJson toJsonObject();

public:
    inline bool operator==(const VCPlayRecord &other) {
        return (this == &other) ||
               (!mTraceId.empty() ? mTraceId == other.mTraceId :
                                    mPrepareT == other.mPrepareT);
    }

private:
    friend class VCPlayerEvent;
    void prepare();
    void prepared();
    void play();
    void pause();
    void stop();
    void renderStart();
    void bufferStart(int reason);
    void bufferEnd();

public:
    std::vector<VCPlayBufferTime::Ptr> getPlayBufferTimeList();

public:
    typedef uint64_t Timestamp; // ms
    Timestamp mPrepareT{0};
    Timestamp mPreparedT{0};
    Timestamp mPlayT{0};
    Timestamp mFirstFrameT{0};
    Timestamp mFirstBufferStartT{0};
    Timestamp mFirstBufferEndT{0};

public:
    typedef uint32_t DurationMS; // ms
    DurationMS mPrepareD{0};
    DurationMS mFirstFrameD{0};
    DurationMS mPlayD{0};
    DurationMS mBufferingD{0};
    VCString mMediaId;
    VCString mSceneId;
    VCString mTraceId;
    VCString mBriefSceneId;
    VCString mAppSessionId;

private:
    shared_mutex mBufMutex;
    std::vector<VCPlayBufferTime::Ptr> mBufferInfos;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayRecord);
};

typedef std::list<VCPlayRecord::Ptr> PlayRecordList;

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

using PlayRecordClosure =
        std::function<void(int operation, const VCPlayRecord::Ptr &record)>;

class VCPlayRecordHolder final : public IVCPrintable {
public:
    enum Operation : int {
        Save = 1,
        Remove = 2
    };

    struct Scene {
        VCString mBriefSceneId;
        volatile size_t mTotalNum{0};
        volatile size_t mMaxNum{1000};
        PlayRecordList mRecords;
    };

    using PlayRecordMap = std::unordered_map<VCString, Scene>;

public:
    VCPlayRecordHolder() = default;
    ~VCPlayRecordHolder() override = default;

public:
    static const int MaxSceneCount;
    static const char * const Prefix;

    static VCString CacheKey(const VCPlayRecord::Ptr &record) {
        return string_format("%s-%s-%" PRIu64,
                             Prefix,
                             record->mMediaId.c_str(),
                             record->mPrepareT);
    }

    void setMaxNum(size_t num) {
        mCommonScene.mMaxNum = num;
    }

    void addItem(const VCPlayRecord::Ptr &record, bool isCache);
    void onRecord(const PlayRecordClosure &closure);
    PlayRecordList getRecords(VCStrCRef briefSceneId = VCString()) const;
    int getTotalRecordCount(VCStrCRef briefSceneId);

public:
    std::string toString() const override;

private:
    void _saveRecord(const VCPlayRecord::Ptr &record);
    void _removeRecord(const VCPlayRecord::Ptr &record);

private:
    mutable shared_mutex mMutex;
    Scene mCommonScene;
    PlayRecordClosure mOpClosure{nullptr};
    PlayRecordMap mRecordMap;
    PlayRecordList mWillSaveRecords;
    PlayRecordList mWillRemoveRecords;
    std::list<VCString> mBriefSceneIds;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayRecordHolder);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAY_RECORD_H
