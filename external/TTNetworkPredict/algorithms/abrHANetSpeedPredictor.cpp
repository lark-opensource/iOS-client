//
// Created by xuzhimin on 2020-03-19.
//

#include "abrHANetSpeedPredictor.h"

NETWORKPREDICT_NAMESPACE_BEGIN

abrHANetSpeedPredictor::abrHANetSpeedPredictor()
:mStreamSlidingWindowSize(20)
,mLoadTypeSlidingWindowSize(20)
{
}

abrHANetSpeedPredictor::~abrHANetSpeedPredictor() {
}

void abrHANetSpeedPredictor::predictMultiBandwidth() {
//    int64_t cost_time = (int64_t)(speedRecord->time > 1e-4 ? speedRecord->time : 1e-4); //ms
//    float download_speed = speedRecord->bytes * 8.0 * 1000.0 / cost_time; // bps
//    if (speedRecord->trackType == VIDEO_TYPE) {
//        if (download_speed > 40000 ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
//            float instantBandwidth = download_speed;
//            mRecentVideoBandwidth.push_back(instantBandwidth);
//            mRecentVideoTimestamp.push_back(speedRecord->timestamp);
//            if(mRecentVideoBandwidth.size() > mBandwidthSlidingWindowSize) {
//                std::vector<float>::iterator  k = mRecentVideoBandwidth.begin();
//                mRecentVideoBandwidth.erase(k);
//            }
//            if(mRecentVideoTimestamp.size() > mBandwidthSlidingWindowSize) {
//                std::vector<int64_t>::iterator  k = mRecentVideoTimestamp.begin();
//                mRecentVideoTimestamp.erase(k);
//            }
//        }
//        mPredictedVideoBandwidth = predictBandwidth(VIDEO_TYPE);
//        LOGD("[SelectorLog] [HANet] download_speed:%.2f predict_speed:%.2f", download_speed, mPredictedVideoBandwidth);
//    } else if (speedRecord->trackType == AUDIO_TYPE) {
//        if (download_speed > 40000 ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
//            float instantBandwidth = download_speed;
//            mRecentAudioBandwidth.push_back(instantBandwidth);
//            mRecentAudioTimestamp.push_back(speedRecord->timestamp);
//            if(mRecentAudioBandwidth.size() > mBandwidthSlidingWindowSize) {
//                std::vector<float>::iterator  k = mRecentAudioBandwidth.begin();
//                mRecentAudioBandwidth.erase(k);
//            }
//            if(mRecentAudioTimestamp.size() > mBandwidthSlidingWindowSize) {
//                std::vector<int64_t>::iterator  k = mRecentAudioTimestamp.begin();
//                mRecentAudioTimestamp.erase(k);
//            }
//        }
//        mPredictedAudioBandwidth = predictBandwidth(AUDIO_TYPE);
//    } else {
//        mPredictedVideoBandwidth = 0.0;
//        mPredictedAudioBandwidth = 0.0;
//    }
}

float abrHANetSpeedPredictor::predictBandwidth(int media_type) {
    float predicted_bandwidth = 0.0;
    float bandwidth_sum = 0.0;
    if (media_type == VIDEO_TYPE) {
        for (int i = 0; i < mRecentVideoBandwidth.size(); i ++) {
            float temp_bandwidth = mRecentVideoBandwidth.at(i) > 1 ? mRecentVideoBandwidth.at(i) : 1;
            bandwidth_sum += 1.0f/temp_bandwidth;
        }
        predicted_bandwidth = mRecentVideoBandwidth.size() > 0 ? mRecentVideoBandwidth.size() / bandwidth_sum : predicted_bandwidth;
    } else if (media_type == AUDIO_TYPE) {
        for (int i = 0; i < mRecentAudioBandwidth.size(); i ++) {
            float temp_bandwidth = mRecentAudioBandwidth.at(i) > 1 ? mRecentAudioBandwidth.at(i) : 1;
            bandwidth_sum += 1.0f/temp_bandwidth;
        }
        predicted_bandwidth = mRecentAudioBandwidth.size() > 0 ? mRecentAudioBandwidth.size() / bandwidth_sum : predicted_bandwidth;
    } else {
        //pass
    }
    LOGD("[SelectorLog] [HANet] predicted_bandwidth=%f", predicted_bandwidth);
    return predicted_bandwidth;
}

int abrHANetSpeedPredictor::findStreamIndex(std::string stream_id, int media_type) {
    int index = -1;
    if (media_type == VIDEO_TYPE) {
        for (int i = 0; i < mRecentStreamVideoBandwidthInfo.size(); i ++) {
            if (mRecentStreamVideoBandwidthInfo.at(i).stream_id == stream_id) {
                index = i;
                break;
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        for (int i = 0; i < mRecentStreamAudioBandwidthInfo.size(); i ++) {
            if (mRecentStreamAudioBandwidthInfo.at(i).stream_id == stream_id) {
                index = i;
                break;
            }
        }
    } else {
        //pass
    }
    return index;
}

int abrHANetSpeedPredictor::findStreamFailedIndex(int media_type) {
    int index = -1;
    if (media_type == VIDEO_TYPE) {
        if (mRecentStreamVideoBandwidthInfo.size() <= mStreamSlidingWindowSize) {
            return index;
        }
        int64_t timestamp_end = -1;
        for (int i = 0; i < mRecentStreamVideoBandwidthInfo.size(); i ++) {
            if (mRecentStreamVideoBandwidthInfo.at(i).end_timestamp >= timestamp_end) {
                index = i;
                timestamp_end = mRecentStreamVideoBandwidthInfo.at(i).end_timestamp;
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        if (mRecentStreamAudioBandwidthInfo.size() <= mStreamSlidingWindowSize) {
            return index;
        }
        int64_t timestamp_end = -1;
        for (int i = 0; i < mRecentStreamAudioBandwidthInfo.size(); i ++) {
            if (mRecentStreamAudioBandwidthInfo.at(i).end_timestamp >= timestamp_end) {
                index = i;
                timestamp_end = mRecentStreamAudioBandwidthInfo.at(i).end_timestamp;
            }
        }
    } else {
        //pass
    }
    return index;
}

int abrHANetSpeedPredictor::findLoadTypeIndex(std::string load_type, int media_type) {
    int index = -1;
    if (media_type == VIDEO_TYPE) {
        for (int i = 0; i < mRecentLoadTypeVideoBandwidthInfo.size(); i ++) {
            if (mRecentLoadTypeVideoBandwidthInfo.at(i).load_type == load_type) {
                index = i;
                break;
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        for (int i = 0; i < mRecentLoadTypeAudioBandwidthInfo.size(); i ++) {
            if (mRecentLoadTypeAudioBandwidthInfo.at(i).load_type == load_type) {
                index = i;
                break;
            }
        }
    } else {
        //pass
    }
    return index;
}

int abrHANetSpeedPredictor::findLoadTypeFailedIndex(int media_type) {
    int index = -1;
    if (media_type == VIDEO_TYPE) {
        if (mRecentLoadTypeVideoBandwidthInfo.size() <= mLoadTypeSlidingWindowSize) {
            return index;
        }
        int64_t timestamp_end = -1;
        for (int i = 0; i < mRecentLoadTypeVideoBandwidthInfo.size(); i ++) {
            if (mRecentLoadTypeVideoBandwidthInfo.at(i).end_timestamp >= timestamp_end) {
                index = i;
                timestamp_end = mRecentLoadTypeVideoBandwidthInfo.at(i).end_timestamp;
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        if (mRecentLoadTypeAudioBandwidthInfo.size() <= mLoadTypeSlidingWindowSize) {
            return index;
        }
        int64_t timestamp_end = -1;
        for (int i = 0; i < mRecentLoadTypeAudioBandwidthInfo.size(); i ++) {
            if (mRecentLoadTypeAudioBandwidthInfo.at(i).end_timestamp >= timestamp_end) {
                index = i;
                timestamp_end = mRecentLoadTypeAudioBandwidthInfo.at(i).end_timestamp;
            }
        }
    } else {
        //pass
    }
    return index;
}

void abrHANetSpeedPredictor::updateStreamBandwidthInfo(std::string stream_id, float stream_download_speed, int64_t timestamp_start, int64_t timestamp_end, int media_type) {
    if (media_type == VIDEO_TYPE) {
        int stream_index = findStreamIndex(stream_id, VIDEO_TYPE);
        int stream_failed_index = findStreamFailedIndex(VIDEO_TYPE);

        if (stream_index > 0) {
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                mRecentStreamVideoBandwidthInfo[stream_index].end_timestamp = timestamp_end;
                mRecentStreamVideoBandwidthInfo[stream_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentStreamVideoBandwidthInfo[stream_index].mRecentTimestamp.push_back(timestamp_start);
                if(mRecentStreamVideoBandwidthInfo[stream_index].mRecentBandwidth.size() > mBandwidthSlidingWindowSize) {
                    std::vector<float>::iterator k = mRecentStreamVideoBandwidthInfo[stream_index].mRecentBandwidth.begin();
                    mRecentStreamVideoBandwidthInfo[stream_index].mRecentBandwidth.erase(k);
                }
                if(mRecentStreamVideoBandwidthInfo[stream_index].mRecentTimestamp.size() > mBandwidthSlidingWindowSize) {
                    std::vector<int64_t>::iterator k = mRecentStreamVideoBandwidthInfo[stream_index].mRecentTimestamp.begin();
                    mRecentStreamVideoBandwidthInfo[stream_index].mRecentTimestamp.erase(k);
                }
            }
        } else if (stream_failed_index > 0) {
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                mRecentStreamVideoBandwidthInfo[stream_failed_index].stream_id = stream_id;
                mRecentStreamVideoBandwidthInfo[stream_failed_index].end_timestamp = timestamp_end;
                mRecentStreamVideoBandwidthInfo[stream_failed_index].mRecentBandwidth.clear();
                mRecentStreamVideoBandwidthInfo[stream_failed_index].mRecentTimestamp.clear();
                mRecentStreamVideoBandwidthInfo[stream_failed_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentStreamVideoBandwidthInfo[stream_failed_index].mRecentTimestamp.push_back(timestamp_start);
            }
        } else {  // new
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                StreamMediaBandwidthInfo recent_stream_video_bandwidth_info;
                recent_stream_video_bandwidth_info.stream_id = stream_id;
                recent_stream_video_bandwidth_info.end_timestamp = timestamp_end;
                recent_stream_video_bandwidth_info.mRecentBandwidth.clear();
                recent_stream_video_bandwidth_info.mRecentTimestamp.clear();
                recent_stream_video_bandwidth_info.mRecentBandwidth.push_back(instantBandwidth);
                recent_stream_video_bandwidth_info.mRecentTimestamp.push_back(timestamp_start);
                mRecentStreamVideoBandwidthInfo.push_back(recent_stream_video_bandwidth_info);
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        int stream_index = findStreamIndex(stream_id, AUDIO_TYPE);
        int stream_failed_index = findStreamFailedIndex(AUDIO_TYPE);

        if (stream_index > 0) {
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                mRecentStreamAudioBandwidthInfo[stream_index].end_timestamp = timestamp_end;
                mRecentStreamAudioBandwidthInfo[stream_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentStreamAudioBandwidthInfo[stream_index].mRecentTimestamp.push_back(timestamp_start);
                if(mRecentStreamAudioBandwidthInfo[stream_index].mRecentBandwidth.size() > mBandwidthSlidingWindowSize) {
                    std::vector<float>::iterator k = mRecentStreamAudioBandwidthInfo[stream_index].mRecentBandwidth.begin();
                    mRecentStreamAudioBandwidthInfo[stream_index].mRecentBandwidth.erase(k);
                }
                if(mRecentStreamAudioBandwidthInfo[stream_index].mRecentTimestamp.size() > mBandwidthSlidingWindowSize) {
                    std::vector<int64_t>::iterator k = mRecentStreamAudioBandwidthInfo[stream_index].mRecentTimestamp.begin();
                    mRecentStreamAudioBandwidthInfo[stream_index].mRecentTimestamp.erase(k);
                }
            }
        } else if (stream_failed_index > 0) {
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                mRecentStreamAudioBandwidthInfo[stream_failed_index].stream_id = stream_id;
                mRecentStreamAudioBandwidthInfo[stream_failed_index].end_timestamp = timestamp_end;
                mRecentStreamAudioBandwidthInfo[stream_failed_index].mRecentBandwidth.clear();
                mRecentStreamAudioBandwidthInfo[stream_failed_index].mRecentTimestamp.clear();
                mRecentStreamAudioBandwidthInfo[stream_failed_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentStreamAudioBandwidthInfo[stream_failed_index].mRecentTimestamp.push_back(timestamp_start);
            }
        } else {  // new
            if (stream_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = stream_download_speed;
                StreamMediaBandwidthInfo recent_stream_audio_bandwidth_info;
                recent_stream_audio_bandwidth_info.stream_id = stream_id;
                recent_stream_audio_bandwidth_info.end_timestamp = timestamp_end;
                recent_stream_audio_bandwidth_info.mRecentBandwidth.clear();
                recent_stream_audio_bandwidth_info.mRecentTimestamp.clear();
                recent_stream_audio_bandwidth_info.mRecentBandwidth.push_back(instantBandwidth);
                recent_stream_audio_bandwidth_info.mRecentTimestamp.push_back(timestamp_start);
                mRecentStreamAudioBandwidthInfo.push_back(recent_stream_audio_bandwidth_info);
            }
        }
    } else {
        //pass
    }
}

void abrHANetSpeedPredictor::updateLoadTypeBandwidthInfo(std::string load_type, float load_type_download_speed, int64_t timestamp_start, int64_t timestamp_end, int media_type) {
    if (media_type == VIDEO_TYPE) {
        int load_type_index = findLoadTypeIndex(load_type, VIDEO_TYPE);
        int load_type_failed_index = findLoadTypeFailedIndex(VIDEO_TYPE);

        if (load_type_index > 0) {
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                mRecentLoadTypeVideoBandwidthInfo[load_type_index].end_timestamp = timestamp_end;
                mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentTimestamp.push_back(timestamp_start);
                if(mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentBandwidth.size() > mBandwidthSlidingWindowSize) {
                    std::vector<float>::iterator k = mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentBandwidth.begin();
                    mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentBandwidth.erase(k);
                }
                if(mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentTimestamp.size() > mBandwidthSlidingWindowSize) {
                    std::vector<int64_t>::iterator k = mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentTimestamp.begin();
                    mRecentLoadTypeVideoBandwidthInfo[load_type_index].mRecentTimestamp.erase(k);
                }
            }
        } else if (load_type_failed_index > 0) {
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].load_type = load_type;
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].end_timestamp = timestamp_end;
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].mRecentBandwidth.clear();
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].mRecentTimestamp.clear();
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentLoadTypeVideoBandwidthInfo[load_type_failed_index].mRecentTimestamp.push_back(timestamp_start);
            }
        } else {  // new
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                LoadTypeMediaBandwidthInfo recent_load_type_video_bandwidth_info;
                recent_load_type_video_bandwidth_info.load_type = load_type;
                recent_load_type_video_bandwidth_info.end_timestamp = timestamp_end;
                recent_load_type_video_bandwidth_info.mRecentBandwidth.clear();
                recent_load_type_video_bandwidth_info.mRecentTimestamp.clear();
                recent_load_type_video_bandwidth_info.mRecentBandwidth.push_back(instantBandwidth);
                recent_load_type_video_bandwidth_info.mRecentTimestamp.push_back(timestamp_start);
                mRecentLoadTypeVideoBandwidthInfo.push_back(recent_load_type_video_bandwidth_info);
            }
        }
    } else if (media_type == AUDIO_TYPE) {
        int load_type_index = findLoadTypeIndex(load_type, AUDIO_TYPE);
        int load_type_failed_index = findLoadTypeFailedIndex(AUDIO_TYPE);

        if (load_type_index > 0) {
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                mRecentLoadTypeAudioBandwidthInfo[load_type_index].end_timestamp = timestamp_end;
                mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentTimestamp.push_back(timestamp_start);
                if(mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentBandwidth.size() > mBandwidthSlidingWindowSize) {
                    std::vector<float>::iterator k = mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentBandwidth.begin();
                    mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentBandwidth.erase(k);
                }
                if(mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentTimestamp.size() > mBandwidthSlidingWindowSize) {
                    std::vector<int64_t>::iterator k = mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentTimestamp.begin();
                    mRecentLoadTypeAudioBandwidthInfo[load_type_index].mRecentTimestamp.erase(k);
                }
            }
        } else if (load_type_failed_index > 0) {
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].load_type = load_type;
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].end_timestamp = timestamp_end;
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].mRecentBandwidth.clear();
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].mRecentTimestamp.clear();
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].mRecentBandwidth.push_back(instantBandwidth);
                mRecentLoadTypeAudioBandwidthInfo[load_type_failed_index].mRecentTimestamp.push_back(timestamp_start);
            }
        } else {  // new
            if (load_type_download_speed > MINIMUM_SPEED ) {// Add a filter to solve the no download slot > 5 kBps <=> 40000 bps
                float instantBandwidth = load_type_download_speed;
                LoadTypeMediaBandwidthInfo recent_load_type_audio_bandwidth_info;
                recent_load_type_audio_bandwidth_info.load_type = load_type;
                recent_load_type_audio_bandwidth_info.end_timestamp = timestamp_end;
                recent_load_type_audio_bandwidth_info.mRecentBandwidth.clear();
                recent_load_type_audio_bandwidth_info.mRecentTimestamp.clear();
                recent_load_type_audio_bandwidth_info.mRecentBandwidth.push_back(instantBandwidth);
                recent_load_type_audio_bandwidth_info.mRecentTimestamp.push_back(timestamp_start);
                mRecentLoadTypeAudioBandwidthInfo.push_back(recent_load_type_audio_bandwidth_info);
            }
        }
    } else {
        //pass
    }
}

NETWORKPREDICT_NAMESPACE_END
