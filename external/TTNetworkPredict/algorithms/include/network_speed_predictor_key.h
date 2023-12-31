//
//  networkPredictKey.hpp
//  networkPredictModule
//
//  Created by shen chen on 2020/7/9.
//

#ifndef networkPredictKey_H
#define networkPredictKey_H

#include <stdio.h>
#include <vector>
#include <map>
#include <string>
#include "network_speed_pedictor_base.h"
#include <memory>
#include <NetworkSpeedRecord.h>
#include "NetworkSpeedResult.h"

NETWORKPREDICT_NAMESPACE_BEGIN

#define AUDIO_TYPE 1
#define VIDEO_TYPE 0

#define AVERAGE_WINDOW_DOWNLOAD_SPEED 0
#define AVERAGE_DOWNLOAD_SPEED 1
#define AVERAGE_EMA_DOWNLOAD_SPEED 2
#define AVERAGE_EMA_STARTUP_DOWNLOAD_SPEED 3
#define AVERAGE_EMA_STARTUP_END_DOWNLOAD_SPEED 4

typedef struct StreamMediaBandwidthInfo {
    std::string stream_id;
    int64_t end_timestamp;
    std::vector<float> mRecentBandwidth;
    std::vector<int64_t> mRecentTimestamp;
} StreamMediaBandwidthInfo;

typedef struct LoadTypeMediaBandwidthInfo {
    std::string load_type;
    int64_t end_timestamp;
    std::vector<float> mRecentBandwidth;
    std::vector<int64_t> mRecentTimestamp;
} LoadTypeMediaBandwidthInfo;

typedef struct DownloadInfo{
    std::string loadType;
    std::string host;
    uint64_t bytes;
    int64_t start_timestamp;
    int64_t end_timestamp;
    int trackType;
} DownloadInfo;

typedef struct SpeedInfo{
    SpeedInfo(float speed, bool preload, int buffer, int maxBuffer, std::shared_ptr<SpeedRecordItem> speedRecord);
    float speed;
    int preload;
    int buffer;
    int maxBuffer;
    std::shared_ptr<SpeedRecordItem> speedRecord;
} SpeedInfo;

typedef std::vector<std::shared_ptr<NetworkSpeedResult>> NetworkSpeedResultVec;
typedef std::vector<std::shared_ptr<NetworkSpeedResultItem>> NetworkSpeedResultItemVec;
typedef std::map<std::string, std::vector<DownloadInfo>> DowloadInfoMap;
typedef std::vector<DownloadInfo> DownloadInfoVec;

#define MAX_TIMESTAMP 9999999999999
#define M_IN_B 1000000.0f
#define M_IN_K 1000.0f
#define BYTE_IN_B 8.0f
#define MINIMUM_SPEED 40000
#define MAXIMUM_SPEED 1000000000

#define STARTUP_WINDOWSIZE 6
#define MIN_SPEED_COUNT 0
#define MIN_SPEED_COUNT_ST 0
#define EMA_WEIGHT 0.4f

#define BLOCK_THRESHOLD 0.95
#define SCALED_SPEED_LEN 100

#define BLOCK_METHOD_SIMPLE 0
#define BLOCK_METHOD_COMPLEX 1

NETWORKPREDICT_NAMESPACE_END
#endif /* networkPredictKey_hpp */
