//
//  vc_scene_config.hp

#ifndef vc_scene_config_hpp
#define vc_scene_config_hpp
#pragma once

#include "vc_base.h"
#include "vc_media_info.h"
#include "vc_play_record.h"
#include "vc_shared_mutex.h"
#include <list>
#include <mutex>
#include <stdio.h>

VC_NAMESPACE_BEGIN

typedef std::list<std::shared_ptr<VCMediaInfo>> MediaInfoList;
typedef std::vector<std::shared_ptr<VCMediaInfo>> MediaInfoVector;

class VCScene {
public:
    typedef std::shared_ptr<VCScene> Ptr;
    typedef std::map<std::string, std::shared_ptr<VCMediaInfo>> Map;

private:
    class VCFileHashStorage {
    public:
        explicit VCFileHashStorage(std::string mediaId);
        ~VCFileHashStorage();

    public:
        void putFileHash(const std::string &fileHash);
        void playingInfo(const std::shared_ptr<VCMediaInfo> &mediaInfo);

    public:
        int mIsPlaying{0};

    private:
        std::string mMediaId;
        std::vector<std::string> mFileHashVec;
    };

public:
    typedef enum : int {
        Enter = 1,
        Leave = 2,
    } FocusType;

public:
    explicit VCScene(std::string sceneId);
    ~VCScene();

public:
    void setBriefSceneId(const std::string &briefSceneId);
    void setAlgorithmJsonString(std::string jsonString);
    void setAutoPlay(bool autoPlay);
    void setMute(bool mute);
    void setCardCnt(int cnt);
    void
    setFocusMediaId(const std::string &mediaId, int focusType, bool isPlay);
    void playingInfo(const std::string &mediaId, const std::string &fileHash);

public:
    int addMedia(const std::shared_ptr<VCMediaInfo> &mediaInfo);
    void addPlaceholderMedia(const std::shared_ptr<VCMediaInfo> &mediaInfo);
    void removeMedia(const std::string &mediaId);
    void removeAllMedia();
    std::shared_ptr<VCMediaInfo> getMediaInfo(const std::string &mediaId);
    MediaInfoList allMedias();
    MediaInfoVector getNextMedias(const std::string &mediaId, int count);
    std::shared_ptr<VCMediaInfo> getFocusMedia();

public:
    std::string getSceneId();
    VCString getBriefSceneId();
    std::string getAlgorithmJsonString();

#ifdef __BUILD_FOR_DY__
    int getTotalRecordCount() const {
        return mTotalRecordCount;
    }

public:
    void addRecord(const VCPlayRecord::Ptr &rd);
    PlayRecordList getRecords();
#endif

public:
    static Ptr SceneConfig(const std::string &jsonStr,
                           const std::string &algorithmJson);

private:
    std::string mSceneId;
    VCString mBriefSceneId;
    bool mAutoPlay{true};
    bool mMute{false};
    int mCardCnt{1};
    std::shared_ptr<VCMediaInfo> mFocusMedia{nullptr};
    std::string mFocusMediaId;
    std::shared_ptr<VCFileHashStorage> mMediaFileHashStorage{nullptr};
    std::string mAlgorithmJson;
    MediaInfoList mMediaList;
    Map mMediaMap;
    std::mutex mMediaListMutex;
    std::mutex mMediaIdMutex;

#ifdef __BUILD_FOR_DY__
private:
    int mRecordCount{1000};
    int mTotalRecordCount{0};
    PlayRecordList mHistory;
    shared_mutex mHistoryMutex;
#endif

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCScene);
};

VC_NAMESPACE_END

#endif /* vc_scene_config_hpp */
