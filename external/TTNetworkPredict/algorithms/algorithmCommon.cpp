//
// Created by wangchao on 2020/12/18.
//
#include "algorithmCommon.h"

NETWORKPREDICT_NAMESPACE_BEGIN


void updateMultidimensionalFakeMediaDownloadSpeed(NetworkSpeedResultVec &multi_dimensinal_download_speed, std::map<std::string, int> &media_info, bool missing, std::string current_stream_id, int media_type) {
    // If there is no video info updated currently, we need to generate a fake download speed result to guarantee that the uploading video and audio speed have the same sample_time_interval.
    if (missing) {
        std::string stream_id = "-1";
        auto media_info_item = media_info.find(current_stream_id);
        if (media_info_item == media_info.end()) {
            media_info_item = media_info.begin();
            while (media_info_item != media_info.end()) {
                if(media_info_item->second == media_type) {
                    stream_id = media_info_item->first;
                    break;
                }
                media_info_item ++;
            }
            if (media_info_item == media_info.end()) {
                LOGD("[SelectorLog] Error. There is no stream id in the currently playing media_info");
                if (media_info.empty()) {
                    LOGD("[SelectorLog] Error. The currently playing media_info is empty");
                }
            }
        } else {
            stream_id = media_info_item->first;
        }
        NetworkSpeedResult *p_network_speed_result = new NetworkSpeedResult();
        std::shared_ptr<NetworkSpeedResult> network_speed_result(p_network_speed_result);
        network_speed_result->fileId = stream_id;
        NetworkSpeedResultItemVec result_item_collection;
        std::shared_ptr<NetworkSpeedResultItem> result_item = std::make_shared<NetworkSpeedResultItem>("-1", "-1", -1.0, media_type);
        result_item_collection.push_back(result_item);
        network_speed_result->speedResultItems = result_item_collection;
        multi_dimensinal_download_speed.push_back(network_speed_result);
    }
}

void updateMultidimensionalDownloadSpeed(DowloadInfoMap &existed_multidimensional_info, NetworkSpeedResultVec &multidimensional_download_speed, std::string file_id, std::string load_type, uint64_t bytes, int64_t start_timestamp, int64_t end_timestamp, std::string host, int track_type) {
    DownloadInfo download_info;
    download_info.loadType = load_type;
    download_info.host = host;
    download_info.bytes = bytes;
    download_info.start_timestamp = start_timestamp;
    download_info.end_timestamp = end_timestamp;
    download_info.trackType = track_type;

    DowloadInfoMap::iterator iter_existed_download_info = existed_multidimensional_info.find(file_id);
    if (iter_existed_download_info == existed_multidimensional_info.end()) {
        NetworkSpeedResult *p_network_speed_result = new NetworkSpeedResult();
        std::shared_ptr<NetworkSpeedResult> network_speed_result(p_network_speed_result);
        network_speed_result->fileId = file_id;
        NetworkSpeedResultItemVec result_item_collection;
        int64_t cost_time = end_timestamp - start_timestamp;
        float download_speed = cost_time > 0 ? (static_cast<float>(bytes) * BYTE_IN_B * M_IN_K / cost_time) : 0;
        std::shared_ptr<NetworkSpeedResultItem> result_item = std::make_shared<NetworkSpeedResultItem>(load_type, host, download_speed, track_type);
        result_item_collection.push_back(result_item);
        network_speed_result->speedResultItems = result_item_collection;
        multidimensional_download_speed.push_back(network_speed_result);
        std::vector<DownloadInfo> vec_download_info;
        vec_download_info.push_back(download_info);
        existed_multidimensional_info.insert(std::make_pair(file_id, vec_download_info));
    } else {
        int64_t new_start_timestamp = start_timestamp;
        int64_t new_end_timestamp = end_timestamp;
        uint64_t new_bytes = bytes;
        DownloadInfoVec::iterator iter_existed_download_info_item = iter_existed_download_info->second.begin();

        NetworkSpeedResultVec::iterator iter_network_speed_result = multidimensional_download_speed.begin();
        while (iter_network_speed_result != multidimensional_download_speed.end()) {
            if(file_id == iter_network_speed_result->get()->fileId) {
                break;
            }
            iter_network_speed_result ++;
        }
        if (iter_network_speed_result == multidimensional_download_speed.end()) {
            LOGD("[SelectorLog][ANet] Error. Can't find %s in multidimensional_download_speed", file_id.c_str());
            return;
        }
        int index = 0;
        int removed_item_count = 0;
        while (iter_existed_download_info_item != iter_existed_download_info->second.end()) {
            if (load_type == iter_existed_download_info_item->loadType && host == iter_existed_download_info_item->host) {
                if (new_start_timestamp < iter_existed_download_info_item->end_timestamp || new_end_timestamp > iter_existed_download_info_item->start_timestamp) {
                    new_start_timestamp = new_start_timestamp < iter_existed_download_info_item->start_timestamp ? new_start_timestamp : iter_existed_download_info_item->start_timestamp;
                    new_end_timestamp = new_end_timestamp > iter_existed_download_info_item->end_timestamp ? new_end_timestamp : iter_existed_download_info_item->end_timestamp;
                    new_bytes += iter_existed_download_info_item->bytes;
                    iter_existed_download_info_item = iter_existed_download_info->second.erase(iter_existed_download_info_item);
                    if ((iter_network_speed_result->get()->speedResultItems).size() <= index - removed_item_count) {
                        LOGD("[SelectorLog][ANet] Error. Size of speed records of %s in existed_multidimensional_info doesn't match with multidimensional_download_speed", file_id.c_str());
                        return;
                    }
                    (iter_network_speed_result->get()->speedResultItems).erase((iter_network_speed_result->get()->speedResultItems).begin() + index - removed_item_count);
                    removed_item_count ++;
                } else {
                    iter_existed_download_info_item ++;
                }
            } else {
                iter_existed_download_info_item ++;
            }
            index ++;
        }
        iter_existed_download_info->second.push_back(download_info);
        int64_t new_cost_time = new_end_timestamp - new_start_timestamp;
        float download_speed = new_cost_time > 0 ? (static_cast<float>(new_bytes) * BYTE_IN_B * M_IN_K / new_cost_time) : 0;
        std::shared_ptr<NetworkSpeedResultItem> result_item = std::make_shared<NetworkSpeedResultItem>(load_type, host, download_speed, track_type);
        iter_network_speed_result->get()->speedResultItems.push_back(result_item);
    }
}

float getMediaAverageDownloadSpeed(int speed_type, float avg_speed, float avg_window_speed,
                                   float ema_speed,
                                   float ema_startup_speed,
                                   float ema_startup_end_speed) {
    float ret = -1;
    if (speed_type == AVERAGE_WINDOW_DOWNLOAD_SPEED) {
        ret = avg_window_speed;
    }else if (speed_type == AVERAGE_DOWNLOAD_SPEED) {
        ret = avg_speed;
    } else if (speed_type == AVERAGE_EMA_DOWNLOAD_SPEED) {
        ret = ema_speed;
    } else if (speed_type == AVERAGE_EMA_STARTUP_DOWNLOAD_SPEED) {
        ret = ema_startup_speed;
    } else if (speed_type == AVERAGE_EMA_STARTUP_END_DOWNLOAD_SPEED) {
        ret = ema_startup_end_speed;
    }

    LOGD("[SelectorLog] getMediaAverageDownloadSpeed speed_type:%d, vv_avg_speed:%f, avg_window_speed:%f "
         "ema_vv_speed:%f, ema_vv_startup_speed:%f, ema_vv_startup_end_speed:%f",
         speed_type, avg_speed, avg_window_speed, ema_speed, ema_startup_speed, ema_startup_end_speed);
    return ret;
}

void updateMediaAverageDownloadSpeed(float ewa_weight, int startup_window_size,
                                     const std::vector<float> &recent_bandwidth,
                                     const std::vector<float> &startup_speed,
                                     int call_count,
                                     const float avg_speed,
                                     const float avg_window_speed,
                                     float &ema_speed,
                                     float &ema_startup_speed,
                                     float &ema_startup_end_speed) {
    float avg_startup_speed = 0.0f;
    float avg_startup_end_speed = 0.0f;
    float avg_end_speed = 0.0f;

    if (!startup_speed.empty()) {
        avg_startup_speed = std::accumulate(std::begin(startup_speed),
                                            std::end(startup_speed), 0.0f) / startup_speed.size();
    }

    if (call_count > startup_window_size && call_count < startup_window_size * 2) {
        int min_window_size = (call_count - startup_window_size) > recent_bandwidth.size() ?
                              int(recent_bandwidth.size()) : (call_count - startup_window_size);
        if (min_window_size > 0) {
            avg_end_speed = std::accumulate(std::end(recent_bandwidth) - min_window_size,
                                        std::end(recent_bandwidth), 0.0f) / float(min_window_size);
        }
    } else if(call_count >= startup_window_size * 2) {
        int min_window_size = startup_window_size > recent_bandwidth.size() ?
                              int(recent_bandwidth.size()) : startup_window_size;
        if (min_window_size > 0) {
            avg_end_speed = std::accumulate(std::end(recent_bandwidth) - min_window_size,
                                        std::end(recent_bandwidth), 0.0f) / float(min_window_size);
        }
    }
    if (avg_startup_speed > 0.0f && avg_end_speed > 0.0f) {
        avg_startup_end_speed = (avg_startup_speed + avg_end_speed) / 2;
    } else if (avg_startup_speed > 0.0f) {
        avg_startup_end_speed = avg_startup_speed;
    } else if (avg_end_speed > 0.0f) {
        avg_startup_end_speed = avg_end_speed;
    }

    // Exponential moving average
    if (avg_speed > 0.0f && call_count > MIN_SPEED_COUNT) {
        ema_speed = ema_speed > 0 ? ewa_weight * ema_speed + (1 - ewa_weight) * avg_speed : avg_speed;
    }
    if (avg_startup_speed > 0.0f && call_count > MIN_SPEED_COUNT_ST) {
        ema_startup_speed = ema_startup_speed > 0 ?
                            ewa_weight * ema_startup_speed + (1 - ewa_weight) * avg_startup_speed :
                            avg_startup_speed;
    }
    if (avg_startup_end_speed > 0.0f && call_count > MIN_SPEED_COUNT) {
        ema_startup_end_speed = ema_startup_end_speed > 0 ?
                                ewa_weight * ema_startup_end_speed + (1 - ewa_weight) * avg_startup_end_speed :
                                avg_startup_end_speed;
    }

    LOGD("[SelectorLog] updateMediaAverageDownloadSpeed ewa_weight:%f, call_count:%d, "
         "avg_speed:%f, avg_window_speed:%f, avg_startup_speed:%f, avg_startup_end_speed:%f, "
         "ema_speed:%f, ema_vv_startup_speed:%f, ema_vv_startup_end_speed:%f",
         ewa_weight, call_count,
         avg_speed, avg_window_speed, avg_startup_speed, avg_startup_end_speed,
         ema_speed, ema_startup_speed, ema_startup_end_speed);
}

void resetMediaAverageDownloadSpeed(float &avg_speed, int &call_count, std::vector<float> &startup_speed) {
    // reset
    avg_speed = 0.0f;
    call_count = 0;
    startup_speed.clear();
    LOGD("[SelectorLog] resetMediaAverageDownloadSpeed");
}

void updateMediaDownloadSpeedInfo(const std::vector<float> &recent_bandwidth, float download_speed,
                                  int startup_window_size, float &media_avg_speed,
                                  float & media_avg_window_speed,
                                  int &media_call_count, std::vector<float> &media_startup_speed) {
    media_avg_speed = (media_call_count + 1) > 0 ?
                      (media_avg_speed * float(media_call_count) +
                       download_speed) / (float(media_call_count) + 1) : 0;
    if (!recent_bandwidth.empty()) {
        media_avg_window_speed = std::accumulate(std::begin(recent_bandwidth),
                                                 std::end(recent_bandwidth), 0.0f) / recent_bandwidth.size();
    }
    media_call_count++;
    if (media_startup_speed.size() < startup_window_size) {
        media_startup_speed.push_back(download_speed);
    }
}

void isExistMedia(std::map<std::string, int> &media_info, bool &exist_video, bool &exist_audio) {
    exist_video = false;
    exist_audio = false;
    std::map<std::string, int>::iterator media_info_item = media_info.begin();
    while (media_info_item != media_info.end()) {
        if (media_info_item->second == VIDEO_TYPE) {
            exist_video = true;
        } else if (media_info_item->second == AUDIO_TYPE) {
            exist_audio = true;
        }
        if (exist_video && exist_audio) {
            break;
        }
//        LOGD("[SelectorLog] [network] current playing stream_id:%s", media_info_item->first.c_str());
        media_info_item ++;
    }
}

float getAccuracy(SpeedInfo& speedInfo) {
    std::shared_ptr<SpeedRecordItem> speedRecord = speedInfo.speedRecord;
    if (speedInfo.speed <= MINIMUM_SPEED
        || speedInfo.speed >= MAXIMUM_SPEED
        || speedInfo.preload == 1
        || speedInfo.speedRecord->trackType == AUDIO_TYPE)
        return 0;
//    if (getIsRangeWork(speedInfo))
//        return 1;
    if (!getIsBlock(speedInfo, BLOCK_METHOD_SIMPLE))
        return 1;
    if (speedInfo.speedRecord->lastDataRecv > 0)
        return 0.5;
    else
        return 0;
}

bool getIsRangeWork(SpeedInfo& speedInfo) {
    std::shared_ptr<SpeedRecordItem> speedRecord = speedInfo.speedRecord;
    return speedRecord->s_off > 0
        && speedRecord->e_off > speedRecord->s_off
        && speedRecord->e_off - speedRecord->s_off < speedRecord->fbs;
}


bool getIsBlock(SpeedInfo& speedInfo, int method) {
    int buffer = speedInfo.buffer > 0 ? speedInfo.buffer : 0;
    std::shared_ptr<SpeedRecordItem> speedRecord = speedInfo.speedRecord;
    bool isBlock = false;
    bool isPlayerBlock = false;
    if (speedInfo.maxBuffer > 0)
        isPlayerBlock = double(buffer) / double(speedInfo.maxBuffer) > BLOCK_THRESHOLD;
    else
        isPlayerBlock = false;

    if (method == BLOCK_METHOD_SIMPLE) {
        isBlock = isPlayerBlock;
    } else {
        bool isMdlBlock = double(speedRecord->cbs) / double(speedRecord->fbs)  > BLOCK_THRESHOLD;
        isBlock = isMdlBlock || isPlayerBlock;
    }
    return isBlock;
}

NETWORKPREDICT_NAMESPACE_END


