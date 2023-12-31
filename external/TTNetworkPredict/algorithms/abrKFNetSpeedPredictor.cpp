//
// Created by xuzhimin on 2020-05-29.
//

#include "abrKFNetSpeedPredictor.h"

NETWORKPREDICT_NAMESPACE_BEGIN

float changekBpstobps(float bw){
    bw = bw * 1000.0 * 8.0;
    return bw;
}

float changebpstokBps(float bw){
    bw = bw / 1000.0 / 8.0;
    return bw;
}

abrKFNetSpeedPredictor::abrKFNetSpeedPredictor()
:videoX(0.0), audioX(0.0)
,videoP(1.0), audioP(1.0)
,videoF(1.0), audioF(1.0)
,videoQ(1.0), audioQ(1.0)
,videoH(1.0), audioH(1.0)
,videoR(1.0), audioR(1.0)
,videoZ(-1.0), audioZ(-1.0)
,videoPositiveGrow(0.0), audioPositiveGrow(0.0)
,videoNegativeGrow(0.0), audioNegativeGrow(0.0)
,videoPositiveThreshold(200.0), audioPositiveThreshold(200.0)
,videoNegativeThreshold(10.0), audioNegativeThreshold(10.0)
,videoV(5.0), audioV(5.0)
,videoStableQ(1.0), audioStableQ(1.0)
,videoDynamicUpQ(8.0), audioDynamicUpQ(8.0)
,videoDynamicDownQ(180.0), audioDynamicDownQ(180.0)
,videoStableCount(0.0), audioStableCount(0.0)
,videoStableMeasurementDiscount(0.9), audioStableMeasurementDiscount(0.9)
,videoDynamicMeasurementDiscount(0.75), audioDynamicMeasurementDiscount(0.75)
,videoStableThreshold(10.0), audioStableThreshold(10.0)
{
    videoMeasurementDiscount = videoStableMeasurementDiscount;
    audioMeasurementDiscount = audioStableMeasurementDiscount;
}

abrKFNetSpeedPredictor::~abrKFNetSpeedPredictor() {
}

void abrKFNetSpeedPredictor::updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) {
    auto media_info_item = mediaInfo.find(speedRecord->streamId);
    if (media_info_item == mediaInfo.end()) {
        return;
    }
    int track_type_from_media_info = media_info_item->second;
    int64_t last_data_recv = speedRecord->lastDataRecv;
    float cost_time = speedRecord->time; //ms
    cost_time = cost_time > last_data_recv && last_data_recv > 0 ? cost_time - last_data_recv : cost_time;
    cost_time = cost_time > 1e-4f ? cost_time : 1e-4f;
    float download_speed = speedRecord->bytes * 8.0f * 1000.0f / cost_time; // bps
    if (track_type_from_media_info == VIDEO_TYPE) {
        mVideoCurrentStreamId = speedRecord->streamId;
        mLastVideoDownloadSpeed = download_speed;
        mLastVideoDownloadSize = speedRecord->bytes;
        mLastVideoDownloadTime = cost_time;
        mLastVideoRTT = speedRecord->rtt;
        mLastVideoLastDataRecv = speedRecord->lastDataRecv;
        if (download_speed > MINIMUM_SPEED && download_speed < MAXIMUM_SPEED) {
            if (!mOpenNetworkSpeedOptimize || (mOpenNetworkSpeedOptimize&& cost_time <= mCostTimeFilterValue)) {
                float instantBandwidth = changebpstokBps(download_speed);
                videoZ = videoMeasurementDiscount * instantBandwidth;
                mRecentVideoBandwidth.push_back(download_speed);
                if (mRecentVideoBandwidth.size() > mBandwidthSlidingWindowSize) {
                    std::vector<float>::iterator k = mRecentVideoBandwidth.begin();
                    mRecentVideoBandwidth.erase(k);
                }
            }
            updateMediaDownloadSpeedInfo(mRecentVideoBandwidth, download_speed, mStartupWindowSize,
                                         mVideoAvgSpeed, mVideoAvgWindowSpeed,
                                         mVideoCallCount, mVideoStartupSpeed);
        }
        mPredictedVideoBandwidth = predictBandwidth(VIDEO_TYPE);
        LOGD("[SelectorLog] video download_speed:%.2f predict_speed:%.2f cost_time:%.2f bytes:%d "
             "timestamp:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             download_speed, mPredictedVideoBandwidth, cost_time, speedRecord->bytes,
             speedRecord->timestamp, speedRecord->rtt, last_data_recv);
    } else if (track_type_from_media_info == AUDIO_TYPE) {
        mAudioCurrentStreamId = speedRecord->streamId;
        mLastAudioDownloadSpeed = download_speed;
        mLastAudioDownloadSize = speedRecord->bytes;
        mLastAudioDownloadTime = cost_time;
        mLastAudioRTT = speedRecord->rtt;
        mLastAudioLastDataRecv = speedRecord->lastDataRecv;
        if (download_speed > MINIMUM_SPEED && download_speed < MAXIMUM_SPEED) {
            float instantBandwidth = changebpstokBps(download_speed);
            audioZ = audioMeasurementDiscount * instantBandwidth;
            mRecentAudioBandwidth.push_back(download_speed);
            if (mRecentAudioBandwidth.size() > mBandwidthSlidingWindowSize) {
                std::vector<float>::iterator k = mRecentAudioBandwidth.begin();
                mRecentAudioBandwidth.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentAudioBandwidth, download_speed, mStartupWindowSize,
                                         mAudioAvgSpeed, mAudioAvgWindowSpeed,
                                         mAudioCallCount, mAudioStartupSpeed);
        }
        mPredictedAudioBandwidth = predictBandwidth(AUDIO_TYPE);
        LOGD("[SelectorLog] audio download_speed:%.2f predict_speed:%.2f cost_time:%.2f bytes:%d "
             "timestamp:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             download_speed, mPredictedAudioBandwidth, cost_time,speedRecord->bytes,
             speedRecord->timestamp, speedRecord->rtt, last_data_recv);
    } else {
        mPredictedVideoBandwidth = 0.0;
        mPredictedAudioBandwidth = 0.0;
    }
}

void abrKFNetSpeedPredictor::update(std::vector<std::shared_ptr<SpeedRecord>> speedRecords, std::map<std::string, int> mediaInfo) {
    int video_speed_record_num_all = 0;
    int audio_speed_record_num_all = 0;
    int64_t video_total_record_size_all = 0;  // byte
    int64_t audio_total_record_size_all = 0;  // byte
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
            std::string stream_id = speedRecords.at(i)->streamId;
            auto media_info_item = mediaInfo.find(stream_id);
            bool is_current_playing_media = true;
            if (media_info_item == mediaInfo.end()) {
                is_current_playing_media = false;
            }
            int track_type_from_media_info = VIDEO_TYPE;
            if (is_current_playing_media) {
                track_type_from_media_info = media_info_item->second;
                if (track_type_from_media_info == VIDEO_TYPE) {
                    mVideoCurrentStreamId = media_info_item->first;
                    missing_video = false;
                } else {
                    mAudioCurrentStreamId = media_info_item->first;
                    missing_audio = false;
                }
            }
            std::vector<std::shared_ptr<SpeedRecordItem>> speed_records = speedRecords.at(i)->speedRecords;
            int speed_record_num = speed_records.size();
//            LOGD("\n\n[SelectorLog] [KFNet] speed_records:%d", speed_record_num);
//            LOGD("[SelectorLog] [KFNet] stream_id:%s", stream_id.c_str());
            int video_speed_record_num = 0;
            int audio_speed_record_num = 0;
            int64_t video_total_record_size = 0;
            int64_t audio_total_record_size = 0;
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
                    int track_type = speed_records.at(j)->trackType;
                    int64_t bytes = speed_records.at(j)->bytes; // byte
                    int64_t cost_time = speed_records.at(j)->time; //ms
                    int64_t last_data_recv = speed_records.at(j)->lastDataRecv;
                    int64_t timestamp_start = speed_records.at(j)->timestamp;
                    cost_time = cost_time > last_data_recv && last_data_recv > 0 ? cost_time - last_data_recv : cost_time;
                    int64_t timestamp_end = timestamp_start + cost_time;
                    std::string load_type = speed_records.at(j)->loadType;
                    std::string host = speed_records.at(j)->host;
                    int64_t rtt = speed_records.at(j)->tcpRtt;

                    if (!is_current_playing_media) {
                        track_type_from_media_info = track_type;
                    }

                    if (track_type_from_media_info == VIDEO_TYPE) {
                        video_timestamp_start = video_timestamp_start > timestamp_start ? timestamp_start : video_timestamp_start;
                        video_timestamp_end = video_timestamp_end < timestamp_end ? timestamp_end : video_timestamp_end;
                        video_speed_record_num ++;
                        video_total_record_size += bytes;

                        if (is_current_playing_media) {
                            video_timestamp_start_all = video_timestamp_start_all > timestamp_start ? timestamp_start : video_timestamp_start_all;
                            video_timestamp_end_all = video_timestamp_end_all < timestamp_end ? timestamp_end : video_timestamp_end_all;
                            video_speed_record_num_all ++;
                            video_total_record_size_all += bytes;
                            video_total_rtt += rtt;
                            video_last_data_recv = last_data_recv;
                            video_update_count ++;
                        }

                    } else if (track_type_from_media_info == AUDIO_TYPE) {
                        audio_timestamp_start = audio_timestamp_start > timestamp_start ? timestamp_start : audio_timestamp_start;
                        audio_timestamp_end = audio_timestamp_end < timestamp_end ? timestamp_end : audio_timestamp_end;
                        audio_speed_record_num ++;
                        audio_total_record_size += bytes;

                        if (is_current_playing_media) {
                            audio_timestamp_start_all = audio_timestamp_start_all > timestamp_start ? timestamp_start : audio_timestamp_start_all;
                            audio_timestamp_end_all = audio_timestamp_end_all < timestamp_end ? timestamp_end : audio_timestamp_end_all;
                            audio_speed_record_num_all ++;
                            audio_total_record_size_all += bytes;
                            audio_total_rtt += rtt;
                            audio_last_data_recv = last_data_recv;
                            audio_update_count ++;
                        }

                    } else {
                        //pass
                    }
                    if (is_current_playing_media && bytes > 0) {
                        updateMultidimensionalDownloadSpeed(mExistedMultidimensionalInfo, mMultidimensionalDownloadSpeed,
                                                            stream_id, load_type, bytes, timestamp_start, timestamp_end, host, track_type_from_media_info);  // With aggregation when timestamp overlap
                        LOGD("[SelectorLog] [KFNet] [multi] current track_type:%d "
                             "track_type_from_media_info:%d bytes:%" PRId64 " time:%" PRId64
                                     " timestamp_start:%" PRId64 " load_type:%s host:%s rtt:%" PRId64 " last_data_recv:%" PRId64,
                             track_type, track_type_from_media_info, bytes, cost_time,
                             timestamp_start, load_type.c_str(), host.c_str(), rtt, last_data_recv);
                    } else if (bytes > 0) {
                        LOGD("[SelectorLog] [KFNet] [multi] track_type:%d "
                             "track_type_from_media_info:%d bytes:%" PRId64 " time:%" PRId64
                                     " timestamp_start:%" PRId64 " load_type:%s host:%s stream_id:%s rtt:%" PRId64 " last_data_recv:%" PRId64,
                             track_type, track_type_from_media_info, bytes, cost_time,
                             timestamp_start, load_type.c_str(), host.c_str(), stream_id.c_str(), rtt, last_data_recv);
                    }
                }
            }

            if (video_speed_record_num > 0 && video_timestamp_end > video_timestamp_start) {
                video_stream_cost_time = video_timestamp_end - video_timestamp_start;  // ms
                video_stream_download_speed = video_total_record_size * BYTE_IN_B * M_IN_K / video_stream_cost_time; // bps
            }

            if (audio_speed_record_num > 0 && audio_timestamp_end > audio_timestamp_start) {
                audio_stream_cost_time = audio_timestamp_end - audio_timestamp_start;  // ms
                audio_stream_download_speed = audio_total_record_size * BYTE_IN_B * M_IN_K / audio_stream_cost_time; // bps
            }

        }
    }
    if (video_speed_record_num_all > 0 && video_timestamp_end_all > video_timestamp_start_all) {
        video_cost_time_all = video_timestamp_end_all - video_timestamp_start_all;  // ms
        video_download_speed_all = video_total_record_size_all * BYTE_IN_B * M_IN_K / video_cost_time_all; // bps
        mLastVideoDownloadSpeed = video_download_speed_all;
        mLastVideoDownloadSize = video_total_record_size_all;
        mLastVideoDownloadTime = video_cost_time_all;
        mLastVideoRTT = video_update_count > 0 ? int64_t(video_total_rtt * 1.0f / video_update_count) : 0;
        mLastVideoLastDataRecv = video_last_data_recv;
        if (video_download_speed_all > MINIMUM_SPEED && video_download_speed_all < MAXIMUM_SPEED) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
            float instantBandwidth = changebpstokBps(video_download_speed_all);
            videoZ = videoMeasurementDiscount * instantBandwidth;
            mRecentVideoBandwidth.push_back(video_download_speed_all);
            if(mRecentVideoBandwidth.size() > mBandwidthSlidingWindowSize) {
                std::vector<float>::iterator  k = mRecentVideoBandwidth.begin();
                mRecentVideoBandwidth.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentVideoBandwidth, video_download_speed_all, mStartupWindowSize,
                                         mVideoAvgSpeed, mVideoAvgWindowSpeed,
                                         mVideoCallCount, mVideoStartupSpeed);
        }
        mPredictedVideoBandwidth = predictBandwidth(VIDEO_TYPE);
        LOGD("[SelectorLog] video download_speed:%.2f predict_speed:%.2f cost_time:%" PRId64
                     " bytes:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             video_download_speed_all, mPredictedVideoBandwidth, video_cost_time_all,
             video_total_record_size_all, mLastVideoRTT, mLastVideoLastDataRecv);
    }

    if (audio_speed_record_num_all > 0 && audio_timestamp_end_all > audio_timestamp_start_all) {
        audio_cost_time_all = audio_timestamp_end_all - audio_timestamp_start_all;  // ms
        audio_download_speed_all = audio_total_record_size_all * BYTE_IN_B * M_IN_K / audio_cost_time_all;  // bps
        mLastAudioDownloadSpeed = audio_download_speed_all;
        mLastAudioDownloadSize = audio_total_record_size_all;
        mLastAudioDownloadTime = audio_cost_time_all;
        mLastAudioRTT = audio_update_count > 0 ? int64_t(audio_total_rtt * 1.0f / audio_update_count) : 0;
        mLastAudioLastDataRecv = audio_last_data_recv;
        if (audio_download_speed_all > MINIMUM_SPEED && audio_download_speed_all < MAXIMUM_SPEED) {// Add a filter to solve the no download slot
            float instantBandwidth = changebpstokBps(audio_download_speed_all);
            audioZ = audioMeasurementDiscount * instantBandwidth;
            mRecentAudioBandwidth.push_back(audio_download_speed_all);
            if (mRecentAudioBandwidth.size() > mBandwidthSlidingWindowSize) {
                std::vector<float>::iterator k = mRecentAudioBandwidth.begin();
                mRecentAudioBandwidth.erase(k);
            }
            updateMediaDownloadSpeedInfo(mRecentAudioBandwidth, audio_download_speed_all, mStartupWindowSize,
                                         mAudioAvgSpeed, mAudioAvgWindowSpeed,
                                         mAudioCallCount, mAudioStartupSpeed);
        }
        mPredictedAudioBandwidth = predictBandwidth(AUDIO_TYPE);
        LOGD("[SelectorLog] audio download_speed:%.2f predict_speed:%.2f cost_time:%" PRId64
                     " bytes:%" PRId64 " rtt:%" PRId64 " last_data_recv:%" PRId64,
             audio_download_speed_all, mPredictedAudioBandwidth, audio_cost_time_all,
             audio_total_record_size_all, mLastAudioRTT, mLastAudioLastDataRecv);
    }
    if(exist_video && missing_video)
        updateMultidimensionalFakeMediaDownloadSpeed(mMultidimensionalDownloadSpeed, mediaInfo, missing_video, mVideoCurrentStreamId, VIDEO_TYPE);
    if(exist_audio && missing_audio)
        updateMultidimensionalFakeMediaDownloadSpeed(mMultidimensionalDownloadSpeed, mediaInfo, missing_audio, mAudioCurrentStreamId, AUDIO_TYPE);
    updateMultidimensionalPredictSpeed();
}

float abrKFNetSpeedPredictor::predictBandwidth(int media_type) {
    float predicted_bandwidth = 0.0;
    if (media_type == VIDEO_TYPE) {
        if (videoZ < 0) {
            return mPredictedVideoBandwidth;
        }
        float residual = (videoZ -  videoH * videoX) / pow(videoH * videoP * videoH + videoR, 0.5);

        float positive_temp = videoPositiveGrow + residual - videoV;
        if (positive_temp > 0){
            videoPositiveGrow = positive_temp;
        }else{
            videoPositiveGrow = 0;
        }

        float negative_temp = videoNegativeGrow + residual + videoV;
        if (negative_temp < 0){
            videoNegativeGrow = negative_temp;
        }else{
            videoNegativeGrow = 0;
        }

        if (videoPositiveGrow > videoPositiveThreshold || - videoNegativeGrow > videoNegativeThreshold){
            if (videoPositiveGrow > videoPositiveThreshold){
                videoQ = videoDynamicUpQ;
            }else if (-videoNegativeGrow > videoNegativeThreshold){
                videoQ = videoDynamicDownQ;
            }
            // Restart: set value to zero again
            videoPositiveGrow = 0.0;
            videoNegativeGrow = 0.0;
            videoStableCount = 0.0;
            videoMeasurementDiscount = videoDynamicMeasurementDiscount;
        }else{
            videoQ = videoStableQ;
            videoStableCount += 1;
        }

        if (videoStableCount >= videoStableThreshold){     // Determine whether it is in a stable stage
            videoMeasurementDiscount = videoStableMeasurementDiscount;
        }

        videoX = videoF * videoX;
        videoP = videoF * videoP * videoF + videoQ;
        float K = videoP * videoH / (videoH * videoP * videoH + videoR);
        videoX += K * (videoZ - videoH * videoX);
        videoP = (1 - K * videoH) * videoP;
        predicted_bandwidth = videoX;
    } else if (media_type == AUDIO_TYPE) {
        if (audioZ < 0) {
            return mPredictedAudioBandwidth;
        }
        float residual = (audioZ -  audioH * audioX) / pow(audioH * audioP * audioH + audioR, 0.5);
        float positive_temp = audioPositiveGrow + residual - audioV;
        if (positive_temp > 0){
            audioPositiveGrow = positive_temp;
        }else{
            audioPositiveGrow = 0;
        }

        float negative_temp = audioNegativeGrow + residual + audioV;
        if (negative_temp < 0){
            audioNegativeGrow = negative_temp;
        }else{
            audioNegativeGrow = 0;
        }

        if (audioPositiveGrow > audioPositiveThreshold || - audioNegativeGrow > audioNegativeThreshold){
            if (audioPositiveGrow > audioPositiveThreshold){
                audioQ = audioDynamicUpQ;
            }else if (-audioNegativeGrow > audioNegativeThreshold){
                audioQ = audioDynamicDownQ;
            }

            // Restart: set value to zero again
            audioPositiveGrow = 0.0;
            audioNegativeGrow = 0.0;
            audioStableCount = 0.0;
            audioMeasurementDiscount = audioDynamicMeasurementDiscount;
        }else{
            audioQ = audioStableQ;
            audioStableCount += 1;
        }

        // Determine whether it is in a stable stage
        if (audioStableCount >= audioStableThreshold){
            audioMeasurementDiscount = videoStableMeasurementDiscount;
        }

        audioX = audioF * audioX;
        audioP = audioF * audioP * audioF + audioQ;
        float K = audioP * audioH / (audioH * audioP * audioH + audioR);
        audioX += K * (audioZ - audioH * audioX);
        audioP = (1 - K * audioH) * audioP;
        predicted_bandwidth = audioX;


    } else {
        //pass
    }
    predicted_bandwidth = changekBpstobps(predicted_bandwidth);
    LOGD("[SelectorLog] [KFNet] predicted_bandwidth=%f", predicted_bandwidth);
    return predicted_bandwidth;  // return bps
}

NETWORKPREDICT_NAMESPACE_END
