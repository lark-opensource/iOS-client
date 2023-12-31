//
// Created by bytedance on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_C_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_C_DEFINE_H
#include "bef_framework_public_geometry_define.h"
#include <stdbool.h>
#include <stdint.h>

//#define _EFFECT_SDK_EXPORTS_

#ifdef __cplusplus

#ifdef _EFFECT_SDK_EXPORTS_
#ifdef WIN32
#define BEF_SDK_API extern "C" __declspec(dllexport)
#else
#define BEF_SDK_API extern "C" __attribute__((visibility("default")))
#endif
#else
#define BEF_SDK_API extern "C"
#endif

#define BEF_DEFAULT(value) = value

#else // c

#ifdef _EFFECT_SDK_EXPORTS_
#ifdef WIN32
#define BEF_SDK_API __declspec(dllexport)
#else
#define BEF_SDK_API __attribute__((visibility("default")))
#endif
#else
#define BEF_SDK_API
#endif

#define BEF_DEFAULT(value)

#endif // __cplusplus

#define BEFERROR_CONSTRCTOR(error, reasonP, dominP, errorCodeP) \
    if (error)                                                  \
    {                                                           \
        std::string str = reasonP;                              \
        strcpy(error->reason, str.c_str());                     \
        error->domin = dominP;                                  \
        error->errorCode = errorCodeP;                          \
    }
typedef enum ErrorDomin
{
    ErrorDominResourceFile
} ErrorDomin;
typedef enum ErrorCode
{
    ErrorCodeResourceVersionLength = -0x000000000001,
    ErrorCodeResourceVersionTooHigh = -0x000000000002,
} ErrorCode;
typedef struct BEFError
{
    char reason[256];
    ErrorDomin domin;
    ErrorCode errorCode;
} BEFError;
typedef short int16_t;
typedef int int32_t;

typedef unsigned long long UINT64;
// def byted effect handle
typedef void* bef_effect_handle_t;

// def byted effect result
typedef int bef_effect_result_t;

typedef UINT64 bef_feature_handle_t;

// def byted algorithm requirement
typedef unsigned long long bef_algorithm_requirement;

// define bef_intensity_type
typedef int bef_intensity_type;

typedef unsigned long long UINT64;
// def byted effect handle
typedef void* bef_effect_handle_t;

// def byted effect result
typedef int bef_effect_result_t;

typedef char* (*bef_resource_finder)(bef_effect_handle_t, const char*, const char*);
typedef void  (*bef_resource_finder_releaser)(void*);

typedef UINT64 bef_feature_handle_t;

// def byted effect result
typedef int bef_effect_feature_types;

// define bef_intensity_type
typedef int bef_intensity_type;

typedef const char* bef_intensity_name;

// define bef_mv_audio_type
typedef int bef_mv_audio_type;

typedef void* LPVoid;

typedef int effect_result;

typedef void* device_texture_handle;

typedef void* gpdevice_handle;

typedef struct bef_base_effect_info_st
{

} bef_base_effect_info;

typedef struct bef_audio_effect_st
{
    int m_audio_effect_id;
    // Shift formant or keep it when altering pitch.
    // Default: OptionFormantShifted
    bool m_formatShiftOn;

    // Enable time-domain smooting or not, after frequency pitch update
    // Default: OptionSmoothingOff
    bool m_smoothOn;

    // The way to adjust phase for consistent content from one analyzing widow to next.
    // Default: OptionPhaseLaminar
    // Joint or seperated processing for stereo input
    // Default: OptionChannelsApart
    int m_processChMode;

    // Transient detection method: Percussive/Compound/soft
    // Default: OptionDetectorCompound
    int m_transientDetectMode;

    // Phase reset on transient point in way of crsip/mixed/smooth;
    // Default: OptionTransientsCrisp
    int m_phaseResetMode;

    // The method to adjust phase: Cross-band(laminar) or Intra-band(Independent)
    // Default: OptionPhaseLaminar
    int m_phaseAdjustMethod;

    //    The FFT processing Window mode: short/standard/long
    // Default: OptionWindowStandard
    int m_windowMode;

    // The mode to conduct the pitch adjusting: speed/consistency/quality
    // Default: OptionPitchHighSpeed
    int m_pitchTunerMode;

    // Audio data block size for audio effect processing.
    // In general, could use 1024, 2048, 4096, ect.
    int m_blockSize;

    // Pitch tunning parameters
    // Rage: [-100.0 - 100.0]
    float m_centtone;

    // Rage: [-12, 12]
    float m_semitone;

    // Rage: [-3.0, 3.0]
    float m_octave;

    // Tempo tunning parameter, Future proof for case combined time- and frequency- effect.
    // Rage: [-3.0, 3.0]
    float m_speedRatio;

    // AudioEffect enable/disable status
    // Default: true
    bool m_enable;
} bef_audio_effect;

typedef struct bef_audio_sami_aed
{
    int channels;
    int sample_rate;
    int bit_sample;
    int audio_type; // 0 -- pcm
    float threshold;
} bef_sami_aed;

typedef struct bef_audio_speech_asr
{
    char asr_cluster[32];
    char asr_address[32];
    char asr_uri[32];
    int  asr_auto_stop;
} bef_audio_speech_asr;

typedef struct bef_audio_speech_capt
{
    char capt_cluster[32];
    char capt_address[32];
    char capt_uri[32];
    char capt_core_type[32];
    char capt_response_mode[32];
} bef_audio_speech_capt;

typedef struct bef_audio_oneset_st
{
    int channels;
    int sample_rate;
    int bit_sample;
    int audio_type; // 0 -- pcm
    float threshold;
} bef_audio_oneset;

typedef struct bef_audio_volume_st
{
    int channels;
    int sample_rate;
    int bit_sample;
    int audio_type; // 0 -- pcm
} bef_audio_volume;

typedef struct bef_audio_tone_st
{
    float f0_min;
    float f0_max;
} bef_audio_tone;

typedef struct bef_audio_spectrum_st
{
    int channels;
    int sample_rate;
    int bit_sample;
    int audio_type; // 0 -- pcm
} bef_audio_spectrum;

typedef struct bef_audio_beats_st
{
    int channels;
    int sample_rate;
    int bit_sample;
    int audio_type; // 0 -- pcm
} bef_audio_beats;

typedef struct bef_mv_audio_update_info_st
{
    int sampleRate;
    int channels;
    int sampleNum;
    bef_mv_audio_type audioType;
    float audioTimeLength;
} bef_mv_audio_update_info;

typedef struct bef_audio_sample_parameter_t
{
    int sampleRate;
    int channels;
} bef_audio_sample_parameter;

typedef enum
{
    bef_effect_audio_playback_device_type_unknown = 0, // default
    bef_effect_audio_playback_device_type_earphone,
    bef_effect_audio_playback_device_type_speaker,
} bef_effect_audio_playback_device_type;

typedef void* bef_effect_audio_handle;

typedef enum
{
    bef_effect_audio_out_port_play = 0,    // output for 'play'
    bef_effect_audio_out_port_write,       // output for 'write '

    bef_effect_audio_in_port_mic = 100,    // input port for 'mic'
    bef_effect_audio_in_port_music         // input port for 'music'
} bef_effect_audio_port_type;

typedef enum
{
    // Everything seems fine.
    bef_effect_audio_status_ok = 0,
    // *WARNING* Fails to process audio output in time.
    bef_effect_audio_status_under_run,
    // *ERROR* Audio handle is not set correctly.
    bef_effect_audio_status_unbind,
    // *WARNING* Fails to process audio input in time.
    bef_effect_audio_status_over_run,

    // *Unknown error* Most likely due to unmatched AudioSDK version.
    bef_effect_audio_status_unknown = 100
} bef_effect_audio_status_type;

typedef enum
{
    bef_render_api_gles20 = 0,
    bef_render_api_gles30,
} bef_render_api_type;

typedef struct bef_effect_remark_st
{
    unsigned short width;
    unsigned short height;
    bool needFaceDetect;
    bool needMatting;
    bool needHairColor;
    bool needSlam;
    bool needARPlane;
    bool needSkeletonDetect;
    bool needSkeletonDetect2;
    bool needCatFaceDetect;
    bool needFace240Detect;
    bool needHandDetect;
    bool needHandDetectRoi;
    bool need2HandDetect;
    bool needHandDetectKeyPoint;
    bool need2HandDetectKeyPoint;
    bool needHandDetectKeyPoint3D;
    bool needHandDetectLeftRight;
    bool needHandDetectRing;
    bool needExpressionDetect;
    bool needGenderDetect;
    bool needFace3DDetect;
    bool needSkySegDetect;
    bool needUSLabSkySegDetect;
    bool needskelectonCHRY;
    bool needEnigma;
    bool needLicensePlateDetect;
    bool needActionDetectStatic;
    bool needActionDetectSequence;
    bool needPetFaceDetect;
    bool needFace3DMesh;
    bool needFace3DMesh845;
    bool needFace3DMeshPerspective;
    bool needObjectDetect;
    bool needJointV2;
    bool needHeadSeg;
    bool needAvatarDrive;
    bool needARScan;
    bool needUpperBody3D;
    bool needSceneRecognition;
    bool needCarColor;
    bool needGyroscope;
    bool needFacePartBeauty;
    bool needFaceAttributes;
    bool needHdrnet;
    bool needSnapshot;
    bool needClothesSeg;
    bool needFaceGan;
    bool needFaceBeautify;
    bool needCarDetect;
#if BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT || BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT_SAFE
    bool needMemojiMatch;
#endif
    bool needTrackingAr;
    bool needGazeEstimation;
    bool needBling;
    bool needKira;
    bool needMug;

    bool needSkeletonPose3D;
    bool needBigGan;
    bool needTeeth;
    bool needFaceVerify;
    bool needFaceClusting;
    bool needOldgan;
    bool needGenderGan;
    bool needSkinUnified;
    bool needNail;
    bool needNailKeyPoint;
    bool needFemaleGan;
    bool needEarSeg;
    bool needSceneNormal;
    bool needModelTest;
    bool needStructxtHist;
    bool needStructxtSharp;
    bool needGroundSeg;
    bool needFaceSmoothCPU;
    bool needLaughGan;
    bool needGeneralObjectDetection;
    bool needManga;
    bool needSkinSeg;

    bool needWatercolor;
    bool needAvatar3D;
    bool needBuildingSeg;
    bool needFoodComics;
    bool needOilPaint;
    bool needFoot;
    bool needBlingHighlight;
    bool needBlockGan;
    bool needObjectTracking;
    bool needSaliencySeg;
    bool needHighFrequenceSensorData;
    bool needBeautyGan;
    bool needSwapperMe;
    bool needClothMesh;
    bool needHandtv;
    bool need2Handtv;
    bool needHandtvKeypoint;
    bool need2HandtvKeypoint;
    bool needHandtvSeg;
    bool needHandtvSkeleton;
    bool needHandtvDynamic;
    bool needHandtvPersonRecognition;
    bool needInteractiveMatting;
    bool needBuildInSensorData;
} bef_effect_remark;

/*
 *@brief monitor state
 **/
typedef enum
{
    BEF_LOG_LEVEL_NONE = 0,
    BEF_LOG_LEVEL_DEFAULT = 1,
    BEF_LOG_LEVEL_VERBOSE = 2,
    BEF_LOG_LEVEL_DEBUG = 3,
    BEF_LOG_LEVEL_INFO = 4,
    BEF_LOG_LEVEL_WARN = 5,
    BEF_LOG_LEVEL_ERROR = 6,
    BEF_LOG_LEVEL_FATAL = 7,
    BEF_LOG_LEVEL_SILENT = 8,
} bef_log_level;

typedef enum
{
    BEF_AB_DATA_TYPE_BOOL = 0,
    BEF_AB_DATA_TYPE_INT = 1,
    BEF_AB_DATA_TYPE_FLOAT = 2,
    BEF_AB_DATA_TYPE_STRING = 3,
} bef_ab_data_type;

/*
 * @brief safe area.
 */
typedef struct bef_safe_area_st
{   // style: 0, Device safe area.
    // style: 1, UI safe area.
    int style;
    bef_rectf frame;
} bef_safe_area;

/*
 * @brief effect call method single param
 */
typedef struct bef_effect_value_param_st
{
    int valueType;
    void* valueBuffer;
    int bufferLength;
} bef_effect_value_param;

/*
 * @brief effect call method params
 */
typedef struct bef_effect_value_params_st
{
    int paramCount;
    bef_effect_value_param* paramsVal;
} bef_effect_value_params;

/*
 * @brief effect callback function
 */
typedef void (*bef_effect_callback)();

/*
 * @brief effect callback data
 */
typedef struct bef_effect_callback_data_st
{
    bef_effect_callback callback;
} bef_effect_callback_data;

#endif //EFFECT_SDK_BEF_EFFECT_C_DEFINE_H
