//
// Created by ByteDance on 2022/9/30.
//

#ifndef VIDEOENGINE_VC_EVENT_LOG_KEYS_H
#define VIDEOENGINE_VC_EVENT_LOG_KEYS_H
#pragma once

#include "vc_base.h"

VC_NAMESPACE_BEGIN

namespace eventlog {
extern const char* TAG;

// eventlog name
extern const char* LOG_KEY_THROWS;                    // st_throws
extern const char* LOG_KEY_PLAY_TASK_CONTROL;         // st_play_task_op
extern const char* LOG_KEY_PRELOAD;                   // st_preload
extern const char* LOG_KEY_BUFFER_DURATION;           // st_buf_dur
extern const char* LOG_KEY_PRELOAD_PERSONALIZED;      // st_preload_personalized
extern const char* LOG_KEY_ADAPTIVE_RANGE;            // st_adaptive_range
extern const char* LOG_KEY_REMAINING_BUFFER_DURATION; // st_remaining_buf_dur
extern const char* LOG_KEY_PRELOAD_FINISHED_TIME; // st_preload_finished_time
extern const char* LOG_KEY_BANDWIDTH_RANGE;       // st_band_range
extern const char* LOG_KEY_COMMON_EVENT_LOG;      // st_common
extern const char* LOG_KEY_PRELOAD_DECISION_INFO; // st_preload_decision
extern const char* LOG_KEY_PRELOAD_STRATEGY;      // st_preload_sc_info

// eventlog name add
extern const char* LOG_KEY_NET_SPEED;

// st_play_task_op
extern const char* PAUSE;
extern const char* RESUME;
extern const char* RANGE;
extern const char* RANGE_DURATION;
extern const char* TARGET_BUFFER;
extern const char* SAFE_FACTOR;
extern const char* SEEKLABEL;
extern const char* FIRST_BLOCK_DECISION_TIME;
extern const char* FIRST_BLOCK_EXEC_TIME;
extern const char* EST_PLAYTIME;
extern const char* SMART_LEVEL;

// st_buf_dur
extern const char* LOG_KEY_STARTUP_BUFFER_DURATION;
extern const char* LOG_KEY_RE_BUFFER_DURATION_INITIAL;
extern const char* LOG_KEY_PLAY_BUFFER_DIFF_COUNT;
extern const char* LOG_KEY_STARTUP_CACHE_SIZE;
extern const char* LOG_KEY_LOAD_CONTROL_VERSION;
extern const char* LOG_KEY_LOAD_CONTROL_SLIDING_WINDOW;

// st_preload_personalized
extern const char* LOG_KEY_PRELOAD_PERSONALIZED_OPTION;
extern const char* LOG_KEY_WATCH_DURATION_LABEL;
extern const char* LOG_KEY_STALL_LABEL;
extern const char* LOG_KEY_FIRST_FRAME_LABEL;

// st_adaptive_range
extern const char* LOG_KEY_ADAPTIVE_RANGE_ENABLED;
extern const char* LOG_KEY_ADAPTIVE_RANGE_BUFFER_LOG;

// st_band_range
extern const char* LOG_KEY_CURRENT_BANDWIDTH;
extern const char* LOG_KEY_BANDWIDTH_BITRATE_RATIO;

// st_common
extern const char* LOG_KEY_MODULE_ACTIVATED;

// st_bandwidth
extern const char* LOG_KEY_SPEED_FIRST_FRAME;
extern const char* LOG_KEY_SPEED_TOTAL_AVG;
extern const char* LOG_KEY_SPEED_TOTAL_STD;
extern const char* LOG_KEY_SPEED_BLOCK_AVG;
extern const char* LOG_KEY_SPEED_BLOCK_STD;
extern const char* LOG_KEY_SPEED_LAST_BUF_START;
}; // namespace eventlog

VC_NAMESPACE_END
#endif // VIDEOENGINE_VC_EVENT_LOG_KEYS_H
