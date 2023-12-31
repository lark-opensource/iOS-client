//
//  bef_effect_algorithm_.h
//  Pods
//
//  Created by bytedance on 2019/10/11.
//

#ifndef bef_effect_algorithm__h
#define bef_effect_algorithm__h
#include "bef_effect_public_define.h"

#ifdef BEF_MODULE_HANDLE
#undef BEF_MODULE_HANDLE
#endif
#define BEF_MODULE_HANDLE bef_AfterEffectHandle

typedef void* BEF_MODULE_HANDLE;

/// Model parameter type
typedef enum {
    // Whether to use summary mode, 0 means not to use, 1 means to use, the default is 0
    bef_kAfterEffectSummaryMode,
    // Maximum number of sampling frames, default is 60
    bef_kAfterEffectSampleMaxNum,
    // Sampling frequency，after setting kAfterEffectSampleFPS, kAfterEffectSampleMaxNum will be invalid. Parameter type is floating point
    bef_kAfterEffectSampleFPS,
    // Maximum number of covers, default is 6
    bef_kAfterEffectSampleMaxCover,
    // Use face attributes, 0 means no use, 1 means use, the default is 0
    bef_kAfterEffectUseFaceAttr,
}bef_AfterEffectParamType;

/// Model enumeration, some modules may have multiple models
typedef enum  {
    bef_kAfterEffectModel1,
}bef_AfterEffectModelType;

typedef enum  {
    bef_kAfterEffectFuncGetFrameTimes,
    bef_kAfterEffectFuncCalcScore,
    bef_kAfterEffectFuncGetCoverInfos,
    bef_kAfterEffectFuncShotSegment,
    bef_kAfterEffectFuncSummary,
}bef_AfterEffectFuncType;

/**
 * @breif Single face attribute structure
 */
typedef enum {
    bef_ANGRY = 0,                   // angry
    bef_DISGUST = 1,                 // disgust
    bef_FEAR = 2,                    // afraid
    bef_HAPPY = 3,                   // happy
    bef_SAD = 4,                     // sad
    bef_SURPRISE = 5,                // surprise
    bef_NEUTRAL = 6,                 // calm
    bef_NUM_EXPRESSION = 7           // number of emoticons 
}bef_ExpressionType;

typedef struct bef_AttrInfo {
    float age;                          // Predicted age value, value range [0, 100]
    float boy_prob;                     // Probability value predicted as male, value range [0.0, 1.0]
    float attractive;                   // Predicted face value score, range [0, 100]
    float happy_score;                  // Predicted smile level, range [0, 100]
    bef_ExpressionType exp_type;            // Predicted emoji category
    float exp_probs[bef_NUM_EXPRESSION];    // The predicted probability of each expression, without smoothing
    float real_face_prob;               // Predict the probability of belonging to a real face, used to distinguish non-real faces such as sculptures and comics
    float quality;                      // Predict the quality score of the face, range [0, 100]
    float arousal;                      // Emotional intensity
    float valence;                      // The degree of positive and negative emotions
    float sad_score;                    // Sadness
    float angry_score;                  // Angry degree
    float surprise_score;               // Degree of surprise
    float mask_prob;                    // Predict the probability of wearing a mask
    float wear_hat_prob;                // Probability of wearing a hat
    float mustache_prob;                // Bearded probability
    float lipstick_prob;                // Probability of applying lipstick
    float wear_glass_prob;              // Probability with ordinary glasses
    float wear_sunglass_prob;           // Probability with sunglasses
    float blur_score;                   // Blur degree
    float illumination;                 // illumination
} bef_AttrInfo;

typedef struct BEF_AfterEffectArgs {
    bef_AfterEffectFuncType func_type;
    bef_ModuleBaseArgs base;
    int video_duration_ms;
    int time_stamp_ms;
    const bef_face_106* face_info_ptr;
    int summary_duration_ms;
    const bef_AttrInfo* attr_info_ptr;
}BEF_AfterEffectArgs;

typedef struct BEF_AfterEffectScoreInfo {
    int time;
    // Final score
    float score;
    // Face score
    float face_score;
    // Comprehensive quality score
    float quality_score;
    // Sharpness score
    float sharpness_score;
} BEF_AfterEffectScoreInfo;

typedef struct BEF_AfterEffectShotSegment {
    // The moment when the slice score is the highest
    int time_highlight;
    // Slice start time
    int time_start;
    // Slice end time
    int time_end;
    // Slice score
    float score;
} BEF_AfterEffectShotSegment;

typedef struct BEF_AfterEffectRet {
    // Corresponding to func_type : kAfterEffectFuncGetFrameTimes
    // The amount of frame time to extract
    int frame_time_num;
    // Extract the first address of the frame time, the memory is managed internally by the SDK and contains frame_time_num elements
    int* frame_time_ptr;
    
    // Corresponding to func_type :  kAfterEffectFuncCalcScore
    // Final score = (face_score * 0.3 + quality_score + sharpness_score * 0.1) / 1.4
    float score;
    // Face score
    float face_score;
    // Comprehensive quality score
    float quality_score;
    // Sharpness score
    float sharpness_score;
    
    // Corresponding to func_type :  kAfterEffectFuncGetCoverInfos
    // The amount of frame time to extract
    int cover_num;
    // Extract the first address of the frame time, the memory is managed internally by the SDK and contains frame_time_num elements
    int* cover_time_ptr;
    // The first address of the cover score, the memory is managed internally by the SDK, and contains cover_num elements
    float* cover_score_ptr;
    
    // Corresponding to func_type :  kAfterEffectFuncShotSegment
    int score_info_num;
    // The first address of the score information, the memory is managed internally by the SDK, and contains score_info_num elements
    BEF_AfterEffectScoreInfo* score_info_ptr;
    // Number of slices
    int shot_segment_num;
    // The first address of the slice, the memory is managed internally by the SDK and contains shot_segment_num elements
    BEF_AfterEffectShotSegment* shot_segment_ptr;
    
    // Corresponding to func_type :  kAfterEffectFuncShotSegment
    // Number of slices
    int summary_shot_num;
    // The first address of the slice, the memory is managed internally by the SDK, and contains summary_shot_num elements
    BEF_AfterEffectShotSegment* summary_shot_ptr;
}BEF_AfterEffectRet;

/// Create handle
BEF_SDK_API int bef_AfterEffect_CreateHandle(bef_AfterEffectHandle* handle);

/// Load model (from file system)
BEF_SDK_API int bef_AfterEffect_LoadModel_path(bef_AfterEffectHandle handle,
                                       bef_AfterEffectModelType type,
                                       const char* model_path);
/// Support ios and android synchronous call
BEF_SDK_API int bef_AfterEffect_LoadModel(bef_AfterEffectHandle handle,
                                               bef_AfterEffectModelType type,
                                               bef_resource_finder finder);

/// Load model (load from memory, Android recommends using this interface)
BEF_SDK_API int bef_AfterEffect_LoadModelFromBuff_path(bef_AfterEffectHandle handle,
                                               bef_AfterEffectModelType type,
                                               const char* mem_model,
                                               int model_size);

/// Configure int/float algorithm parameters. This interface is a lightweight interface, which can be replaced by calling #{MODULE}_D interface
BEF_SDK_API int bef_AfterEffect_SetParamF(bef_AfterEffectHandle handle,
                                       bef_AfterEffectParamType type,
                                       float value);

/// Configure char* type algorithm parameters. This interface is a lightweight interface, which can be replaced by calling #{MODULE}_DO interface
BEF_SDK_API int bef_AfterEffect_SetParamS(bef_AfterEffectHandle handle,
                                       bef_AfterEffectParamType type,
                                       char* value);

/// Algorithm main call interface
BEF_SDK_API int bef_AfterEffect_DO(bef_AfterEffectHandle handle,
                                BEF_AfterEffectArgs* args,
                                BEF_AfterEffectRet* ret);

/// Destroy handle
BEF_SDK_API int bef_AfterEffect_ReleaseHandle(bef_AfterEffectHandle handle);

/// Print the parameters of the module for debugging
BEF_SDK_API int bef_AfterEffect_DbgPretty(bef_AfterEffectHandle handle);


#endif /* bef_effect_algorithm__h */
