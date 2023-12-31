#ifndef _SMASH_MEMOJIMATCHSAFEAPI_H_
#define _SMASH_MEMOJIMATCHSAFEAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define MEMOJI_MATCHSAFE_MAX_FACE  1  //最大支持的人脸数
typedef void* MemojiMatchsafeHandle;

typedef enum {
    kMemojiMatchsafeMMSUWN = 0,
    kMemojiMatchsafeMMSUYN = 1,
    kMemojiMatchsafeMMSUIN = 2,
    kMemojiMatchsafeMMSUBN = 3,
    kMemojiMatchsafeMMNUM_Sun = 4,
} MemojiMatchsafeSunType;

typedef enum {
    kMemojiMatchsafeMMBOY = 0,   ///< 男
    kMemojiMatchsafeMMGIRL = 1,  ///< 女
} MemojiMatchsafeGenderType;

// pack landmark
typedef struct MemojiMatchsafeLandmarkInfo {
    int id;                // 人脸的id
    AIPoint* landmark106;  // 106点数组               required
} MemojiMatchsafeLandmarkInfo;

// pack input
typedef struct MemojiMatchsafeArgs {
    ModuleBaseArgs base;
    MemojiMatchsafeLandmarkInfo face_landmark_info[MEMOJI_MATCHSAFE_MAX_FACE];
    int face_landmark_info_count;  //输入的人脸的个数
    int view_width;
    int view_height;
    int type_num;
    MemojiMatchsafeGenderType gender;
    MemojiMatchsafeSunType sun;
    
    unsigned char* hair_mask;
    int mask_height;
    int mask_width;
    
} MemojiMatchsafeArgs;


// 模型参数类型
// TODO: 根据实际情况修改
typedef enum {
    kMemojiMatchsafeEdgeMode,
    kMemojiMatchsafeUseEmbedding,
    kMemojiMatchsafeBeardThres,
    kMemojiMatchsafeGlassThres,
}MemojiMatchsafeParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum {
    kMemojiMatchsafeHair_model = 0,
    kMemojiMatchsafeGlasses_model = 1,
    kMemojiMatchsafeFacial_model = 2,
    kMemojiMatchsafeFeature_embedding = 3,
    kMemojiMatchsafeSun_model = 4,
}MemojiMatchsafeModelType;

typedef struct MemojiMatchsafeResource {
    char* gender;
    char* faceshape;
    char* nose;
    
    char* rice_cl;
    // char mouth_color[MEMORY_SIZE_RESOURCE];
    
    char* hair;
    char* brow;
    char* eye;
    char* mouth;
    char* glasses;
    char* beard;
    
    int* mouth_color;
    int* hair_color;
    
    float confidence_gender;
    
    float confidence_hair;
    float confidence_eye;
    float confidence_brow;
    float confidence_mouth;
    float confidence_nose;
    float confidence_faceshape;
    
    float confidence_glasses;
    float confidence_beard;
} MemojiMatchsafeResource;

typedef struct MemojiMatchsafeEmbedtype{
    float* hair;
    float* brow;
    float* mouth;
    float* eye;
    float* beard;
    float* glass;
} MemojiMatchsafeEmbedtype;

typedef struct MemojiMatchsafeEmbedding {
    int lenth_hair;
    int lenth_brow;
    int lenth_eye;
    int lenth_mouth;
    
    int lenth_rice_cl;
    
    float* rice_cl;  // rgb
    float* hair_color;
    float* mouth_color;
    
    float* hair;
    float* mouth;
    float* brow;
    float* eye;
} MemojiMatchsafeEmbedding;


typedef struct MemojiMatchsafeFacialFactors {
    float facelong;
    float facewidth;
    float facejaw;
    float eyedist;
    float eyebrowdist;
    float eyesize;
    float nosesize;
} MemojiMatchsafeFacialFactors;

typedef struct MemojiMatchsafeRet {
    // TODO: 以下换成你自己的算法模块返回内容定义
    MemojiMatchsafeEmbedding embeddings;
    MemojiMatchsafeResource resource;
    MemojiMatchsafeFacialFactors facial_factors;
    MemojiMatchsafeEmbedtype embedtypes;
} MemojiMatchsafeRet;

//内存申请
AILAB_EXPORT MemojiMatchsafeRet* MemojiMatchsafe_MallocResultMemory(void* handle);

//释放内存
AILAB_EXPORT int MemojiMatchsafe_FreeResultMemory(MemojiMatchsafeRet* ret);

// 创建句柄
AILAB_EXPORT int MemojiMatchsafe_CreateHandle(void** out);


// 加载模型（从文件系统中加载）
AILAB_EXPORT int MemojiMatchsafe_LoadModel(void* handle,
                                           MemojiMatchsafeModelType type,
                                           const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int MemojiMatchsafe_LoadModelFromBuff(void* handle,
                                                   MemojiMatchsafeModelType type,
                                                   const char *mem_model,
                                                   int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MemojiMatchsafe_SetParamF(void* handle,
                                           MemojiMatchsafeParamType type,
                                           float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MemojiMatchsafe_SetParamS(void* handle,
                                           MemojiMatchsafeParamType type,
                                           char* value);

// 算法主调用接口
AILAB_EXPORT int MemojiMatchsafe_DO(void* handle,
                                    MemojiMatchsafeArgs* args,
                                    MemojiMatchsafeRet* ret);

// 销毁句柄
AILAB_EXPORT int MemojiMatchsafe_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int MemojiMatchsafe_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_MEMOJIMATCHSAFEAPI_H_
