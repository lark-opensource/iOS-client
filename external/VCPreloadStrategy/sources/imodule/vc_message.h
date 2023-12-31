//
// Created by 黄清 on 2/27/21.
//

#ifndef VIDEOENGINE_VC_MESSAGE_H
#define VIDEOENGINE_VC_MESSAGE_H
#pragma once

#include "vc_base.h"
#include "vc_net_simple.h"
#include "vc_object.h"
#include "vc_state_supplier.h"
#include <memory>
#include <mutex>
#include <string>
#include <vc_media_info.h>

VC_NAMESPACE_BEGIN

class VCMessage;

class IVCMessageHandle {
public:
    virtual ~IVCMessageHandle(){};
    virtual void receiveMessage(std::shared_ptr<VCMessage> &msg) = 0;
};

class IVCMessageSender {
public:
    virtual ~IVCMessageSender() {
        LOGD("~IVCMessageSender");
    };

    virtual void sendMessage(const std::shared_ptr<VCMessage> &msg) = 0;
};

typedef enum : int {
    MsgWhatIsUnknown = -1,
    /// IO
    MsgWhatIsIO = 0,
    MsgLoaderReqProgress = 1,
    MsgLoaderReqStart = 2,
    MsgLoaderReqEnd = 3,
    MsgTaskStart = 4,
    MsgTaskEnd = 5,
    MsgTaskBeginOpen = 6,
    MsgRangeStart = 7,

    /// Player
    MsgWhatIsPlayer = 1000,
    MsgPlayerPlay = 1001,
    MsgPlayerPause = 1002,
    MsgPlayerSeek = 1003,
    MsgPlayerSwitchBitrate = 1004,
    MsgPlayerBufStart = 1005,
    MsgPlayerBufEnd = 1006,
    MsgPlayerStop = 1007,
    MsgPlayerClose = 1008,
    MsgPlayerPrepare = 1009,
    MsgPlayerRenderStart = 1010,

    /// Scene
    MsgWhatIsScene = 2000,
    MsgSceneSwitch = 2001,
    MsgSceneDestroy = 2002,
    MsgMediaRefresh = 2003,
    MsgMediaUpdate = 2004,

    /// Running
    MsgWhatIsRunning = 3000,
    MsgPlayStrategyRet = 3001,
    MsgIntervalTrigger = 3002,
    MsgTargetBuffer = 3003,
    MsgPeriodChanged = 3004,

    MsgWhatIsPreload = 3200,
    MsgPreloadTaskFinished = 3201,
    MsgBlockPlayIO = 3202,
    MsgPreloadAllFinished = 3203,
    MsgNetStateChanged = 3204,

    /// Business
    MsgWhatIsBusiness = 4000,
    MsgAppState = 4001,
    MsgSmartPreloadRetUpdate = 4002,
    MsgPreloadTimelinessRetUpdate = 4003,
    MsgPreloadSmartConfigJsonUpdate = 4004,
    MsgFocusMedia = 4005,
    MsgSmartRangeRequestUpdate = 4006,
    MsgAppPreloadCancelAll = 4007,
    MsgAlgoJsonStringUpdate = 4008,
    MsgAddPriorityPreloadTask = 4009,
    MsgPeakPreloadConfigJsonUpdate = 4010,
    MsgGetNonBlockRangeEnabled = 4011,
    MsgAppCustomEvent = 4012,
    MsgSettingInfoUpdate = 4013,
    MsgRemovePriorityPreloadTask = 4015,
    MsgPriorityPreloadTaskInsertFront = 4016,
    MsgEngineGetEventLog = 4017,
    MsgEngineNetScore = 4018,

    // IO Decision
    MsgIODecisionUpdate = 4500,

    /// Select bitrate
    MsgWhatIsSelectBitrate = 5000,
    MsgGetBitrate = 5001,

    /// Bandwidth
    MsgWhatIsBandwidth = 6000,
    MsgGetBandwidth = 6002,
    MsgNetSampling = 6003,
    MsgSpeedQueueSize = 6004,

    // SmartTask
    MsgSmartTaskResult = 7000,

} VCMsgWhat;

namespace WhatUtil {
std::string WhatString(VCMsgWhat what);
}

class VCMsgArgs;
class _VCMessagePool;

class VCMessage final : public IVCPrintable {
public:
    typedef std::shared_ptr<VCMessage> Ptr;

public:
    static Ptr obtain();
    static Ptr obtain(int what);
    static Ptr obtain(int what, int arg1);
    static Ptr obtain(int what, VCModuleType targetModule);
    static Ptr obtain(int what, int arg1, int arg2);
    static Ptr obtain(int what, int arg1, int arg2, int arg3);
    static Ptr obtain(int what, const std::string &argStr);
    static Ptr obtain(int what, int arg1, int arg2, const std::string &argStr);
    static Ptr
    obtain(int what, int arg1, int arg2, int arg3, const std::string &argStr);
    static Ptr obtain(int what, const std::shared_ptr<VCMsgArgs> &args);
    static Ptr
    obtain(int what, int arg1, const std::shared_ptr<VCMsgArgs> &args);
    static Ptr obtain(int what,
                      int arg1,
                      int arg2,
                      const std::string &argStr,
                      const std::shared_ptr<VCMsgArgs> &args);
    static Ptr obtain(int what,
                      int arg1,
                      int arg2,
                      int arg3,
                      const std::string &argStr,
                      const std::shared_ptr<VCMsgArgs> &args);

public:
    static bool recycle(std::shared_ptr<VCMessage> &message);

public:
    void copyFrom(std::shared_ptr<VCMessage> &o);
    VCModuleType getTargetModuleType();

public:
    std::string toString() const override;

public:
    VCMessage() = default;

    ~VCMessage() noexcept override = default;

private:
    friend class _VCMessagePool;
    Ptr next{nullptr};

public:
    VCMsgWhat what{MsgWhatIsUnknown};
    int arg1{0};
    int arg2{0};
    int arg3{0};
    std::string argStr;
    std::shared_ptr<VCMsgArgs> args{nullptr};

private:
    VCModuleType mModuleType{VCModuleTypeAll};
    int mId{0};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMessage);
};

VC_NAMESPACE_END

/// MARK: - Message.Args

VC_NAMESPACE_BEGIN

class VCMsgArgs : public IVCPrintable {
public:
    VCMsgArgs() = default;
    virtual ~VCMsgArgs() = default;

public:
    std::string toString() const override {
        return "<base MsgArgs>";
    };

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgArgs);
};

typedef enum : int {
    VCIOTaskTypeUnknown = 0,
    VCIOTaskTypePlay = 1,
    VCIOTaskTypePreload = 2,
} VCIOTaskType;

typedef enum : int {
    VCIOTaskReadSourceUnknown = 0,
    VCIOTaskReadSourceNormalRead = 1,
    VCIOTaskReadSourcePreRead = 2,
} VCIOTaskReadSource;

class VCMsgIOArgs : public VCMsgArgs {
public:
    VCMsgIOArgs() = default;

    ~VCMsgIOArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgIOArgs");
#endif
    }

public:
    std::string mMediaId;
    std::string mFileHash;
    std::string mTaskId;
    int mIsHeader{false};
    int mUseCache{0};
    VCIOTaskReadSource mReadSource{VCIOTaskReadSourceUnknown};
    VCIOTaskType mTaskType{VCIOTaskTypeUnknown};
    int64_t mOff{0};
    int64_t mSize{0};
    int mBitrate{0};
    int64_t mJitterBufMin{0};
    std::map<std::string, std::string> mInfo;

public:
    std::string toString() const override {
        return "IOArgs: mMediaId = " + mMediaId + ", mFileHash = " + mFileHash +
               ", mTaskId = " + mTaskId +
               ", mIsHeader = " + std::to_string(mIsHeader) +
               ", mUseCache = " + std::to_string(mUseCache) +
               ", mReadSource = " + std::to_string(mReadSource) +
               ", mTaskType = " + std::to_string(mTaskType) +
               ", mOff = " + std::to_string(mOff) +
               ", mSize = " + std::to_string(mSize) +
               ", mBitrate = " + std::to_string(mBitrate) +
               ", mInfo.size = " + std::to_string(mInfo.size());
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgIOArgs);
};

class VCMsgPlayArgs : public VCMsgArgs {
public:
    VCMsgPlayArgs() = default;

    ~VCMsgPlayArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgPlayArgs");
#endif
    }

public:
    std::string mMediaId;
    std::string mSceneId;

    std::string toString() const override {
        return "PlayArgs: mediaId = " + mMediaId + ", sceneId = " + mSceneId;
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgPlayArgs);
};

class VCMsgPreloadActionArgs : public VCMsgArgs {
public:
    VCMsgPreloadActionArgs() = default;

    ~VCMsgPreloadActionArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgPreloadActionArgs");
#endif
    }

public:
    std::string mType;

    std::string mMediaId;
    std::string mFileHash;

    std::string toString() const override {
        return "PlayArgs: mediaId = " + mMediaId;
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgPreloadActionArgs);
};

class VCMsgSceneArgs : public VCMsgArgs {
public:
    VCMsgSceneArgs() = default;

    ~VCMsgSceneArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgSceneArgs");
#endif
    }

public:
    std::string mSceneId;
    std::string mAlgoParam;

    std::string toString() const override {
        return "SceneArgs: mSceneId " + mSceneId +
               ", mAlgoParam = " + mAlgoParam;
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgSceneArgs);
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCMsgSelectBitrateArgs final : public VCMsgArgs {
public:
    VCMsgSelectBitrateArgs() = default;
    ~VCMsgSelectBitrateArgs() override = default;

public:
    VCMediaInfo::Ptr mMedia{nullptr};
    SelectBitrateType mType;
    std::map<std::string, std::string> mParam;
    IVCSelectBitrateContext::Ptr mContext;

public:
    std::string toString() const override {
        return "VCMsgSelectBitrateArgs: mediaId = " +
               (mMedia != nullptr ? mMedia->mMediaId : "null") +
               ", type = " + std::to_string(mType);
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgSelectBitrateArgs);
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCMsgNetSimpleArgs final : public VCMsgArgs {
public:
    VCMsgNetSimpleArgs() = default;
    ~VCMsgNetSimpleArgs() override = default;

public:
    std::shared_ptr<VCNetSimple> mSimple;

public:
    std::string toString() const override {
        return "VCMsgNetSimpleArgs: info = " +
               (mSimple != nullptr ? mSimple->toString() : "null");
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgNetSimpleArgs);
};

class VCMsgPriorityTaskArgs final : public VCMsgArgs {
public:
    VCMsgPriorityTaskArgs() = default;
    ~VCMsgPriorityTaskArgs() = default;

public:
    VCMediaInfo::Ptr mMedia{nullptr};
    std::string mInfo;

public:
    std::string toString() const override {
        return "";
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgPriorityTaskArgs);
};

class VCMsgSettingInfoArgs final : public VCMsgArgs {
public:
    VCMsgSettingInfoArgs() = default;
    ~VCMsgSettingInfoArgs() = default;

public:
    std::string mModule;
    VCJson mJson;

public:
    std::string toString() const override {
        return "SettingInfoArgs: mModule " + mModule +
               ", mJsonString = " + mJson.dump();
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgSettingInfoArgs);
};

class VCMsgIODecisionArgs : public VCMsgArgs {
public:
    VCMsgIODecisionArgs() = default;

    ~VCMsgIODecisionArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgIODecisionArgs");
#endif
    }

public:
    std::string mMediaId;
    std::string mSceneId;
    VCMsgWhat mOriginMessageType;
    int dangerBufferThresholdInMs;
    int secureBufferThresholdInMs;
    int safeBandwidth;
    bool cancelPreload;
    bool shouldPreload;

    std::string boolToString(bool b) const {
        return b ? "true" : "false";
    }

    std::string toString() const override {
        return "PlayArgs: mediaId = " + mMediaId + ", sceneId = " + mSceneId +
               "originMessageType = " +
               WhatUtil::WhatString(mOriginMessageType) +
               ", dangerBufferThresholdInMs = " +
               ToString(dangerBufferThresholdInMs) +
               ", secureBufferThresholdInMs = " +
               ToString(secureBufferThresholdInMs) +
               ", safeBandwidth = " + ToString(safeBandwidth) +
               ", cancelPreload = " + boolToString(cancelPreload) +
               ", shouldPreload = " + boolToString(shouldPreload);
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgIODecisionArgs);
};

class VCMsgPreloadResultUpdateArgs : public VCMsgArgs {
public:
    VCMsgPreloadResultUpdateArgs() = default;

    ~VCMsgPreloadResultUpdateArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgPreloadResultUpdateArgs");
#endif
    }

public:
    std::string mMediaId;
    std::string mSceneId;
    bool mShouldPreload{false};
    bool mCancelPreload{false};
    bool mIsStartTaskEmpty{false};
    bool mIsRunningTaskEmpty{false};

    std::string boolToString(bool b) const {
        return b ? "true" : "false";
    }

    std::string toString() const override {
        return "PlayArgs: mediaId = " + mMediaId + ", sceneId = " + mSceneId +
               ", cancelPreload = " + boolToString(mCancelPreload) +
               ", shouldPreload = " + boolToString(mShouldPreload) +
               ", isStartTaskEmpty = " + boolToString(mIsStartTaskEmpty) +
               ", isRunningTaskEmpty = " + boolToString(mIsRunningTaskEmpty);
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgPreloadResultUpdateArgs);
};

typedef enum : int {
    VCSmartTaskErrTypeOK = 0,
    VCSmartTaskErrTypeDownloadFailed = 1,
    VCSmartTaskErrTypeDownloadingExist = 2,
    VCSmartTaskErrTypeDownloadRetryMax = 3,
    VCSmartTaskErrTypeTaskReachMax = 4,
    VCSmartTaskErrTypeTaskExecuteFailed = 5,
} VCSmartTaskErrorType;

class VCMsgSmartTaskResultArgs : public VCMsgArgs {
public:
    VCMsgSmartTaskResultArgs() = default;

    ~VCMsgSmartTaskResultArgs() override {
#ifdef DEBUG
        LOGD("~VCMsgSmartTaskResultArgs");
#endif
    }

public:
    int64_t timestamp{-1};
    int64_t timeConsume{-1};
    std::string businessName;
    bool isSuccess;
    std::shared_ptr<Dict> result;

    std::string toString() const override {
        return "SmartTaskResultArgs: businessName = " + businessName +
               "timestamp = " + std::to_string(timestamp) +
               "timeConsume = " + std::to_string(timeConsume) + ", isSuccess" +
               std::to_string(isSuccess);
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgSmartTaskResultArgs);
};

class VCMsgPeriodChanged : public VCMsgArgs {
public:
    VCMsgPeriodChanged() = default;

    ~VCMsgPeriodChanged() override {
#ifdef DEBUG
        LOGD("~VCMsgPeriodChanged");
#endif
    }

public:
    std::vector<VCKey> dynamicConfigKey;

    std::string toString() const override {
        return "VCMsgPeriodChanged: dynamicConfigKeySize = " +
               std::to_string(dynamicConfigKey.size());
    }

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMsgPeriodChanged);
};

VC_NAMESPACE_END

#endif // VIDEOENGINE_VC_MESSAGE_H
