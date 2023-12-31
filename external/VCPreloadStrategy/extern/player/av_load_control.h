//
// av_load_control.h
// Created by teddy on 2020/5/26.
// Created by wangchen.sh on 2020/7/27.
//

#pragma once

#include "av_player_event_base.h"
#include <stdint.h>

PEV_NAMESPACE_BEGIN

class LoadControlInterface {
public:
    // Using default construct method with shallow copy
    // return src frame if failure.
    virtual bool shouldStartPlayback(int64_t bufferedDurationMs,
                                     float playbackSpeed,
                                     bool rebuffering) = 0;

    virtual int onTrackSelected(int trackType) = 0;

    virtual int onCodecStackSelected(int trackType) = 0;

    virtual int onFilterStackSelected(int trackType) = 0;

    virtual ~LoadControlInterface() {}
};

PEV_NAMESPACE_END
