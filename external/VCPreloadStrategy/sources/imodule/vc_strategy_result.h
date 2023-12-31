//
// Created by 黄清 on 4/20/21.
//

#ifndef PRELOAD_VC_STRATEGY_RESULT_H
#define PRELOAD_VC_STRATEGY_RESULT_H
#pragma once

#include "vc_base.h"
#include "vc_imodule.h"
#include <functional>
#include <list>

VC_NAMESPACE_BEGIN

/// MARK: - VCStrategyResult

class VCResultItem;
class VCMediaInfo;

using ItemClosure =
        std::function<void(const std::shared_ptr<VCResultItem> &item)>;

class VCStrategyResult final : IVCPrintable {
public:
    typedef std::shared_ptr<VCStrategyResult> Ptr;

public:
    VCStrategyResult();
    ~VCStrategyResult() noexcept override;
    explicit VCStrategyResult(const std::shared_ptr<VCResultItem> &item);

public:
    void combine(VCStrategyResult::Ptr beCombined);
    void enqueue(const std::shared_ptr<VCResultItem> &item);
    /// pop in order.
    std::shared_ptr<VCResultItem> dequeue(void);
    int itemSize(void);

    void forEach(const ItemClosure &fun);

public:
    std::string toString() const override;

private:
    VCModuleType mType{VCModuleTypeUnknown};
    uint64_t mTs{0};
    std::list<std::shared_ptr<VCResultItem>> mItems;

private:
    VC_DISALLOW_MOVE(VCStrategyResult);
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

/// MARK: - VCResultItem
class VCResultItem : public IVCPrintable {
public:
    typedef std::shared_ptr<VCResultItem> Ptr;

public:
    explicit VCResultItem(VCModuleType type);
    virtual ~VCResultItem() override;

public:
    /// return mMediaInfo.
    std::shared_ptr<VCMediaInfo> getMedia(void);
    /// return mMediaId.
    std::string getMediaId(void);

    std::string toString() const override {
        return "<VCResultItem>";
    };

    /// get module type.
    VCModuleType getType();

    /// Whether it can be converted to a message, if so, the message is
    /// currently executed
    virtual VCMessage::Ptr toMessage() {
        return nullptr;
    }

protected: /// subClass assign valid value.
    VCModuleType mType{VCModuleTypeUnknown};
    std::string mMediaId;
    std::shared_ptr<VCMediaInfo> mMediaInfo{nullptr};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCResultItem);
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCPlayLoadRetItem : public VCResultItem {
public:
    typedef std::shared_ptr<VCPlayLoadRetItem> Ptr;

public:
    VCPlayLoadRetItem(const std::string &mediaId);
    ~VCPlayLoadRetItem() override;

public:
    std::string toString() const override;
    VCMessage::Ptr toMessage() override;

public:
    std::string mFileHash;
    bool mBlockIO{false};
    int mRangeEnable{1};
    int mTargetBufferMs{-1};
    int mIODecisionType{0}; // 0: PlayLoad; 1: Preload
};

class VCPlayerRetItem : public VCResultItem {
public:
    typedef std::shared_ptr<VCPlayerRetItem> Ptr;

public:
    explicit VCPlayerRetItem(const std::string &mediaId);
    ~VCPlayerRetItem() override;

public:
    std::string toString() const override;

public:
    std::string mSceneId;
    int mOpenTimeout{15};
    int mMaxCacheSecond{30};
    int mRangeEnable{1};
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCSelectRetItem final : public VCResultItem {
public:
    typedef std::shared_ptr<VCSelectRetItem> Ptr;

public:
    VCSelectRetItem(const std::string &mediaId);
    ~VCSelectRetItem() override;

public:
    std::string toString() const override;

public:
    int64_t mSpeed{0};
    long mVideoBitrate{0};
    double mVideoCalcBitrate{0};
    long mAudioBitrate{0};
    double mAudioCalcBitrate{0};
    int mErrorCode{0};
    std::string mErrorDesc;
    int mReason{0};
    int mConfigQuality{0};
    int mUseLastNetworkSpeed{0};
    std::string mExtraInfo; // g general info; a auto bitrate info; c cache
                            // info; b best resolution info; p preload info
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCBandwidthRetItem final : public VCResultItem {
public:
    typedef std::shared_ptr<VCBandwidthRetItem> Ptr;

public:
    VCBandwidthRetItem();
    ~VCBandwidthRetItem() override;

public:
    std::string toString() const override;

public:
    float mNetworkSpeedBitPerSec{0.0f};
};

class VCPreLoadRetItem : public VCResultItem {
public:
    typedef std::shared_ptr<VCPreLoadRetItem> Ptr;

public:
    VCPreLoadRetItem(const std::string &mediaId);
    ~VCPreLoadRetItem() override;

public:
    std::string toString() const override;
    VCMessage::Ptr toMessage() override;

public:
    std::string mFileHash;
    bool mBlockIO{false};
    int mRangeEnable{1};
    int mTargetBufferMs{1};
    VCMsgWhat mOriginMessageType;
    bool mShouldPreload{false};
    bool mCancelPreload{false};
    int mDangerBufferThresholdInMs{0};
    int mSecureBufferThresholdInMs{0};
    int mSafeBandwidthInbps{0};
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_STRATEGY_RESULT_H
