//
//  vc_strategy_center.h

#ifndef vc_strategy_center_hpp
#define vc_strategy_center_hpp
#pragma once

#include <memory>
#include <stdio.h>
#include <string>
#include <thread>
#include <vector>

#include "av_player_event_base.h"
#include "av_player_interface.h"
#include "vc_app_info.h"
#include "vc_base.h"
#include "vc_context.h"
#include "vc_device_info.h"
#include "vc_event_listener.h"
#include "vc_event_log_manager.h"
#include "vc_executor.h"
#include "vc_feature_supplier.h"
#include "vc_loader_info_handler.h"
#include "vc_media_dynamic_info.h"
#include "vc_media_info.h"
#include "vc_message.h"
#include "vc_module.h"
#include "vc_module_factory.h"
#include "vc_play_task.h"
#include "vc_player_context_wrapper.h"
#include "vc_player_manager.h"
#include "vc_portrait_supplier.h"
#include "vc_scene_manager.h"
#include "vc_smart_task_manager.h"
#include "vc_state_supplier.h"

#ifdef __TRACE__
#include "file_recorder_impl.h"
#include "http_recorder_impl.h"
#include "tracer_impl.h"
#endif

VC_NAMESPACE_BEGIN

using AVMDLStrategyCenterKey =
        com::ss::ttm::medialoader::AVMDLStrategyCenterKey;
using AVMDLIOTaskListener = com::ss::ttm::medialoader::AVMDLIOTaskListener;
using AVMDLStrategyCenterListener =
        com::ss::ttm::medialoader::AVMDLStrategyCenterListener;
using AVMDLIOTask = com::ss::ttm::medialoader::AVMDLIOTask;
using AVMDLIOTaskInfo = com::ss::ttm::medialoader::AVMDLIOTaskInfo;
using AVMDLIOManager = com::ss::ttm::medialoader::AVMDLIOManager;
using AVMDLIOManagerMDLState =
        com::ss::ttm::medialoader::AVMDLIOManagerMDLState;
using IPlayerEvent = com::ss::ttm::player::IPlayerEvent;
using PlayerEventType = com::ss::ttm::player::PlayerEventType;
using IPlayer = com::ss::ttm::player::IPlayer;

class VCPlayTask;
class VCAppInfo;
class VCSettingInfo;
class VCDeviceInfo;
class VCSmartTaskManager;

class VCManager final :
        public IVCRunner,
        public IVCContext,
        public IVCMessageSender,
        public IPlayerEvent,
        public AVMDLIOTaskListener,
        public AVMDLStrategyCenterListener {
public:
    VCManager();
    ~VCManager();

public:
    bool updateAppInfo(const std::string &infoString);
    bool updateDeviceInfo(const std::string &infoString);

public:
    void start() override;
    void stop() override;
    void stop(bool isAppTerminate);

public: /// engine
    void createPlayer(IPlayer *player,
                      const std::string &mediaId,
                      const std::string &traceId,
                      const std::string &tag);
    void releasePlayer(const std::string &mediaId, const std::string &traceId);
    void makeCurrentPlayer(const std::string &mediaId);
    void playSelection(const std::string &mediaId,
                       int videoBitrate,
                       int audioBitrate);
    void setPlayerIntOption(IPlayer *player, int key, int value);

public:
    void registerIOManager(AVMDLIOManager *ioManager, int64_t version);
    bool isIOManagerVersionMatch() const;
    int iPlayerVersion(void);

public: /// media
    void addMedia(const std::shared_ptr<VCMediaInfo> &media,
                  const std::string &sceneId,
                  bool isLast = false);
    void removeMedia(const std::string &mediaId, const std::string &sceneId);
    void removeAllMedia(std::string &sceneId, int stopTask);
    void focusMedia(const std::string &mediaId, int focusType);
    void updateMedia(const std::string &mediaId,
                     const std::string &sceneId,
                     const std::string &mediaInfo);
    MediaInfoList allMedias(const std::string &sceneId);

    void addPriorityPreloadTask(const std::shared_ptr<VCMediaInfo> &media);
    void removePriorityPreloadTask(const std::string key);

public: /// dynamic info
    void setMediaDynamicInfo(IVCMediaDynamicInfo *dynamicInfo);

public: /// device
    void setIntValue(int key, int value);
    float getFloatValue(int key, float dVal) const;
    void setStringValue(int key, const std::string &value);
    std::string getStringValue(int key, const std::string &dVal) const;
    void setFloatValue(int key, float value);
    void setInt64Value(int key, int64_t value);
    int64_t getInt64Value(int key, int64_t dVal) const;
    int64_t
    getInt64Value(int key, const std::string &strKey, int64_t dVal) const;
    void setSettingsInfo(std::string &module, std::string &jsonString);

public: /// business
    void businessEvent(int key, int value);
    void businessEvent(int key, std::string &value);
    void businessEvent(int appId, int key, int value);
    void businessEvent(int appId, int key, VCStrCRef value);

public: /// state supplier
    void setStateSupplier(IVCStateSupplier *supplier);

public: /// app server
    void setPortraitSupplier(IVCPortraitSupplier *supplier);

public: /// scene config
    void createScene(std::shared_ptr<VCScene> &config);
    void switchToScene(std::string &sceneId);
    void destroyScene(std::string &sceneId);
    void setAlgorithmJson(int key, const std::string &json);
    std::string getCommonAlgorithmJson();

public: /// event listener
    void setEventListener(IVCEventListener *listener);

public: /// start up bitrate
    LongValueMap selectBitrate(const VCMediaInfo::Ptr &media,
                               SelectBitrateType type,
                               StringValueMap &param,
                               IVCSelectBitrateContext::Ptr context);

public: ///
    int64_t getIOManagerInt64Value(const std::string &fileKey,
                                   int key1,
                                   int key2,
                                   int64_t dValue = 0) override;

public: /// Preload Manager need
    std::string getCurrentSceneId() override;
    int getNetworkType() override;
    double getNetworkScore() override;
    int64_t getNetSpeedBitPerSec() override;
    int64_t getMaxCacheSize() override;
    int64_t getCurrentPlayerMinStartBuffer() override;
    int getCurrentPlaybackState() override;
    int getCurrentPlaybackPosition() override;
    float getCurrentPlaybackSpeed() override;
    int64_t getCurrentPlayAudioBufferMSImp(bool isIgnoreMDL) override;
    int64_t getCurrentPlayVideoBufferMSImp(bool isIgnoreMDL) override;
    int64_t getCurrentPlayAudioBufferSize() override;
    int64_t getCurrentPlayVideoBufferSize() override;
    int getCurrentPlayDuration() override;

    std::shared_ptr<VCMediaInfo>
    getMediaById(const std::string &mediaId) override;
    std::shared_ptr<VCMediaInfo> getCurrentPlayMedia() override;
    VCPlayerInfo::Ptr getCurrentPlayerInfo() override;
    VCPlayerInfo::Ptr getPlayerInfo(VCStrCRef mediaId) override;
    std::list<std::shared_ptr<VCMediaInfo>>
    getMediaList(const std::string &sceneId) override;
    MediaInfoVector getNextMedias(const std::string &mediaId,
                                  int count) override;
    std::vector<std::shared_ptr<VCSegment>> getCurrentPendingSegment() override;
    int
    getIntValAtPlayer(const std::string &mediaId, int key, int dVal) override;
    int64_t getInt64ValAtPlayer(const std::string &mediaId,
                                int key,
                                int64_t dVal) override;

public: // event log
    void eventLog(const std::string &id,
                  int key,
                  int value,
                  const std::string &info) override;

    std::string getEventLog(const std::string &id);
    void removeLogData(const std::string &id);

private:
    int setIntValAtPlayer(const std::string &mediaId, int key, int val);

    friend VCPlayTask;

public:
    int64_t getFileCacheSizeByKey(const std::string &fileKey) override;
    int64_t getFileSizeByKey(const std::string &fileKey) override;

    RepresentationMap getPredictSelectRepresentations(
            const std::shared_ptr<VCMediaInfo> &media) override;

    RepresentationMap
    getPredictSelectRepresentations(const std::shared_ptr<VCMediaInfo> &media,
                                    const std::string sceneId) override;
    void onBeforeSelect(const std::shared_ptr<VCMediaInfo> &mediaInfo,
                        StringValueMap &extraInfo,
                        int type,
                        IVCSelectBitrateContext::Ptr context) override;
    void onAfterSelect(const std::shared_ptr<VCMediaInfo> &mediaInfo,
                       StringValueMap &extraInfo,
                       int type,
                       IVCSelectBitrateContext::Ptr context) override;

    bool currentPlayIsIdle(void) override;
    std::string getConfigString(VCKey configKey,
                                bool isDynamic = false) override;
    PlayRecordList getPlayRecords(VCStrCRef sceneId = VCString()) override;
    PlayRecordList getAllPlayRecords() override;
    VCLoaderInfo::Ptr getLoaderInfo(VCStrCRef fileHash) override;
    LoaderInfoList getAllLoaderInfo() override;
    int
    getIntValue(VCKey key, int dVal, VCStrCRef sceneId = VCString()) override;
    VCPlayRecord::Ptr getCurrentPlayRecord() override;
    bool getMDLIsRunning() override;
    std::string getAppSessionId() override;
    IVCPortraitSupplier &getPortraitSupplier() override;
    IVCFeatureSupplier &getFeatureSupplier() override;

public:
    void sendMessage(const std::shared_ptr<VCMessage> &msg) override;

private:
    void onPlayerEvent(IPlayer *player,
                       PlayerEventType eventType,
                       long eventParam,
                       long eventCode,
                       void *object = nullptr,
                       const char *extraInfo = nullptr) override;
    void onTaskInfo(
            IOTaskCallBack key,
            int64_t value,
            const char *param,
            AVMDLIOTask *task,
            AVMDLIOTaskInfo &info,
            std::map<std::string, std::string> *otherInfo = nullptr) override;
    void onNotify(AVMDLStrategyCenterKey key,
                  AVMDLIOTaskInfo &info,
                  AVMDLIOTask *task,
                  std::map<std::string, std::string> *otherInfo,
                  int64_t value = -1,
                  char *param = nullptr) override;

    int64_t getInt64Value(StrategyCenterInfoKey key,
                          const char *param) override;
    float getFloatValue(StrategyCenterInfoKey key, const char *param) override;
    char *getCStringValue(StrategyCenterInfoKey key,
                          const char *param) override;

private:
    void _sendEvent(const std::shared_ptr<VCMessage> &msg);

private: // Private
    void _confirmSelectBitrate(std::string &mediaId, std::string &fileHash);
    void _retainCurrentInfo(const std::string &sceneId);
    void _releasePlayer(const std::string &mediaId,
                        IPlayer *iplayer,
                        std::shared_ptr<VCPlayerItem> &player,
                        int event,
                        int eventParam);
    void _configVideoHardware(int eventCode,
                              IPlayer *iplayer,
                              const std::shared_ptr<VCPlayerItem> &player);
    void _startThread(void);
    void _stopThread(void);
    void _intervalTrigger(int intervalMilliSecond);
    void _algoJsonNotify();
    RepresentationMap _selectReps(const std::shared_ptr<VCMediaInfo> &media,
                                  VCStrCRef sceneId,
                                  bool useSceneId);

private:
    VCModule mModuleCenter;
    VCModuleConfig mModuleConfig;
    VCExecutor mExecutor;
    VCPlayerManager mPlayerManager;
    VCSceneManager mSceneManager;
    VCSmartTaskManager mSmartTaskManager;
    VCLoaderInfoHandler mLoadHandler;
    VCPlayTask mPlayTask;
    VCAppInfo mAppInfo;
    VCDeviceInfo mDeviceInfo;
    VCSettingInfo mSettingInfo;
    VCPortraitSupplier mPortraitSupplier;
    VCPlayerContextWrapper mSupperPlayerContext;
    VCFeatureSupplier mFeatureSupplier;
    IVCMediaDynamicInfo *mDynamicInfo{nullptr};
    IVCEventListener *mEventListener{nullptr};
    AVMDLIOManager *mIOManager{nullptr};
    int mIOManagerVersion{0};
    IVCStateSupplier *mStateSupplier{nullptr};
    AVMDLIOManagerMDLState mMDLState;
    VCEventLogManager mEventLogManager;

private:
    std::thread mThread;
#if defined(__ANDROID__)
    bool mAttachEnv{};
#endif

    TRACE_CODE(HttpRecorderImpl *mEventHttpRecorder;)
    TRACE_CODE(FileRecorderImpl *mEventFileRecorder;)
    TRACE_CODE(SpanMap mIOTaskSpan;)
private:
    friend class VCPlayFeature;
};

VC_NAMESPACE_END

#endif /* vc_strategy_center_hpp */
