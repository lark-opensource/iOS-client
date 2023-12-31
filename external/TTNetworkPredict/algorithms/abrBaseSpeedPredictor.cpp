//
// Created by bytedance on 2021/6/4.
//

#include "abrBaseSpeedPredictor.h"
#include <math.h>
#include <algorithm>
#include <pthread.h>
#if defined(__APPLE__)
#include <sys/types.h>
#endif

NETWORKPREDICT_NAMESPACE_BEGIN

abrBaseSpeedPredictor::abrBaseSpeedPredictor():
mBandwidthSlidingWindowSize(20)
,mLastVideoDownloadSpeed(-1.0f)
,mLastAudioDownloadSpeed(-1.0f)
,mLastVideoDownloadSize(0)
,mLastAudioDownloadSize(0)
,mLastVideoDownloadTime(-1)
,mLastAudioDownloadTime(-1)
,mLastVideoRTT(-1)
,mLastAudioRTT(-1)
,mLastVideoLastDataRecv(0)
,mLastAudioLastDataRecv(0)
,mVideoCurrentStreamId("-1")
,mAudioCurrentStreamId("-1")
,mVideoMDLLoaderType("-1")
,mAudioMDLLoaderType("-1")
,mPredictedVideoBandwidth(-1.0f)
,mPredictedAudioBandwidth(-1.0f)
,mPredictConfidence(-1.0f)
,mVideoCallCount(0)
,mAudioCallCount(0)
,mVideoAvgSpeed(0.0f)
,mAudioAvgSpeed(0.0f)
,mVideoAvgWindowSpeed(0.0f)
,mAudioAvgWindowSpeed(0.0f)
,mStartupWindowSize(STARTUP_WINDOWSIZE)
,mEMAWeight(EMA_WEIGHT)
,mEMAVideoSpeed(0.0f)
,mEMAAudioSpeed(0.0f)
,mEMAVideoStartupEndSpeed(0.0f)
,mEMAAudioStartupEndSpeed(0.0f)
,mEMAVideoStartupSpeed(0.0f)
,mEMAAudioStartupSpeed(0.0f)
,mOpenNetworkSpeedOptimize(false)
,mCostTimeFilterValue(1000)
,mConfBasedPredict(0)
,mConfBasedPredSpeed(-1.0f)
{
    mRecentVideoBandwidth.clear();
    mRecentAudioBandwidth.clear();
    mRecentVideoTimestamp.clear();
    mRecentAudioTimestamp.clear();
    mMultidimensionalPredictSpeed.clear();
    mMultidimensionalDownloadSpeed.clear();
    mExistedMultidimensionalInfo.clear();
    mVideoStartupSpeed.clear();
    mAudioStartupSpeed.clear();
    mStartupWindowSize = mStartupWindowSize > mBandwidthSlidingWindowSize ?
                         mBandwidthSlidingWindowSize : mStartupWindowSize;
    mRecentAccuracy.clear();
    mRecentConfSpeed.clear();
    mRecentConfTimestamp.clear();
    pthread_rwlock_init(&mLock, nullptr);
}

abrBaseSpeedPredictor::~abrBaseSpeedPredictor() {
    pthread_rwlock_destroy(&mLock);
}

float abrBaseSpeedPredictor::getPredictSpeed(int media_type) {
    if (! mConfBasedPredict) {
        if (mRecentVideoBandwidth.size() > 0) {
            mPredictConfidence = 1.0f;
        } else {
            mPredictConfidence = 0.0f;
        }
    }
    if (media_type == VIDEO_TYPE) {
        return mPredictedVideoBandwidth;
    } else if (media_type == AUDIO_TYPE) {
        return mPredictedAudioBandwidth;
    } else {
        float invalid_predict_speed = -1.0;
        return invalid_predict_speed;
    }
}
std::map<std::string, std::string> abrBaseSpeedPredictor::getDownloadSpeed(int media_type) {
    std::map<std::string, std::string> result;
    char buf[256];
    float download_speed = -1.0f;
    uint64_t download_size = 0;
    int64_t download_time = -1;
    int64_t rtt = -1;
    int64_t last_data_recv = -1;
    if (media_type == VIDEO_TYPE) {
        download_speed = mLastVideoDownloadSpeed;
        if (pthread_rwlock_tryrdlock(&mLock) == 0) {
            result["stream_id"] = mVideoCurrentStreamId;
            result["mdl_loader_type"] = mVideoMDLLoaderType;
            download_size = mLastVideoDownloadSize;
            download_time = mLastVideoDownloadTime;
            rtt = mLastVideoRTT;
            last_data_recv = mLastVideoLastDataRecv;

            pthread_rwlock_unlock(&mLock);
        }
    } else if (media_type == AUDIO_TYPE) {
        download_speed = mLastAudioDownloadSpeed;
        if (pthread_rwlock_tryrdlock(&mLock) == 0) {
            result["stream_id"] = mAudioCurrentStreamId;
            result["mdl_loader_type"] = mAudioMDLLoaderType;
            download_size = mLastAudioDownloadSize;
            download_time = mLastAudioDownloadTime;
            rtt = mLastAudioRTT;
            last_data_recv = mLastAudioLastDataRecv;
            pthread_rwlock_unlock(&mLock);
        }
    }

    snprintf(buf, 256, "%f", download_speed);
    result["download_speed"] = buf;
    snprintf(buf, 256, "%" PRIu64, download_size);
    result["download_size"] = buf;
    snprintf(buf, 256, "%" PRId64, download_time);
    result["download_time"] = buf;
    snprintf(buf, 256, "%" PRId64, rtt);
    result["rtt"] = buf;
    snprintf(buf, 256, "%" PRId64, last_data_recv);
    result["last_data_recv"] = buf;
    return result;
}

NetworkSpeedResultVec abrBaseSpeedPredictor::getMultidimensionalDownloadSpeeds() {
    return mMultidimensionalDownloadSpeed;
}

NetworkSpeedResultVec abrBaseSpeedPredictor::getMultidimensionalPredictSpeeds() {
    return mMultidimensionalPredictSpeed;
}

float abrBaseSpeedPredictor::getLastPredictConfidence() {
    return mPredictConfidence;
}

// Summary: Returns an average speed for the last video view.
// Parameters:
//      speed_type: The average speed calculation method.
//      trigger: Whether clear the historic speed records and update EMA-related speed or not.
//          If the preload bitrate selector is calling this function, "trigger" should be false.
//          If the startup bitrate selector is calling this function, "trigger" should be true.
float abrBaseSpeedPredictor::getAverageDownloadSpeed(int media_type, int speed_type, bool trigger) {
    float ret = -1.0f;
    if (media_type == VIDEO_TYPE) {
        if (trigger) {
            updateMediaAverageDownloadSpeed(mEMAWeight, mStartupWindowSize,
                                            mRecentVideoBandwidth,
                                            mVideoStartupSpeed,
                                            mVideoCallCount,
                                            mVideoAvgSpeed,
                                            mVideoAvgWindowSpeed,
                                            mEMAVideoSpeed,
                                            mEMAVideoStartupSpeed,
                                            mEMAVideoStartupEndSpeed);
        }
        ret = getMediaAverageDownloadSpeed(speed_type,
                                           mVideoAvgSpeed,
                                           mVideoAvgWindowSpeed,
                                           mEMAVideoSpeed,
                                           mEMAVideoStartupSpeed,
                                           mEMAVideoStartupEndSpeed);
        if (trigger) {
            resetMediaAverageDownloadSpeed(mVideoAvgSpeed, mVideoCallCount, mVideoStartupSpeed);
        }
    } else if (media_type == AUDIO_TYPE) {
        if (trigger) {
            updateMediaAverageDownloadSpeed(mEMAWeight, mStartupWindowSize,
                                            mRecentAudioBandwidth,
                                            mAudioStartupSpeed,
                                            mAudioCallCount,
                                            mAudioAvgSpeed,
                                            mAudioAvgWindowSpeed,
                                            mEMAAudioSpeed,
                                            mEMAAudioStartupSpeed,
                                            mEMAAudioStartupEndSpeed);
        }
        ret = getMediaAverageDownloadSpeed(speed_type,
                                           mAudioAvgSpeed,
                                           mAudioAvgWindowSpeed,
                                           mEMAAudioSpeed,
                                           mEMAAudioStartupSpeed,
                                           mEMAAudioStartupEndSpeed);

        if (trigger) {
            resetMediaAverageDownloadSpeed(mAudioAvgSpeed, mAudioCallCount, mAudioStartupSpeed);
        }

    }
    return ret;
}

void abrBaseSpeedPredictor::updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) {
    if (!speedRecord)
        return;
    bool preload = false;
    auto media_info_item = mediaInfo.find(speedRecord->streamId);
    if (media_info_item == mediaInfo.end()) {
        preload = true;
    }
    int64_t last_data_recv = speedRecord->lastDataRecv;
    int64_t cost_time = speedRecord->time; //ms
    cost_time = cost_time > last_data_recv && last_data_recv > 0 ? cost_time - last_data_recv : cost_time;
    float download_speed = cost_time > 0 ? (static_cast<float>(speedRecord->bytes) * BYTE_IN_B * M_IN_K /
            static_cast<float>(cost_time)) : 0.0f; // bps
    int trackType = speedRecord->trackType;

    // Confidence based speed prediction
    std::shared_ptr<SpeedRecordItem> speedRecordNew = std::make_shared<SpeedRecordItem>(speedRecord);
    int buffer = mediaInfo["playerVideoBufLen"];
    int maxBuffer = mediaInfo["playerVideoMaxBufLen"];
    SpeedInfo speedInfo(download_speed, false, buffer, maxBuffer, speedRecordNew);
    if (mConfBasedPredict)
        mConfBasedPredSpeed = confBasedBandwidthPredict(speedInfo);
    if (trackType == VIDEO_TYPE) {
        if (pthread_rwlock_trywrlock(&mLock) == 0) {
            if (!speedRecord->streamId.empty())
                mVideoCurrentStreamId = speedRecord->streamId.c_str();
            else
                mVideoCurrentStreamId = "-1";
            if (!speedRecord->mdlLoaderType.empty())
                mVideoMDLLoaderType = speedRecord->mdlLoaderType.c_str();
            else
                mVideoMDLLoaderType = "-1";
            mLastVideoDownloadSpeed = download_speed;
            mLastVideoDownloadSize = speedRecord->bytes;
            mLastVideoDownloadTime = cost_time;
            mLastVideoRTT = speedRecord->rtt;
            mLastVideoLastDataRecv = speedRecord->lastDataRecv;

            pthread_rwlock_unlock(&mLock);
        }
        if (download_speed > MINIMUM_SPEED && download_speed < MAXIMUM_SPEED) {
            if (!mOpenNetworkSpeedOptimize || (mOpenNetworkSpeedOptimize && cost_time <= mCostTimeFilterValue)) {
                float instantBandwidth = download_speed;
                mRecentVideoBandwidth.push_back(instantBandwidth);
                mRecentVideoTimestamp.push_back(speedRecord->timestamp);
                if (mRecentVideoBandwidth.size() > mBandwidthSlidingWindowSize) {
                    auto k = mRecentVideoBandwidth.begin();
                    mRecentVideoBandwidth.erase(k);
                }
                if (mRecentVideoTimestamp.size() > mBandwidthSlidingWindowSize) {
                    auto k = mRecentVideoTimestamp.begin();
                    mRecentVideoTimestamp.erase(k);
                }
            }
            updateMediaDownloadSpeedInfo(mRecentVideoBandwidth, download_speed, mStartupWindowSize,
                                         mVideoAvgSpeed, mVideoAvgWindowSpeed,
                                         mVideoCallCount, mVideoStartupSpeed);
        }
        if (! mConfBasedPredict)
            mPredictedVideoBandwidth = predictBandwidth(VIDEO_TYPE);
        else
            mPredictedVideoBandwidth = mConfBasedPredSpeed;

        LOGD("[SelectorLog] mediaType:%d download_speed:%.2f predict_speed:%.2f conf_predict_speed:%.2f conf:%.2f cost_time:%" PRId64
                     " bytes:%" PRIu64 " timestamp:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64
                     " mdlLoaderType:%s s_off:%" PRId64 " e_off:%" PRId64 " cbs:%" PRId64 " fbs:%" PRId64,
             trackType, download_speed, mPredictedVideoBandwidth, mConfBasedPredSpeed, mPredictConfidence, cost_time,
             speedRecord->bytes, speedRecord->timestamp, speedRecord->rtt, last_data_recv,
             mVideoMDLLoaderType.c_str(), speedRecord->s_off, speedRecord->e_off, speedRecord->cbs, speedRecord->fbs);
    } else if (trackType == AUDIO_TYPE) {
        if (pthread_rwlock_trywrlock(&mLock) == 0) {
            if (!speedRecord->streamId.empty())
                mAudioCurrentStreamId = speedRecord->streamId.c_str();
            else
                mAudioCurrentStreamId = "-1";
            if (!speedRecord->mdlLoaderType.empty())
                mAudioMDLLoaderType = speedRecord->mdlLoaderType;
            else
                mAudioMDLLoaderType = "-1";
            mLastAudioDownloadSpeed = download_speed;
            mLastAudioDownloadSize = speedRecord->bytes;
            mLastAudioDownloadTime = cost_time;
            mLastAudioRTT = speedRecord->rtt;
            mLastAudioLastDataRecv = speedRecord->lastDataRecv;
            pthread_rwlock_unlock(&mLock);
        }
        if (download_speed > MINIMUM_SPEED && download_speed < MAXIMUM_SPEED) {
            float instantBandwidth = download_speed;
            mRecentAudioBandwidth.push_back(instantBandwidth);
            mRecentAudioTimestamp.push_back(speedRecord->timestamp);
            if(mRecentAudioBandwidth.size() > mBandwidthSlidingWindowSize) {
                auto  k = mRecentAudioBandwidth.begin();
                mRecentAudioBandwidth.erase(k);
            }
            if(mRecentAudioTimestamp.size() > mBandwidthSlidingWindowSize) {
                auto  k = mRecentAudioTimestamp.begin();
                mRecentAudioTimestamp.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentAudioBandwidth, download_speed, mStartupWindowSize,
                                         mAudioAvgSpeed, mAudioAvgWindowSpeed,
                                         mAudioCallCount, mAudioStartupSpeed);
        }
        if (! mConfBasedPredict)
            mPredictedAudioBandwidth = predictBandwidth(AUDIO_TYPE);
        else
            mPredictedAudioBandwidth = mConfBasedPredSpeed;
        LOGD("[SelectorLog] mediaType:%d download_speed:%.2f predict_speed:%.2f conf_predict_speed:%.2f conf:%.2f cost_time:%" PRId64
                     " bytes:%" PRIu64 " timestamp:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64
                     " mdlLoaderType:%s s_off:%" PRId64 " e_off:%" PRId64 " cbs:%" PRId64 " fbs:%" PRId64,
             trackType, download_speed, mPredictedAudioBandwidth, mConfBasedPredSpeed, mPredictConfidence, cost_time,
             speedRecord->bytes, speedRecord->timestamp, speedRecord->rtt, last_data_recv,
             mAudioMDLLoaderType.c_str(), speedRecord->s_off, speedRecord->e_off, speedRecord->cbs, speedRecord->fbs);
    }
}

void abrBaseSpeedPredictor::update(std::vector<std::shared_ptr<SpeedRecord>> speedRecords, std::map<std::string, int> mediaInfo) {
    int video_speed_record_num_all = 0;
    int audio_speed_record_num_all = 0;
    uint64_t video_total_record_size_all = 0;  // byte
    uint64_t audio_total_record_size_all = 0;  // byte
    int64_t video_timestamp_start_all = MAX_TIMESTAMP;
    int64_t video_timestamp_end_all = -1;
    int64_t audio_timestamp_start_all = MAX_TIMESTAMP;
    int64_t audio_timestamp_end_all = -1;
    int64_t video_cost_time_all = 0; //ms
    int64_t audio_cost_time_all = 0; //ms
    float video_download_speed_all = 0; //bps
    float audio_download_speed_all = 0; //bps
    int64_t video_total_rtt = 0;
    int64_t audio_total_rtt = 0;
    int64_t video_last_data_recv = 0;
    int64_t audio_last_data_recv = 0;
    int64_t video_update_count = 0;
    int64_t audio_update_count = 0;
    std::string video_mdl_loader_type = "-1";
    std::string audio_mdl_loader_type = "-1";
    bool missing_video = true;
    bool missing_audio = true;
    bool exist_video = false;
    bool exist_audio = false;
    mMultidimensionalDownloadSpeed.clear();
    mExistedMultidimensionalInfo.clear();
    mMultidimensionalPredictSpeed.clear();

    isExistMedia(mediaInfo, exist_video, exist_audio);
    int stream_record_num = speedRecords.size();
    for (int i = 0; i < stream_record_num; i ++) {
        if (speedRecords.at(i)) {
            std::string stream_id = speedRecords.at(i)->streamId.c_str();
            auto media_info_item = mediaInfo.find(stream_id);
            bool is_current_playing_media = true;
            if (media_info_item == mediaInfo.end()) {
                is_current_playing_media = false;
            }
            int track_type_from_media_info = VIDEO_TYPE;
            if (is_current_playing_media) {
                track_type_from_media_info = media_info_item->second;
                if (track_type_from_media_info == VIDEO_TYPE) {
                    if (pthread_rwlock_trywrlock(&mLock) == 0) {
                        if (!media_info_item->first.empty())
                            mVideoCurrentStreamId = media_info_item->first.c_str();
                        else
                            mVideoCurrentStreamId = "-1";
                        pthread_rwlock_unlock(&mLock);
                    }
                    missing_video = false;
                } else {
                    if (pthread_rwlock_trywrlock(&mLock) == 0) {
                        if (!media_info_item->first.empty())
                            mAudioCurrentStreamId = media_info_item->first.c_str();
                        else
                            mAudioCurrentStreamId = "-1";
                        pthread_rwlock_unlock(&mLock);
                    }
                    missing_audio = false;
                }
            }
            std::vector<std::shared_ptr<SpeedRecordItem>> speed_records = speedRecords.at(i)->speedRecords;
            int speed_record_num = speed_records.size();
//            LOGD("\n\n[SelectorLog] speed_records:%d", speed_record_num);
//            LOGD("[SelectorLog] stream_id:%s", stream_id.c_str());
            int video_speed_record_num = 0;
            int audio_speed_record_num = 0;
            uint64_t video_total_record_size = 0;
            uint64_t audio_total_record_size = 0;
            int64_t video_timestamp_start = MAX_TIMESTAMP;
            int64_t video_timestamp_end = -1;
            int64_t audio_timestamp_start = MAX_TIMESTAMP;
            int64_t audio_timestamp_end = -1;
            int64_t video_stream_cost_time = 0; //ms
            int64_t audio_stream_cost_time = 0; //ms
            float video_stream_download_speed = 0; //bps
            float audio_stream_download_speed = 0; //bps

            for (int j = 0; j < speed_record_num; j ++) {
                if (speed_records.at(j)) {
                    std::shared_ptr<SpeedRecordItem> &speedItem = speed_records.at(j);
                    int track_type = speed_records.at(j)->trackType;
                    uint64_t bytes = speed_records.at(j)->bytes; // byte
                    int64_t cost_time = speed_records.at(j)->time; //ms
                    int64_t last_data_recv = speed_records.at(j)->lastDataRecv;
                    int64_t timestamp_start = speed_records.at(j)->timestamp;
                    cost_time = cost_time > last_data_recv && last_data_recv > 0 ? cost_time - last_data_recv : cost_time;
                    int64_t timestamp_end = timestamp_start + cost_time;
                    std::string load_type = speed_records.at(j)->loadType;
                    std::string host = speed_records.at(j)->host;
                    int64_t rtt = speed_records.at(j)->tcpRtt;
                    std::string mdl_loader_type = "-1";
                    if (!speed_records.at(j)->mdlLoaderType.empty())
                        mdl_loader_type = speed_records.at(j)->mdlLoaderType;
                    int64_t s_off = speed_records.at(j)->s_off;
                    int64_t e_off = speed_records.at(j)->e_off;
                    int64_t cbs = speed_records.at(j)->cbs;
                    int64_t fbs = speed_records.at(j)->fbs;
                    bool preload = false;
                    if (!is_current_playing_media) {
                        preload = true;
                        track_type_from_media_info = track_type;
                    }
                    int buffer = mediaInfo["playerVideoBufLen"];
                    int maxBuffer = mediaInfo["playerVideoMaxBufLen"];
                    float download_speed = cost_time > 0 ? (static_cast<float>(bytes) * BYTE_IN_B * M_IN_K /
                                                            static_cast<float>(cost_time)) : 0.0f; // bps
                    SpeedInfo speedInfo(download_speed, false, buffer, maxBuffer, speedItem);
                    if (mConfBasedPredict)
                        mConfBasedPredSpeed = confBasedBandwidthPredict(speedInfo);


                    if (track_type == VIDEO_TYPE) {
                        video_timestamp_start = video_timestamp_start > timestamp_start ? timestamp_start : video_timestamp_start;
                        video_timestamp_end = video_timestamp_end < timestamp_end ? timestamp_end : video_timestamp_end;
                        video_speed_record_num ++;
                        video_total_record_size += bytes;

                        video_timestamp_start_all = video_timestamp_start_all > timestamp_start ? timestamp_start : video_timestamp_start_all;
                        video_timestamp_end_all = video_timestamp_end_all < timestamp_end ? timestamp_end : video_timestamp_end_all;
                        video_speed_record_num_all ++;
                        video_total_record_size_all += bytes;
                        video_total_rtt += rtt;
                        video_last_data_recv = last_data_recv;
                        video_update_count ++;
                        video_mdl_loader_type = mdl_loader_type;

                    } else if (track_type == AUDIO_TYPE) {
                        audio_timestamp_start = audio_timestamp_start > timestamp_start ? timestamp_start : audio_timestamp_start;
                        audio_timestamp_end = audio_timestamp_end < timestamp_end ? timestamp_end : audio_timestamp_end;
                        audio_speed_record_num ++;
                        audio_total_record_size += bytes;

                        audio_timestamp_start_all = audio_timestamp_start_all > timestamp_start ? timestamp_start : audio_timestamp_start_all;
                        audio_timestamp_end_all = audio_timestamp_end_all < timestamp_end ? timestamp_end : audio_timestamp_end_all;
                        audio_speed_record_num_all ++;
                        audio_total_record_size_all += bytes;
                        audio_total_rtt += rtt;
                        audio_last_data_recv = last_data_recv;
                        audio_update_count ++;
                        audio_mdl_loader_type = mdl_loader_type;


                    } else {
                        //pass
                    }
                    if (bytes > 0) {
                        updateMultidimensionalDownloadSpeed(mExistedMultidimensionalInfo, mMultidimensionalDownloadSpeed,
                                                            stream_id, load_type, bytes, timestamp_start, timestamp_end, host, track_type);  // With aggregation when timestamp overlap
                        LOGD("[SelectorLog] [multi] isCurrent:%d track_type:%d "
                             "track_type:%d bytes:%" PRIu64 " time:%" PRId64
                             " timestamp_start:%" PRId64 " load_type:%s host:%s stream_id:%s rtt:%" PRId64
                             " last_data_recv:%" PRId64 " mdlLoaderType:%s conf_predict_speed:%.2f conf:%.2f s_off:%" PRId64
                             " e_off:%" PRId64 " cbs:%" PRId64 " fbs:%" PRId64,
                             is_current_playing_media, track_type, track_type, bytes, cost_time,
                             timestamp_start, load_type.c_str(), host.c_str(), stream_id.c_str(), rtt,
                             last_data_recv, mdl_loader_type.c_str(), mConfBasedPredSpeed, mPredictConfidence,
                             s_off, e_off, cbs, fbs);
                    }
                }
            }

            if (video_speed_record_num > 0 && video_timestamp_end > video_timestamp_start) {
                video_stream_cost_time = video_timestamp_end - video_timestamp_start;  // ms
                video_stream_download_speed = static_cast<float>(video_total_record_size) * BYTE_IN_B * M_IN_K /
                        static_cast<float>(video_stream_cost_time); // bps
            }

            if (audio_speed_record_num > 0 && audio_timestamp_end > audio_timestamp_start) {
                audio_stream_cost_time = audio_timestamp_end - audio_timestamp_start;  // ms
                audio_stream_download_speed = static_cast<float>(audio_total_record_size) * BYTE_IN_B * M_IN_K /
                        static_cast<float>(audio_stream_cost_time); // bps
            }

        }
    }
    if (video_speed_record_num_all > 0 && video_timestamp_end_all > video_timestamp_start_all) {
        video_cost_time_all = video_timestamp_end_all - video_timestamp_start_all;  // ms
        video_download_speed_all = static_cast<float>(video_total_record_size_all) * BYTE_IN_B * M_IN_K /
                static_cast<float>(video_cost_time_all); // bps
        if (pthread_rwlock_trywrlock(&mLock) == 0) {
            mLastVideoDownloadSpeed = video_download_speed_all;
            mLastVideoDownloadSize = video_total_record_size_all;
            mLastVideoDownloadTime = video_cost_time_all;
            mLastVideoRTT = video_update_count > 0 ? int64_t(video_total_rtt * 1.0f / video_update_count) : 0;
            mLastVideoLastDataRecv = video_last_data_recv;
            mVideoMDLLoaderType = video_mdl_loader_type.c_str();
            pthread_rwlock_unlock(&mLock);
        }
        if (video_download_speed_all > MINIMUM_SPEED && video_download_speed_all < MAXIMUM_SPEED) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
            float instantBandwidth = video_download_speed_all;
            mRecentVideoBandwidth.push_back(instantBandwidth);
            mRecentVideoTimestamp.push_back(video_timestamp_start_all);
            if(mRecentVideoBandwidth.size() > mBandwidthSlidingWindowSize) {
                std::vector<float>::iterator  k = mRecentVideoBandwidth.begin();
                mRecentVideoBandwidth.erase(k);
            }
            if(mRecentVideoTimestamp.size() > mBandwidthSlidingWindowSize) {
                std::vector<int64_t>::iterator  k = mRecentVideoTimestamp.begin();
                mRecentVideoTimestamp.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentVideoBandwidth, video_download_speed_all, mStartupWindowSize,
                                         mVideoAvgSpeed, mVideoAvgWindowSpeed,
                                         mVideoCallCount, mVideoStartupSpeed);
        }
        if (!mConfBasedPredict)
            mPredictedVideoBandwidth = predictBandwidth(VIDEO_TYPE);
        else
            mPredictedVideoBandwidth = mConfBasedPredSpeed;

        LOGD("[SelectorLog] video download_speed:%.2f predict_speed:%.2f conf_predict_speed:%.2f conf:%.2f cost_time:%" PRId64
                     " bytes:%" PRIu64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             video_download_speed_all, mPredictedVideoBandwidth, mConfBasedPredSpeed, mPredictConfidence, video_cost_time_all,
             video_total_record_size_all, mLastVideoRTT, mLastVideoLastDataRecv);
    }

    if (audio_speed_record_num_all > 0 && audio_timestamp_end_all > audio_timestamp_start_all) {
        audio_cost_time_all = audio_timestamp_end_all - audio_timestamp_start_all;  // ms
        audio_download_speed_all = static_cast<float>(audio_total_record_size_all) * BYTE_IN_B * M_IN_K /
                static_cast<float>(audio_cost_time_all);  // bps
        if (pthread_rwlock_trywrlock(&mLock) == 0) {
            mLastAudioDownloadSpeed = audio_download_speed_all;
            mLastAudioDownloadSize = audio_total_record_size_all;
            mLastAudioDownloadTime = audio_cost_time_all;
            mLastAudioRTT = audio_update_count > 0 ? int64_t(audio_total_rtt * 1.0f / audio_update_count) : 0;
            mLastAudioLastDataRecv = audio_last_data_recv;
            mAudioMDLLoaderType = audio_mdl_loader_type.c_str();
            pthread_rwlock_unlock(&mLock);
        }
        if (audio_download_speed_all > MINIMUM_SPEED && audio_download_speed_all < MAXIMUM_SPEED) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
            float instantBandwidth = audio_download_speed_all;
            mRecentAudioBandwidth.push_back(instantBandwidth);
            mRecentAudioTimestamp.push_back(audio_timestamp_start_all);
            if(mRecentAudioBandwidth.size() > mBandwidthSlidingWindowSize) {
                std::vector<float>::iterator  k = mRecentAudioBandwidth.begin();
                mRecentAudioBandwidth.erase(k);
            }
            if(mRecentAudioTimestamp.size() > mBandwidthSlidingWindowSize) {
                std::vector<int64_t>::iterator  k = mRecentAudioTimestamp.begin();
                mRecentAudioTimestamp.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentAudioBandwidth, audio_download_speed_all, mStartupWindowSize,
                                         mAudioAvgSpeed, mAudioAvgWindowSpeed,
                                         mAudioCallCount, mAudioStartupSpeed);
        }
        if (!mConfBasedPredict)
            mPredictedAudioBandwidth = predictBandwidth(AUDIO_TYPE);
        else
            mPredictedAudioBandwidth = mConfBasedPredSpeed;

        LOGD("[SelectorLog] audio download_speed:%.2f predict_speed:%.2f conf_predict_speed:%.2f conf:%.2f cost_time:%" PRId64
                     " bytes:%" PRIu64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             audio_download_speed_all, mPredictedAudioBandwidth, mConfBasedPredSpeed, mPredictConfidence, audio_cost_time_all,
             audio_total_record_size_all, mLastAudioRTT, mLastAudioLastDataRecv);
    }
    if(exist_video && missing_video)
        updateMultidimensionalFakeMediaDownloadSpeed(mMultidimensionalDownloadSpeed, mediaInfo, missing_video, mVideoCurrentStreamId, VIDEO_TYPE);
    if(exist_audio && missing_audio)
        updateMultidimensionalFakeMediaDownloadSpeed(mMultidimensionalDownloadSpeed, mediaInfo, missing_audio, mAudioCurrentStreamId, AUDIO_TYPE);
    updateMultidimensionalPredictSpeed();
}

void abrBaseSpeedPredictor::updateMultidimensionalPredictSpeed() {
    for (int i = 0; i < mMultidimensionalDownloadSpeed.size(); i++) {
        std::string file_id = mMultidimensionalDownloadSpeed.at(i)->fileId;

        NetworkSpeedResult * p_network_speed_result = new NetworkSpeedResult();
        std::shared_ptr<NetworkSpeedResult> network_predict_speed_result(p_network_speed_result);
        network_predict_speed_result->fileId = file_id;
        NetworkSpeedResultItemVec result_item_collection;
        for (int j = 0; j < (mMultidimensionalDownloadSpeed.at(i))->speedResultItems.size(); j++) {
            std::string load_type = (mMultidimensionalDownloadSpeed.at(i))->speedResultItems.at(j).get()->loadType;
            std::string host = (mMultidimensionalDownloadSpeed.at(i))->speedResultItems.at(j).get()->host;
            int track_type = (mMultidimensionalDownloadSpeed.at(i))->speedResultItems.at(j).get()->trackType;
            float predict_speed = -1;
            if (track_type == VIDEO_TYPE) {
                predict_speed = mPredictedVideoBandwidth;
            } else if (track_type == AUDIO_TYPE) {
                predict_speed = mPredictedAudioBandwidth;
            }
            std::shared_ptr<NetworkSpeedResultItem> result_item = std::make_shared<NetworkSpeedResultItem>(load_type, host, predict_speed, track_type);
            result_item_collection.push_back(result_item);
//            LOGD("[SelectorLog][updateMultidimensionalPredictSpeed] predict stream_id=%s, \tload_type=%s, \thost=%s, \ttrack_type=%d, \tpredict_speed=%f",
//                 file_id.c_str(),
//                 load_type.c_str(),
//                 host.c_str(),
//                 track_type,
//                 result_item->bandwidth);
        }
        network_predict_speed_result->speedResultItems = result_item_collection;
        mMultidimensionalPredictSpeed.push_back(network_predict_speed_result);
    }
}

float abrBaseSpeedPredictor::confBasedBandwidthPredict(SpeedInfo& speedInfo) {
    float accuracy = getAccuracy(speedInfo);
    if (accuracy > 0) {
        mRecentConfSpeed.push_back(speedInfo.speed);
        if (mRecentConfSpeed.size() > mBandwidthSlidingWindowSize)
            mRecentConfSpeed.pop_front();
        mRecentConfTimestamp.push_back(speedInfo.speedRecord->timestamp);
        if (mRecentConfTimestamp.size() > mBandwidthSlidingWindowSize)
            mRecentConfTimestamp.pop_front();
        mRecentAccuracy.push_back(accuracy);
        if (mRecentAccuracy.size() > mBandwidthSlidingWindowSize)
            mRecentAccuracy.pop_front();
    }
    int64_t newTimestamp = speedInfo.speedRecord->timestamp;
    std::vector<float> recentConf(mRecentConfSpeed.size(), 0.0f);
    for (int i = 0; i < mRecentConfSpeed.size(); i++) {
        if (mRecentConfTimestamp.size() > i && mRecentAccuracy.size() > i) {
            int64_t age = (newTimestamp - mRecentConfTimestamp[i]) / 1000;
            age = age > 0 ? age : 0;
            recentConf[i] = mRecentAccuracy[i] * exp(-1.0 * age / 30.0);
        }
    }
    float confSum = std::accumulate(recentConf.begin(), recentConf.end(), 0.0f);
    std::vector<float> scaledSpeed;
    if (confSum > 0) {
        for (int i = 0; i < mRecentConfSpeed.size(); i++) {
            if (recentConf.size() > i) {
                int scaleCount = int(recentConf[i] / confSum * SCALED_SPEED_LEN);
                for (int j = 0; j < scaleCount; j++)
                    scaledSpeed.push_back(mRecentConfSpeed[i]);
            }
        }
    }
    LOGD("[SelectorLog] confBasedBandwidthPredict, accuracy=%f, buffer=%d, max_buffer=%d", accuracy,
            speedInfo.buffer, speedInfo.maxBuffer);
    if (! scaledSpeed.empty()){
        mPredictConfidence = *std::max_element(recentConf.begin(), recentConf.end());
        return std::accumulate(scaledSpeed.begin(), scaledSpeed.end(), 0.0f) / scaledSpeed.size();
    } else {
        mPredictConfidence = 0;
        return mPredictedVideoBandwidth;
    }
}

NETWORKPREDICT_NAMESPACE_END
