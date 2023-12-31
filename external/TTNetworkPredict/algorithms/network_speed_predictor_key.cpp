//
//  abrNetSpeedKey.cpp
//  ABRNetSpeedModule
//
//  Created by shen chen on 2020/7/9.
//

#include "network_speed_predictor_key.h"

#include <utility>

com::bytedance::vcloud::networkPredict::SpeedInfo::SpeedInfo(float speed, bool preload, int buffer, int maxBuffer,
                                                             std::shared_ptr<SpeedRecordItem> speedRecord)
                                                             :speed(speed), preload(preload), buffer(buffer), maxBuffer(maxBuffer),
                                                             speedRecord(std::move(speedRecord)) {

}
