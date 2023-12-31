//
//  bef_effect_public_business_mv_define.h
//  Pods
//
//  Created by Helen on 2019/3/20.
//

#ifndef bef_effect_public_business_mv_define_h
#define bef_effect_public_business_mv_define_h
#include <stdbool.h>

/**
 MV data
 */
#define BEF_MV_AUDIO_PCM_RESULT_NUM 6000
typedef struct bef_mv_resource_audio_effect_base_info_st {
    int audioType;
    char* content;  // Resource address corresponding to audio effect
    float rangeStart;
    float rangeEnd;

} bef_mv_resource_audio_effect_base_info;


typedef enum bef_mv_resource_source_type {
    bef_mv_resource_source_type_user = 0,
    bef_mv_resource_source_type_model = 1
}bef_mv_resource_source_type;

typedef struct bef_mv_resource_base_info_st {
    char* content;// The content of the resource corresponds to the content of the above mv protocol
    char* type;//The type of the resource corresponds to the type of the above mv protocol
    bef_mv_resource_source_type from;//user or model
} bef_mv_resource_base_info;

typedef enum bef_mv_template_resource_fill_mode {
    bef_mv_template_resource_fill_mode_fit = 0,
    bef_mv_template_resource_fill_mode_fill = 1,
    bef_mv_template_resource_fill_mode_origin = 2
}bef_mv_template_resource_fill_mode;

/**
 * empty_end:   fill end with rgba(0,0,0,0).
 * empty_start: fill start with rgba(0,0,0,0).
 * fill_end:    fill end with video last frame.
 * fill_start:  fill start with video first frame.
 * repeat:      repeat resource.
 * stretch:     resource time length stretch to template resource length.
 * frozen_start: frozen at video first frame.
 */
typedef enum bef_mv_template_resource_time_mode {
    bef_mv_template_resource_time_mode_empty_end = 0,
    bef_mv_template_resource_time_mode_empty_start,
    bef_mv_template_resource_time_mode_fill_end,
    bef_mv_template_resource_time_mode_fill_start,
    bef_mv_template_resource_time_mode_repeat,
    bef_mv_template_resource_time_mode_stretch,
    bef_mv_template_resource_time_mode_frozen_start
}bef_mv_template_resource_time_mode;

typedef struct bef_mv_template_resource_descriptor_st {
    double trim_in;//Resource start time
    double trim_out;//Resource end time
    double seq_in;//The start time of the resource in the video
    double seq_out;//The end time of the resource in the video
    bef_mv_resource_base_info base_info;
    int rid;
    int width;
    int height;
    bef_mv_template_resource_fill_mode fillMode;
    bool isLoop;
    bef_mv_template_resource_time_mode timeMode;
    bool videoMute; // video mute or not, default false.
    char* logicName;
    double fade_in;
    double fade_out;
    // float volume;
    // bool loudness_balance;
} bef_mv_template_resource_descriptor;

typedef struct bef_mv_resolution_st {
    int w;
    int h;
} bef_mv_resolution;

typedef struct bef_mv_still_time_info_st {
    int count;
    const double* start_time;
    const double* end_time;
} bef_mv_still_time_info;

typedef struct bef_mv_info_st {
    bef_mv_template_resource_descriptor* resources;
    int resources_count;
    bef_mv_resolution resolution;
    int fps;
    bef_mv_resource_audio_effect_base_info m_audioMVInfo;
    bef_mv_still_time_info still_time;
} bef_mv_info;

typedef struct bef_mv_input_resource_st {
    int rid;
    unsigned int textureID;
    unsigned int width;
    unsigned int height;
} bef_mv_input_resource;

typedef void* device_texture_handle;
typedef struct bef_mv_input_resource_device_texture_st {
    int rid;
    device_texture_handle deviceTexture;
    unsigned int width;
    unsigned int height;
} bef_mv_input_resource_device_texture;

typedef enum bef_mv_audio_source_type_st {
    pcm = 0,
    mp3 = 1,
    aac = 2
}bef_mv_audio_source_type;

typedef struct bef_mv_audio_onset_st {
    float stmp;
    float value;
    float persistTime;
    
}bef_mv_audio_onset;

typedef struct bef_mv_audio_volume_st {
    float stmp;
    float value;
    float persistTime;
}bef_mv_audio_volume;

typedef struct bef_mv_audio_base_info_st {
    int sampleRate;
    int channels;
    int audioBits;
    bef_mv_audio_source_type audioDataType;
    int volumeInfoNum;
    int onesetInfoNum;
    bef_mv_audio_volume *volumeInfo;
    bef_mv_audio_onset  *onesetInfo;
    
} bef_mv_audio_base_info;

typedef struct bef_mv_audio_base_properties_info_st {
    float stmp_volume;
    float value_volume;
    float persistTime_volume;

    float stmp_onset;
    float value_onset;
    float persistTime_onset;

    float stmp_tone;
    float value_tone;
    float persistTime_tone;
    
}bef_mv_audio_base_properties_info;

// zhw add in SDK490 for VE cache
typedef struct bef_mv_info_cache_c_st {
    char *path; // template resource path
    bool timeoutUs;
    int audioType; // audio type, 0 means no audio, 1 means rhythm and 2 means volume
    int info_count;
    int info_count_tone;
    float audioTimeLength;
    bef_mv_audio_base_properties_info *audio_base_properties_info;
    bef_mv_resource_base_info *user_resources;
    int user_resources_count;
    int width;
    int height;
    float* resource_durations;
    int resource_durations_count;
    float totalDuraion;
} bef_mv_info_cache_c;

typedef enum bef_mv_algorithm_result_out_type
{
    OUT_IMAGE,                  // The algorithm results are only image
    OUT_VIDEO,                  // The algorithm results are only video
    OUT_IMAGE_AND_JSON,         // Algorithm results have image and json data
    OUT_VIDEO_AND_JSON,         // Algorithm results have video and json data
    OUT_JSON                    // The algorithm result is only json data
}bef_mv_algorithm_result_out_type;

typedef enum bef_mv_algorithm_result_in_type
{
    IN_IMAGE,
    IN_VIDEO,
    IN_JSON
}bef_mv_algorithm_result_in_type;

typedef struct bef_mv_algorithm_item
{
    char *algorithmName;
    char *algorithmParamJSON;
    bool isNeedServerExcute; // Whether the algorithm needs to be executed by the server
    bef_mv_algorithm_result_out_type type;
}bef_mv_algorithm_item;

typedef struct bef_mv_algorithm_info
{
    char                    *photoPath;
    bef_mv_algorithm_item   *items; // Required algorithm
    unsigned int            algorithmsSize; // The length of items array
}bef_mv_algorithm_info;

typedef struct bef_mv_algorithm_config
{
    bef_mv_algorithm_info   *infos; // Algorithm information array, in general, the length is equal to the number of pictures selected by the user
    unsigned int            size; // The length of infos array
}bef_mv_algorithm_config;


typedef struct bef_mv_text_replace_data_st {
    const char* layer_name_prefix;
    int layer_count;
    const char** layer_default_content;
    int* font_size;
    int* line_height;
    int* padding;
    float* start_time;
    float* end_time;
} bef_mv_text_replace_data;

typedef struct bef_mv_text_replace_info_st {
    bef_mv_text_replace_data* datas;
    int data_count;
} bef_mv_text_replace_info;


#endif /* bef_effect_public_business_xmv_define_h */
