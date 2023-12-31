//
// Created by wangchao on 2020/12/18.
//

#ifndef NETWORKPREDICT_ALGORITHMCOMMON_H
#define NETWORKPREDICT_ALGORITHMCOMMON_H

#include "INetworkSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include <vector>
#include <numeric>
#include <cmath>
#include <ctime>
#include <inttypes.h>
#include <unordered_map>

NETWORKPREDICT_NAMESPACE_BEGIN

void updateMultidimensionalFakeMediaDownloadSpeed(NetworkSpeedResultVec &multi_dimensinal_download_speed, std::map<std::string, int> &media_info, bool missing, std::string current_stream_id, int media_type);
void updateMultidimensionalDownloadSpeed(DowloadInfoMap &existed_multidimensional_info, NetworkSpeedResultVec &multidimensional_download_speed, std::string file_id, std::string load_type, uint64_t bytes, int64_t start_timestamp, int64_t end_timestamp, std::string host, int track_type);
void isExistMedia(std::map<std::string, int> &media_info, bool &exist_video, bool &exist_audio);
float getMediaAverageDownloadSpeed(int speed_type, float avg_speed, float avg_window_speed,
                                   float ema_speed,
                                   float ema_startup_speed,
                                   float ema_startup_end_speed);
void updateMediaAverageDownloadSpeed(float ewa_weight, int startup_window_size,
                                     const std::vector<float> &recent_bandwidth,
                                     const std::vector<float> &startup_speed,
                                     const int call_count,
                                     const float avg_speed,
                                     const float avg_window_speed,
                                     float &ema_speed,
                                     float &ema_startup_speed,
                                     float &ema_startup_end_speed);
void resetMediaAverageDownloadSpeed(float &avg_speed, int &call_count, std::vector<float> &startup_speed);
void updateMediaDownloadSpeedInfo(const std::vector<float> &recent_bandwidth, float download_speed,
                                  int startup_window_size, float &media_avg_speed, float &media_avg_window_speed,
                                  int &media_call_count, std::vector<float> &media_startup_speed);

float getAccuracy(SpeedInfo& speedInfo);

bool getIsRangeWork(SpeedInfo& speedInfo);

bool getIsBlock(SpeedInfo& speedInfo, int method);

NETWORKPREDICT_NAMESPACE_END


#endif //NETWORKPREDICT_ALGORITHMCOMMON_H
