//
//  vc_player_manager.h

#ifndef vc_player_manager_hpp
#define vc_player_manager_hpp

#include "av_load_control.h"
#include "av_player_interface.h"
#include "vc_base.h"
#include "vc_context.h"
#include "vc_message.h"
#include "vc_player_info.h"
#include "vc_player_option.h"
#include "vc_utils.h"

#include <atomic>
#include <map>
#include <memory>
#include <mutex>

VC_NAMESPACE_BEGIN

using IPlayer = com::ss::ttm::player::IPlayer;
using PlayerEventType = com::ss::ttm::player::PlayerEventType;
using LoadControlInterface = com::ss::ttm::player::LoadControlInterface;

class VCPlayBufferControlWrapper : public LoadControlInterface {
public:
    VCPlayBufferControlWrapper(
            VCStrCRef mediaId,
            const std::shared_ptr<IVCPlayBufferControl> &control);
    ~VCPlayBufferControlWrapper() override;

public:
    void setOriginControl(LoadControlInterface *oriControl) {
        mOriControl = oriControl;
    }

public:
    bool shouldStartPlayback(int64_t bufferedDurationMs,
                             float playbackSpeed,
                             bool reBuffering) override;
    int onTrackSelected(int trackType) override;
    int onCodecStackSelected(int trackType) override;
    int onFilterStackSelected(int trackType) override;

private:
    std::string mMediaId;
    std::shared_ptr<IVCPlayBufferControl> mControl{nullptr};
    LoadControlInterface *mOriControl{nullptr};
};

class VCPlayRecord;
class VCPlayDurationTool;

class VCPlayerEvent : public IVCPrintable {
public:
    VCPlayerEvent();
    ~VCPlayerEvent() override;

public:
    std::string toString() const override;

public:
    void prepare();
    void prepared();
    void renderStart();
    void play();
    void pause();
    void bufferStart(int reason);
    void bufferEnd();
    void stop();

public:
    std::shared_ptr<VCPlayRecord> mRecord{nullptr};
    VCPlayDurationTool mPlayDurationTool;
};

class VCPlayerItem final : public VCPlayerInfo {
public:
    typedef std::shared_ptr<VCPlayerItem> Ptr;

public:
    VCPlayerItem(const std::string &mediaId,
                 const std::string &sceneId,
                 IPlayer *player);
    VCPlayerItem() = delete;
    ~VCPlayerItem() override;

public:
    std::string getCreateSceneId();

    void setTag(VCStrCRef tag) {
        mTag = tag;
    }

    void setTraceId(VCStrCRef traceId) {
        mTraceId = traceId;
        mPlayerEvent.mRecord->mTraceId = traceId;
    }

    void setBriefSceneId(VCStrCRef briefSceneId) {
        mPlayerEvent.mRecord->mBriefSceneId = briefSceneId;
    }

    void setAppSessionId(VCStrCRef sessionId) {
        setValue(OnePlayKeySessionId, sessionId);
        mPlayerEvent.mRecord->mAppSessionId = sessionId;
    }

    IPlayer *getPlayer() {
        std::lock_guard<shared_mutex> guard(mMutex);
        return mPlayer;
    }

    void updatePlayer(IPlayer *player) {
        std::lock_guard<shared_mutex> guard(mMutex);
        mPlayer = player;
    }

    void processEventLogOnStop(void);

public:
    void
    playerEvent(PlayerEventType eventType, long eventParam, long eventCode);
    void release();

public:
    /// key is PlayerValueKey.
    int setIntValue(int key, int value);
    int setFloatValue(int key, float value);
    int setInt64Value(int key, int64_t value);
    int setStrValue(int key, const std::string &value);
    int getIntValue(int key, int dValue = -1) const;
    float getFloatValue(int key, float dValue = 0.0f) const;
    int64_t getInt64Value(int key, int64_t dValue = -1) const;
    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const;
    //
    int trySetIntValue(IPlayer *player, int key, int value);

public:
    void setBufferControl(const std::shared_ptr<IVCPlayBufferControl> &control,
                          bool check,
                          int checkOriControl);

    std::shared_ptr<IVCPlayBufferControl> getBufferControl() {
        return mBufferControl;
    }

public:
    std::shared_ptr<VCPlayRecord> getRecord() const;
    std::string toString() const override;

public:
    std::string mMediaId;
    bool mLocalFile{false};
    int mRange{0};

private:
    std::string mTraceId;
    std::string mTag;
    std::string mSceneId;
    IPlayer *mPlayer{nullptr};
    bool mReleased{false};
    std::shared_ptr<IVCPlayBufferControl> mBufferControl{nullptr};
    VCPlayerEvent mPlayerEvent;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayerItem);
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCPlayerManager final : public IVCMessageHandle {
public:
    VCPlayerManager();
    ~VCPlayerManager();

public:
    VCPlayerItem::Ptr createPlayer(IPlayer *player,
                                   const std::string &mediaId,
                                   const std::string &traceId,
                                   const std::string &sceneId,
                                   const std::string &tag);
    void addPlayerItem(const std::string &sceneId,
                       std::shared_ptr<VCPlayerItem> &copyItem);
    void releasePlayer(const std::string &mediaId,
                       const std::string &sceneId,
                       IPlayer *player = nullptr);
    void makeCurrentPlayer(const std::string &mediaId,
                           const std::string &sceneId);
    void setPlayerIntOption(IPlayer *player, int key, int value);

public:
    void setContext(IVCContext *context);
    VCPlayerItem::Ptr getCurrentPlayer();
    VCPlayerItem::Ptr getPlayer(const std::string &mediaId,
                                const std::string &sceneId);

public:
    void receiveMessage(std::shared_ptr<VCMessage> &msg) override;

private:
    typedef std::map<std::string, std::shared_ptr<VCPlayerItem>> PlayerMap;
    VCPlayerOptionHelper mOptionHelper;
    PlayerMap mPlayers;
    IVCContext *mContext{nullptr};
    std::shared_ptr<VCPlayerItem> mCurrentPlayer{nullptr};
    std::string mCurrentMediaId;
    std::string mCurrentSceneId;
    std::mutex mPlayersMutex;
    std::mutex mCurrentPlayerMutex;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayerManager);
};

VC_NAMESPACE_END

#endif /* vc_player_manager_hpp */
