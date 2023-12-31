//
// Created by 黄清 on 4/20/21.
//

#ifndef PRELOAD_VC_CONTEXT_H
#define PRELOAD_VC_CONTEXT_H
#pragma once

#include "vc_base.h"
#include "vc_feature_supplier.h"
#include "vc_iportrait_supplier.h"
#include "vc_loader_info.h"
#include "vc_player_info.h"
#include "vc_scene.h"
#include "vc_state_supplier.h"
#include <list>
#include <stdio.h>
#include <string>

VC_NAMESPACE_BEGIN

class IVCPlayBufferControl {
public:
    virtual ~IVCPlayBufferControl(){};

public:
    virtual bool shouldStartPlayback(VCStrCRef mediaId,
                                     int64_t bufferedDurationMs,
                                     float playbackSpeed,
                                     bool reBuffering) = 0;

    virtual int onTrackSelected(VCStrCRef mediaId, int trackType) = 0;

    virtual int onCodecStackSelected(VCStrCRef mediaId, int trackType) = 0;

    virtual int onFilterStackSelected(VCStrCRef mediaId, int trackType) = 0;
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

class VCMediaInfo;
class VCSegment;
class VCMessage;
class VCPlayerInfo;

class IVCContext {
public:
    virtual int getNetworkType() = 0;
    virtual int64_t getNetSpeedBitPerSec() = 0;
    virtual double getNetworkScore() = 0;
    /// Player
    virtual int64_t getMaxCacheSize() = 0;
    virtual int64_t getCurrentPlayerMinStartBuffer() = 0;
    virtual int getCurrentPlaybackState() = 0;
    virtual int getCurrentPlaybackPosition() = 0;
    virtual float getCurrentPlaybackSpeed() = 0;

    int64_t getCurrentPlayAudioBufferMS(bool isIgnoreMDL = false) {
        return getCurrentPlayAudioBufferMSImp(isIgnoreMDL);
    }

    virtual int64_t getCurrentPlayAudioBufferMSImp(bool isIgnoreMDL) = 0;

    int64_t getCurrentPlayVideoBufferMS(bool isIgnoreMDL = false) {
        return getCurrentPlayVideoBufferMSImp(isIgnoreMDL);
    }

    virtual int64_t getCurrentPlayVideoBufferMSImp(bool isIgnoreMDL) = 0;
    virtual int64_t getCurrentPlayAudioBufferSize() = 0;
    virtual int64_t getCurrentPlayVideoBufferSize() = 0;
    /// media duration, is millisecond.
    virtual int getCurrentPlayDuration() = 0;
    virtual VCPlayerInfo::Ptr getCurrentPlayerInfo() = 0;
    virtual VCPlayerInfo::Ptr getPlayerInfo(VCStrCRef mediaId) = 0;
    virtual std::vector<std::shared_ptr<VCSegment>>
    getCurrentPendingSegment() = 0;
    virtual int
    getIntValAtPlayer(const std::string &mediaId, int key, int dVal) = 0;
    virtual int64_t
    getInt64ValAtPlayer(const std::string &mediaId, int key, int64_t dVal) = 0;
    virtual int64_t getIOManagerInt64Value(const std::string &fileKey,
                                           int key1,
                                           int key2,
                                           int64_t dValue) = 0;

    virtual std::string getCurrentSceneId() = 0;
    virtual std::shared_ptr<VCMediaInfo>
    getMediaById(const std::string &mediaId) = 0;
    virtual std::shared_ptr<VCMediaInfo> getCurrentPlayMedia() = 0;
    virtual std::list<std::shared_ptr<VCMediaInfo>>
    getMediaList(const std::string &sceneId) = 0;
    virtual MediaInfoVector getNextMedias(const std::string &mediaId,
                                          int count) = 0;

    virtual int64_t getFileCacheSizeByKey(const std::string &fileKey) = 0;
    virtual int64_t getFileSizeByKey(const std::string &fileKey) = 0;

    virtual RepresentationMap getPredictSelectRepresentations(
            const std::shared_ptr<VCMediaInfo> &media) = 0;

    virtual RepresentationMap
    getPredictSelectRepresentations(const std::shared_ptr<VCMediaInfo> &media,
                                    const std::string sceneId) = 0;
    virtual void onBeforeSelect(const std::shared_ptr<VCMediaInfo> &mediaInfo,
                                StringValueMap &extraInfo,
                                int type,
                                IVCSelectBitrateContext::Ptr context) = 0;
    virtual void onAfterSelect(const std::shared_ptr<VCMediaInfo> &mediaInfo,
                               StringValueMap &extraInfo,
                               int type,
                               IVCSelectBitrateContext::Ptr context) = 0;

    virtual bool currentPlayIsIdle(void) = 0;
    virtual PlayRecordList getPlayRecords(VCStrCRef sceneId = VCString()) = 0;
    virtual PlayRecordList getAllPlayRecords() = 0;
    virtual int
    getIntValue(VCKey key, int dVal, VCStrCRef sceneId = VCString()) = 0;
    /// ret.nullable
    virtual VCPlayRecord::Ptr getCurrentPlayRecord() = 0;
    /// ret.nullable
    virtual VCLoaderInfo::Ptr getLoaderInfo(VCStrCRef fileHash) = 0;
    virtual LoaderInfoList getAllLoaderInfo() = 0;
    /// key is VCKeyConfigAlgoXXX
    virtual std::string getConfigString(VCKey configKey,
                                        bool isDynamic = false) = 0;

    virtual bool getMDLIsRunning() = 0;
    virtual std::string getAppSessionId() = 0;
    /// get portrait supplier
    virtual IVCPortraitSupplier &getPortraitSupplier() = 0;
    /// get feature supplier
    virtual IVCFeatureSupplier &getFeatureSupplier() = 0;

    virtual void eventLog(const std::string &id,
                          int key,
                          int value,
                          const std::string &info) = 0;

public:
    virtual ~IVCContext() {
        LOGD("~IVCContext");
    };
};

VC_NAMESPACE_END
#endif // PRELOAD_VC_CONTEXT_H
