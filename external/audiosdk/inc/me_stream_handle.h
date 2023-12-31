//
// Created by chenmanjia on 2020/12/17.
//
#pragma once
#include "mammon_engine_defs.h"
#include "me_audiostream.h"
#include <string>

#ifndef AUDIO_EFFECT_ME_STREAM_HANDLE_H
#define AUDIO_EFFECT_ME_STREAM_HANDLE_H

using namespace std;

MAMMON_ENGINE_NAMESPACE_BEGIN

class StreamHandle {
public:
    virtual size_t StreamHandleProcess(AudioStream& stream, size_t frame_size) = 0;
    virtual const string name() {
        return "default";
    }
    virtual ~StreamHandle() = default;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_ME_STREAM_HANDLE_H
