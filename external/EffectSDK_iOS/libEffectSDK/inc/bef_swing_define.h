/**
 * @file bef_swing_define.h
 * @author wangyu (wangyu.sky@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-04-14
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_define_h
#define bef_swing_define_h

#pragma once

#include "bef_info_sticker_api.h" // bef_InfoSticker_*

typedef void bef_swing_manager_t;
typedef void bef_swing_track_t;
typedef void bef_swing_segment_t;
typedef void bef_swing_keyframe_t;
typedef void bef_swing_tracker_t;
typedef void bef_keyframe_t; // handle of kerFrame system

typedef double SwingTimeInSec;   // old time format, in second as double
typedef long long SwingTimeInUS; // new time format, in microsecond as int64_t
typedef SwingTimeInUS bef_swing_time_t;

#define USOperator 1000000.0
#define USToSec(t) SwingTimeInSec(t < 0 ? -1.0 : (SwingTimeInSec)(t) / USOperator)
#define USToSecWithNegative(t) SwingTimeInSec((SwingTimeInSec)(t) / USOperator)
#define SecToUS(t) SwingTimeInUS(t < 0.0 ? -1 : (SwingTimeInUS)(t * USOperator))

enum SwingSegmentType
{
    NONE = -1,
    FEATURE = 0, // amazing feature
    EFFECT,      // effect feature
    STICKER,     // info sticker sprite
    TEXT,        // info sticker text
    TEMPLATE,    // info sticker template
    EMOJI,       // info sticker emoji
    CUSTOM,      // custom segment
    VIDEO,       // video segment
    TRANSITION,  // transition segment
    BRUSH,       // brush segment
    SCRIPT       // script template segment
};
typedef enum SwingSegmentType bef_swing_segment_type;

// video source type, mainly use:
// 1. reuse algorithm result if vidoe source is IMAGE.
// 2. set algorithm parameter, specially for matting with VideoMode or not.
enum VideoType
{
    NORMAL = 0, // normal source video
    IMAGE       // source video created from image.
};
typedef enum VideoType bef_video_type;

struct VideoTransform
{
    float positionX;
    float positionY;
    float scaleX;
    float scaleY;
    float rotationX;
    float rotationY;
    float rotationZ;
    bool flipX;
    bool flipY;
    float alpha;
};
typedef struct VideoTransform bef_video_transform_t;

/// Same struct as bef_InfoSticker_pin_param but with time type changed to bef_swing_time_t
typedef struct SwingInfoStickerPinParam
{
    bef_info_sticker_handle infoStickerName; // Information stickers to be tracked
    bef_swing_time_t startTime;              // Start time
    bef_swing_time_t endTime;                // End time
    bef_swing_time_t pinTime;                // The moment of the frame where the pin is
    bef_InfoSticker_texture_buff initBuff;   // Pin tracking initial texture buffer
} bef_swing_InfoSticker_pin_param;

/* ----------------------------------
 * Swing tracking modules definitions */

/**
 * @brief structure for unified access of different segment types' T(Transition)/R(Rotation)/S(Scaling) properties
 * 
 * Coordinates follow the standard EffectSDK canvas convention ([-1, 1] range, canvas center origin and +Y = up)
 */
struct SwingTRS
{
    float posX;     /// normalized x coordinate
    float posY;     /// normalized y coordinate
    float scaleX;   /// x scale
    float scaleY;   /// y scale
    float rotation; /// rotation (degrees; counter-clockwise positive)
};
typedef struct SwingTRS bef_swing_trs;

/**
 * @brief Tracker type enum
 */
enum SwingTrackerType
{
    SWING_TRACKING_OBJECT = 0
    // more types to support coming later
};
typedef enum SwingTrackerType bef_swing_tracker_type;

/**
 * @brief tracking mode flag
 * 
 * Can be OR'ed together to denote following multiple properties, e.g.
 * SWING_TRACKING_FOLLOW_POSITION | SWING_TRACKING_FOLLOW_SCALE -> follow both position and scale
 */
enum SwingTrackingMode
{
    SWING_TRACKING_FOLLOW_POSITION = 1 << 0, /// follow tracker position (note: relative transposition still affected by tracker scale)
    SWING_TRACKING_FOLLOW_SCALE = 1 << 1, /// follow tracker scale
    SWING_TRACKING_FOLLOW_ROTATION = 1 << 2, /// follow tracker rotation
    SWING_TRACKING_FOLLOW_POSITION_ABS = 1 << 3, /// follow tracker position with absolute transposition
};
typedef int bef_swing_tracking_mode;

/**
 * @brief Tracker merge mode enum
 */
enum SwingTrackerMergeMode
{
    SWING_TRACKING_MERGE_MODE_NORMAL = 0, /// normal mode, adds all entries in source to target

    /**
     * @brief overwrite mode
     * 
     * Removes all entries in target within the source's time range first
     * and then add all entries in source
     */
    SWING_TRACKING_MERGE_MODE_OVERWRITE
};
typedef enum SwingTrackerMergeMode bef_swing_tracker_merge_mode;

/**
 * @brief Reset  type enum
 */
enum SwingResetType
{
    SWING_RESET_PARAMS = 0
    // more types to support coming later
};
typedef enum SwingResetType bef_swing_reset_type;

/**
 * @brief Output structure for bef_swing_tracker_get_valid_regions utility function
 */
struct SwingTrackerValidRegion
{
    bef_swing_time_t start; /// start source time (US) of the valid region
    bef_swing_time_t end;   /// end source time (US) of the valid region
};
typedef struct SwingTrackerValidRegion bef_swing_tracker_valid_region;

// The following definitions are temporary and only needed for bef_swing_tracker_convert_to_old_pin_data,
// which will be deprecated once support for old pin API is removed.

struct SwingVideoKeyframe
{
    bef_swing_time_t timestamp; /// keyframe target timestamp (US)
    const char* jsonStr;        /// JSON string of keyframe
};
typedef struct SwingVideoKeyframe bef_swing_video_keyframe;

struct SwingTrackerAndVideoInfo
{
    void* trackingData;                    /// new tracker serialized data
    int trackingDataSize;                  /// size in bytes of serialized data
    bef_video_transform_t* videoTransform; /// video transform structure
    bef_swing_time_t startSourceTime;      /// video source start time
    bef_swing_time_t endSourceTime;        /// video source end time
    bef_swing_time_t startTargetTime;      /// video target start time
    bef_swing_time_t endTargetTime;        /// video target end time
    bef_swing_video_keyframe* keyframes;   /// optional: keyframes array
    int keyframesLength;                   /// length of keyframes array
};
typedef struct SwingTrackerAndVideoInfo bef_swing_tracker_and_video_info;

struct SwingTrackingSegmentInfo
{
    bef_swing_trs* baselineTRS; /// tracking segment baseline trs
    int canvasWidth;            /// canvas width in pixels
    int canvasHeight;           /// canvas height in pixels
    bef_swing_time_t startTime; /// start time (target)
    bef_swing_time_t endTime;   /// end time (target)
};
typedef struct SwingTrackingSegmentInfo bef_swing_tracking_segment_info;

/* --------------------------------------
 * Swing tracking modules definitions end */


/* --------------------------------------
 * Swing custom segment definitions */
enum SwingTextureType {
    Null,       //!< No rendering.
    Direct3D9,  //!< Direct3D 9.0
    Direct3D10, //!< Direct3D 10.0
    Direct3D11, //!< Direct3D 11.0
    Direct3D12, //!< Direct3D 12.0
    Gnm,        //!< GNM
    Metal,      //!< Metal
    OpenGLES2,  //!< OpenGL ES 2.0
    OpenGLES30, //!< OpenGL ES 3.0
    OpenGLES31, //!< OpenGL ES 3.1
    OpenGLES32, //!< OpenGL ES 3.2
    OpenGL,     //!< OpenGL 2.1+
    Vulkan,     //!< Vulkan
    OpenCL,     //!<OpenCL
    Count
};
typedef enum SwingTextureType bef_swing_texture_type;

struct SwingResolution {
    unsigned int width;
    unsigned int height;
};
typedef struct SwingResolution bef_swing_resolution;

struct SwingTextureInfo {
    bef_swing_texture_type textureType;
    device_texture_handle mTLTextureId;
    unsigned int textureId;
    bef_swing_resolution resolution;
};
typedef struct SwingTextureInfo bef_swing_custom_texture_info;

typedef bool (*bef_swing_custom_render_call_back)(void *userData,
                           bef_swing_time_t timestamp,
                           bef_swing_custom_texture_info* input,
                           bef_swing_custom_texture_info* output);

/* --------------------------------------
* Swing custom segment definitions end */

#endif /* bef_swing_define_h */
