//
//  ml_media_info.h

#ifndef ml_media_info_hpp
#define ml_media_info_hpp
#pragma once

#include <atomic>
#include <list>
#include <memory>
#include <stdio.h>
#include <string>

#include "vc_base.h"
#include "vc_define.h"
#include "vc_dubbed_audio_info.h"
#include "vc_info.h"
#include "vc_keys.h"
#include "vc_priority_task_info.h"
#include "vc_representation_info.h"

VC_NAMESPACE_BEGIN

class IVCSelectBitrate {
public:
    virtual ~IVCSelectBitrate(){};
    virtual LongValueMap selectBitrate(const std::string &mediaId,
                                       SelectBitrateType type) = 0;
};

typedef enum : int {
    PreloadTaskAdded = 1,
    PreloadTaskStart = 2,
    PreloadTaskSuccess = 3,
    PreloadTaskFail = 4,
    PreloadTaskCancel = 5,
    PreloadTaskAllUrlFailed = 6,
    PreloadTaskRemove = 7,
} PreloadTaskInfoType;

class IVCPreloadTaskCallbackListener {
public:
    virtual ~IVCPreloadTaskCallbackListener(){};
    virtual void
    preloadTaskInfo(int key, std::string info, std::string extraInfo) = 0;
};

typedef std::list<VCRepresentationInfo::Ptr> RepresentationList;
typedef std::recursive_mutex RepresentationLock;
typedef std::lock_guard<RepresentationLock> RepresentationLockGuard;
using RepresentationMap = std::map<std::string, VCRepresentationInfo::Ptr>;
typedef std::list<VCDubbedAudioInfo::Ptr> DubbedInfoList;

class VCMediaInfo : public VCInfo {
public:
    typedef std::shared_ptr<VCMediaInfo> Ptr;

public:
    VCMediaInfo() : VCInfo(VCInfoType::MediaInfo){};
    ~VCMediaInfo() override;

public:
    int setFloatValue(int key, float value) override;
    int setStrValue(int key, const std::string &value) override;
    int setIntValue(int key, int value) override;

    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;
    int getIntValue(int key, int dValue = -1) const override;
    float getFloatValue(int key, float dValue = 0.0f) const override;

    std::string toString() const override;
    void resetInfo() override;

public: /// get representation
    VCRepresentationInfo::Ptr getRepresentation(
            int bitrate,
            const std::string &mediaType = VCConstString::Stream_VIDEO) const;
    VCRepresentationInfo::Ptr
    getRepresentation(const std::string &fileHash) const;
    RepresentationList getAudioRepresentation() const;

public:
    bool playRepresentation(const std::string &fileHash);

public:
    void setSelectBitrateListener(std::shared_ptr<IVCSelectBitrate> &listener);
    std::shared_ptr<IVCSelectBitrate> getSelectBitrateListener() const;

    void setPreloadTaskCallbackListener(
            std::shared_ptr<IVCPreloadTaskCallbackListener> &callbackListener);
    std::shared_ptr<IVCPreloadTaskCallbackListener>
    getPreloadTaskCallbackListener() const;
    void setupPriorityTaskInfo();
    void triggerPriorityTaskEvent();

public:
    static Ptr MediaInfo(const std::string &jsonStr);
    VCJson toJsonValue();
    bool update(const std::string &mediaInfo);

public: /// dynamic
    int mIsPlaying{0};

public:
    std::string mFormat;   // Enum{"MP4", "DASH"}
    std::string mMediaId;  //视频的id。和Downloader内的media_id对应
    double mDuration{0.0}; //视频的长度，单位s
    int mComments{0}; //视频的评论个数 （实现时可组织成KV对）
    int mLikes{0};    //视频的点赞个数（实现时可组织成KV对）
    int mUserComment{0}; //用户在该视频的评论个数（实现时可组织成KV对）
    int mUserLike{0}; //用户在该视频的喜爱个数（实现时可组织成KV对）
    int mUserShare{0}; //用户在该视频的分享个数（实现时可组织成KV对）
    int mCategory{MediaCategoryNormal};

    /// preload task info
    std::string mBusinessContext;
    std::string mCustomPath;
    int mPreloadPriority{0};
    int64_t mPresetPreloadSize{0};
    VCPriorityTaskInfo *mPriorityTaskInfo{nullptr};

    int mEnableDubbedPreload{0};
    int64_t mDubbedPreloadSize{0};

    std::string mBusinessTag;
    std::string mBusinessSubTag;

public:
    // cache info
    int mCachedSelectBitrate{0};
    int64_t mCachedSelectSpeed{0};

    /// using info
public:
    std::atomic_int mPlayVideoBitrate{0};
    std::atomic_int mPlayAudioBitrate{0};
    int mIsPlaceholder{0};
    bool mIsDash{false};
    bool mNeedRemove{false};
    std::string mTitle;

public: /// sub media
    bool isSubMedia(void);
    int mSubIndex{-1};
    std::vector<VCMediaInfo::Ptr> getAllSubMedias(void);
    std::map<int, VCMediaInfo::Ptr> getPlayOrderSubMedias();
    VCMediaInfo::Ptr getFirstSubMedia(void);

public: /// sub media Inner Interface.
    void addSubMedia(const VCMediaInfo::Ptr &subMedia);
    void removeSubMedia(const VCMediaInfo::Ptr &subMedia);
    void removeAllSubMedias();
    std::string mFirstSubMediaId;
    int mSubListIndex;
    std::weak_ptr<VCMediaInfo> mFirstSubMedia;
    long mCDNUrlExpireTime{0};

private:
    std::shared_ptr<IVCSelectBitrate> mSelectBitrateListener{nullptr};
    std::shared_ptr<IVCPreloadTaskCallbackListener>
            mPreloadTaskCallbackListener{nullptr};
    std::vector<VCMediaInfo::Ptr> mSubMedias;

public:
    RepresentationList getRepresentations();
    VCRepresentationInfo::Ptr getRepresentationsFront();
    bool isRepresentationsEmpty();

    DubbedInfoList getDubbedInfoList();
    VCDubbedAudioInfo::Ptr getDubbedInfo(int infoId);

private:
    void setRepresentations(const RepresentationList &list);
    mutable RepresentationLock mRepresentationsLock;
    RepresentationList mRepresentationInfos;

private:
    void setDubbedInfoList(const DubbedInfoList &list);
    mutable std::mutex mDubbedInfoListMutex;
    DubbedInfoList mDubbedInfoList;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMediaInfo);
};

VC_NAMESPACE_END
#endif /* ml_media_info_hpp */
