/**
 * @file bef_swing_tracker_api.h
 * @author guoxingjian (guoxingjian@bytedance.com)
 * @brief new tracking API based on Swing
 * @version 0.1
 * @date 2022-01-17
 * 
 * Swing tracking module
 * 
 * @copyright Copyright (c) 2022
 * 
 */

#pragma once

#include "bef_swing_define.h"

// --------------------------
// Tracker APIs

/**
 * @brief create swing tracker
 * 
 * Certain types of tracker are bound to a specific video segment.
 * 
 * @param trackerType type of tracker
 * @param[out] outTrackerHandle created tracker handle
 * @param[optional] videoHandle instance of video segment associated with the tracker
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_create(bef_swing_tracker_type trackerType,
                         bef_swing_tracker_t** outTrackerHandle,
                         bef_swing_segment_t* trackingVideoHandle);

/**
 * @brief destroy tracker and release all resources
 * @param trackerHandle tracker handle
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_destroy(bef_swing_tracker_t* trackerHandle);

/**
 * @brief add tracking data to a tracker
 * 
 * Supported data types vary depending on the tracker type.
 * Can be called multiple times.
 * 
 * @param trackerHandle tracker handle
 * @param trackingBuffer tracking data buffer
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_add_tracking_data(bef_swing_tracker_t* trackerHandle,
                                    const void* trackingBuffer);

/**
 * @brief bulk set tracker data using serialized results
 * @param trackerHandle tracker handle
 * @param trackingData serialized tracking data
 * @param trackingDataSize size in bytes of trackingData
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_set_serialized_tracking_data(bef_swing_tracker_t* trackerHandle,
                                               const void* trackingData,
                                               int trackingDataSize);

/**
 * @brief get tracker data at a given timestamp
 * 
 * The returned tracking buffer follows the same convention as bef_swing_tracker_add_tracking_data.
 * i.e. adding the returned buffer back into the tracker should not affect anything.
 * 
 * If not at a key timestamp, the returned buffer is interpolated using the nearest
 * key timestamp results.
 * 
 * @param trackerHandle tracker handle
 * @param timestamp current timestamp
 * @param[out] outTrackingBuffer returned tracking buffer
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_get_tracking_data(bef_swing_tracker_t* trackerHandle,
                                    bef_swing_time_t timestamp,
                                    void** outTrackingBuffer);

/**
 * @brief get serialized tracking data
 * @param trackerHandle tracker handle
 * @param[out] outTrackingData returned data
 * @param[out] outTrackingDataSize size of returned data
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_get_serialized_tracking_data(bef_swing_tracker_t* trackerHandle,
                                               void** outTrackingData,
                                               int* outTrackingDataSize);

/**
 * @brief merge two trackers' data
 * 
 * Note: this API does not modify any tracker-segment bindings
 * 
 * @param target tracker handle whose data will be modified
 * @param source tracker handle whose data will be added to the target
 * @param mode merge mode enum
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_merge(bef_swing_tracker_t* target,
                        bef_swing_tracker_t* source,
                        bef_swing_tracker_merge_mode mode);

// --------------------------
// Segment binding APIs

/**
 * @brief bind tracker to a segment
 * 
 * NOTE: a tracker can bind to multiple segments and vice versa
 * 
 * @param segmentHandle binding segment handle
 * @param trackerHandle tracker handle
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_bind_tracker(bef_swing_segment_t* segmentHandle,
                               bef_swing_tracker_t* trackerHandle);

/**
 * @brief unbind tracker with a bound segment
 * 
 * Does nothing if the segment is not bound to the tracker.
 * 
 * @param segmentHandle segment handle
 * @param trackerHandle tracker handle
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_unbind_tracker(bef_swing_segment_t* segmentHandle,
                                 bef_swing_tracker_t* trackerHandle);

/**
 * @brief unbind segment from all trackers
 * @param segmentHandle segment handle
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_unbind_all_trackers(bef_swing_segment_t* segmentHandle);

/**
 * @brief set tracking mode
 * 
 * The tracking mode can be OR'ed to form compound tracking modes.
 * e.g. SWING_TRACKING_FOLLOW_POSITION | SWING_TRACKING_FOLLOW_ROTATION means to
 * follow BOTH position and rotation of the tracked element.
 * 
 * @param segmentHandle segment handle
 * @param mode tracking mode
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_set_tracking_mode(bef_swing_segment_t* segmentHandle,
                                    bef_swing_tracking_mode mode);

/**
 * @brief transform current segment TRS set by user to baseline TRS
 * 
 * This API is needed when the user drags the tracking segment on the monitor, where
 * the user's selected bbox needs to be translated into new baseline TRS value.
 * 
 * @param segmentHandle segment handle
 * @param timestamp current timestamp in microseconds
 * @param currentTRS current segment TRS structure
 * @param[out] outBaselineTRS new segment baseline TRS corresponding to currentTRS
 * @return bef_effect_result_t error code 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_get_tracking_baseline_trs_from_current(bef_swing_segment_t* segmentHandle,
                                                         bef_swing_time_t timestamp,
                                                         bef_swing_trs* currentTRS,
                                                         bef_swing_trs* outBaselineTRS);

// --------------------------
// Utility APIs
// These APIs do not rely on a running SwingManager instance and are used to circumvent
// scenarios where acess to tracker/tracking segment is restricted.

/**
 * @brief get valid regions array from serialized tracking data (for displaying tracker lines)
 * 
 * A valid regions [tstart, tend) means all tracking points in this region have successful
 * tracking status
 * 
 * For example (... stands for tracking object lost）
 *   t0 --- t1 ... t2 --- t3 ... t4 --- t5
 * returns the following array
 *   [(t0, t1), (t2, t3), (t4, t5)]
 * 
 * @param trackingData serialized tracking data
 * @param trackingDataSize size in bytes of trackingData
 * @param[out] outValidRegions returned valid regions array
 * @param[out] outValidRegionsLength length of the returned valid regions array
 * @return bef_effect_result_t error code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_get_valid_regions(const void* trackingData,
                                    int trackingDataSize,
                                    bef_swing_tracker_valid_region** outValidRegions,
                                    int* outValidRegionsLength);

/**
 * @brief convert tracker serialized data to old pin serialized data
 * 
 * Only needed when both the old PIN API and the new tracking API coexists. Can be deprecated once
 * the former is no longer used.
 * 
 * @param trackingSegmentInfo structure containing information about the tracking segment & canvas
 * @param trackerVideoInfoArr array of structures containing information about tracked video segments and tracker data
 * @param trackerVideoInfoArrLength size of the tracker information structure array
 * @param[out] outTrackingData returned old pin serialized data
 * @param[out] outTrackingDataSize size in bytes of the returned serialized data
 * @return bef_effect_result_t error code 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_tracker_convert_to_old_pin_data(bef_swing_tracking_segment_info* trackingSegmentInfo,
                                          bef_swing_tracker_and_video_info* trackerVideoInfoArr,
                                          int trackerVideoInfoArrLength,
                                          void** outTrackingData,
                                          int* outTrackingDataSize);
