/**
 * @file bef_swing_segment_api.h
 * @author wangyu (wangyu.sky@bytedance.com)
 * @brief
 * @version 0.1
 * @date 2021-04-14
 *
 * @copyright Copyright (c) 2021
 *
 */

#ifndef bef_swing_segment_api_h
#define bef_swing_segment_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief create segment with segment type, do NOT add to any track or segment.
 * @param outSegmentHandle [out] instance of segment
 * @param type segment type
 * @param pString for feature segment pString is a resource path, for text or textTemplate is maybe a json string or a path, others maybe  empty
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_create(bef_swing_manager_t* managerHandle,
                         bef_swing_segment_t** outSegmentHandle,
                         bef_swing_segment_type type,
                         const char* pString);

/**
 * @brief create segment with segment type, do NOT add to any track or segment.
 * @param outSegmentHandle [out] instance of segment
 * @param type segment type
 * @param autorelease (true)delete segment if create with error code(default), (false) should manual call bef_swing_segment_destroy
 *                  we add this as destroy is not safe when preload segment in another thread.
 * @param pString for feature segment pString is a resource path, for text or textTemplate is maybe a json string or a path, others maybe  empty
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_create_safe(bef_swing_manager_t* managerHandle,
                         bef_swing_segment_t** outSegmentHandle,
                         bef_swing_segment_type type,
                         bool autorelease,
                         const char* pString);
/**
 * @brief destroy segment
 * @param segmentHandle instance of segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_destroy(bef_swing_segment_t* segmentHandle);

/**
 * @brief remove segment from track or other segment
 * @param segmentHandle instance of segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_remove(bef_swing_segment_t* segmentHandle);

/**
 * @brief create segment with type, and add to track
 * @param trackHandle instance of track
 * @param outSegmentHandle [out] instance of segment
 * @param type segment type
 * @param start start time of segment, in microsecond
 * @param end end time of segment, in microsecond
 * @param pString for feature segment pString is a resource path, for text or textTemplate is maybe a json string or a resource path, others maybe  empty
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_create_track_segment(bef_swing_track_t* trackHandle,
                                       bef_swing_segment_t** outSegmentHandle,
                                       bef_swing_segment_type type,
                                       bef_swing_time_t start,
                                       bef_swing_time_t end,
                                       const char* pString);

/**
 * @brief add segment to track, if segment is NOT in other track or segment
 * 
 * If segment contains child segments, time range shifting logic is the same as bef_swing_segment_set_time_range
 * 
 * @param trackHandle instance of track
 * @param segmentHandle instance of segment
 * @param start start time of segment, in microsecond
 * @param end end time of segment, in microsecond
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_add_to_track(bef_swing_track_t* trackHandle,
                               bef_swing_segment_t* segmentHandle,
                               bef_swing_time_t start,
                               bef_swing_time_t end);

/**
 * @brief set segment common params
 * @param segmentHandle instance of swing segment
 * @param jsonParamStr json params, e.g. {key:value, ...}
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_params(bef_swing_segment_t* segmentHandle,
                             const char* jsonParamStr);

/**
 * @brief reset segment common params
 * @param segmentHandle instance of swing segment
 * @param type reset type (note: type have been disuse)
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_reset(bef_swing_segment_t* segmentHandle,
                        bef_swing_reset_type type);

/**
 * @brief get segment common params. Must be freed by bef_swing_segment_free_params
 * @param segmentHandle instance of swing segment
 * @param jsonKeyStr json key
 * @param outJsonParamStr [out] json params, e.g. {key:value, ...}, string need deleted by users
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_get_params(bef_swing_segment_t* segmentHandle,
                             const char* jsonKeyStr,
                             char** outJsonParamStr);

/**
 * @brief free params string allocated by bef_swing_segment_get_params
 * 
 * @param paramStr params string
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_free_params(char* paramStr);

/**
 * @brief set time range of segment
 * 
 * If segment contains child segments, their time will be adjusted according to the
 * following rules:
 * 
 * - If parent segment start time changes, then all child segments will be shifted
 *   using the same delta time value.
 * - If parent segment end time changes, then AFTER start time change logic is applied,
 *   all child segments whose end time is bigger than the parent will be reset to the
 *   same endtime.
 * 
 * Example: Video segment time range [0, 1000000], embedded feature segment time range [200000, 800000].
 * After changing video segment time range to [300000, 900000], the feature segment time range will be
 * changed to [500000, 900000].
 * 
 * @param segmentHandle instance of segment
 * @param start start time of segment, in microsecond
 * @param end end time of segment, in microsecond
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_time_range(bef_swing_segment_t* segmentHandle,
                                 bef_swing_time_t start,
                                 bef_swing_time_t end);

/**
 * @brief set time range of segment, relative to parent START time
 * 
 * If parent segment time range is [t1, t2], then calling bef_swing_segment_set_relative_time_range
 * with a time range of [t3, t4] is equivalent to calling bef_swing_segment_set_time_range on the
 * same segment with a time range of [t1 + t3, t1 + t4].
 * 
 * If segment does not belong to any parent segment, then this function is the same as
 * bef_swing_segment_set_time_range.
 * 
 * @param segmentHandle instance of segment
 * @param start relative start time of segment, in microsecond
 * @param end relative end time of segment, in microsecond
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_relative_time_range(bef_swing_segment_t* segmentHandle,
                                          bef_swing_time_t start,
                                          bef_swing_time_t end);

/**
 * @brief set source time range of segment
 * 
 * The source time range corresponds to the source_time_range entry of drafts and is interpreted
 * differently by different segment types.
 * 
 * Currently only video segments make use of this property, which is interpreted as video pts which are
 * trimming, speed adjustment & similar actions. It does not affect video rendering but changes how the
 * video segment handles attached entities (e.g. object trackers).
 * 
 * @param segmentHandle segment handle
 * @param start source start time of segment, in microseconds
 * @param end source end time of segment, in microseconds
 * @return bef_effect_result_t error code 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_source_time_range(bef_swing_segment_t* segmentHandle,
                                        bef_swing_time_t start,
                                        bef_swing_time_t end);

/**
 * @brief enable/disable segment
 * @param segmentHandle instance of segment
 * @param enable true = enable, false = disable
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_enabled(bef_swing_segment_t* segmentHandle,
                              bool enable);

#endif /* bef_swing_segment_api_h */
