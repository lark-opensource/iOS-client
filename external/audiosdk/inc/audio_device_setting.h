//
// Created by manjia on 2020/11/22.
//
#pragma once
#include "ae_audio_status.h"

using namespace std;

namespace mammonengine {

class AudioDeviceSettings {
public:
    bool low_latency;
    size_t sample_rate;
    size_t frame_size;
    size_t channel;
};

}