#ifndef _SMASH_MEMOJIMATCHAPI_H_
#define _SMASH_MEMOJIMATCHAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif

#define MODULE_HANDLE MemojiMatchHandle

#define BEARD_THRD 0.7
#define GLASSESS_THRD 0.7
#define MEMORY_SIZE_RESOURCE 40
#define TYPE_NUM 8

#define HAIR_DIM 19
#define GLASSES_DIM 128
#define BEARD_DIM 128
#define BROW_DIM 384
#define EYE_DIM 128
#define MOUTH_DIM 128
#define COLOR_MOUTH_DIM 3
#define COLOR_SKIN_DIM 3
#define COLOR_HAIR_DIM 3

#define HAIR_DEFAULT_R 50
#define HAIR_DEFAULT_G 50
#define HAIR_DEFAULT_B 55

#define MOUTH_BOY_DEFAULT_R 92
#define MOUTH_BOY_DEFAULT_G 126
#define MOUTH_BOY_DEFAULT_B 235

#define MOUTH_GIRL_DEFAULT_R 70
#define MOUTH_GIRL_DEFAULT_G 96
#define MOUTH_GIRL_DEFAULT_B 210

typedef void* MODULE_HANDLE;

const static int MEMOJI_MATCH_MAX_FACE = 1;  //最大支持的人脸数
const static int MEMOJI_MATCH_MAX_FACE_MULTI = 10;  //最大支持的人脸数

typedef enum {
    kMemojiMatchMMSUWN = 0,
    kMemojiMatchMMSUYN = 1,
    kMemojiMatchMMSUIN = 2,
    kMemojiMatchMMSUBN = 3,
    kMemojiMatchMMNUM_Sun = 4,
} MemojiMatchSunType;

// pack landmark
typedef struct MemojiMatchLandmarkInfo {
    int id;                     // 人脸的id
    AIPoint * landmark106;     // 106点数组               required
} MemojiMatchLandmarkInfo;

typedef struct MemojiMatchFeatures{
    char* resource_id;
    float* feature;
}MemojiMatchFeature, *PtrMemojiMatchFeature;

typedef struct MemojiMatchTypes{
    char *type;
    int resource_num;
    int feature_dim;
    PtrMemojiMatchFeature resource_features;
    int gender; //0male 1female 2allgender
}MemojiMatchTypes, *PtrMemojiMatchTypes;

typedef struct MemojiMatchResourceFeatures {
    PtrMemojiMatchTypes type_hair;
    PtrMemojiMatchTypes type_glasses;
    PtrMemojiMatchTypes type_beard;
    PtrMemojiMatchTypes type_brow;
    PtrMemojiMatchTypes type_eye;
    PtrMemojiMatchTypes type_mouth;
    PtrMemojiMatchTypes type_mcolor;
    PtrMemojiMatchTypes type_scolor;
}MemojiMatchResourceFeatures;

// pack input
typedef struct MemojiMatchArgs {
    ModuleBaseArgs base;
    MemojiMatchLandmarkInfo face_landmark_info[MEMOJI_MATCH_MAX_FACE];
    int face_landmark_info_count;                   //输入的人脸的个数
    int view_width;
    int view_height;
    int type_num;
    int gender;

    unsigned char* hair_mask;
    int mask_height;
    int mask_width;

}MemojiMatchArgs;
typedef struct MemojiMatchMultiArgs {
    ModuleBaseArgs base;
    MemojiMatchLandmarkInfo face_landmark_info[MEMOJI_MATCH_MAX_FACE_MULTI];
    int face_landmark_info_count;                   //输入的人脸的个数
    int view_width;
    int view_height;
    int type_num;
    int gender[MEMOJI_MATCH_MAX_FACE_MULTI];

    unsigned char* hair_mask;
    int mask_height;
    int mask_width;

}MemojiMatchMultiArgs;

// FigureMatchRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
// TODO: 根据实际情况修改
typedef struct MemojiMatchRecommendConfig {
    int InputHairWidth = 128;
    int InputHairHeight = 128;
    int InputGlassesWidth = 224;
    int InputGlassesHeight = 224;
} MemojiMatchRecommendConfig;

// 模型参数类型
// TODO: 根据实际情况修改
typedef enum MemojiMatchParamType {
    kMemojiMatchEdgeMode,
} MemojiMatchParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum MemojiMatchModelType {
    hair_model = 0,
    glasses_model = 1,
    facial_model = 2,
    sun_model = 3,
}MemojiMatchModelType;

typedef struct MemojiMatchResource{
    int ret_id;
    char gender[MEMORY_SIZE_RESOURCE];
    char faceshape[MEMORY_SIZE_RESOURCE];
    char nose[MEMORY_SIZE_RESOURCE];

    char rice_cl[MEMORY_SIZE_RESOURCE];
    //char mouth_color[MEMORY_SIZE_RESOURCE];

    char hair[MEMORY_SIZE_RESOURCE];
    char brow[MEMORY_SIZE_RESOURCE];
    char eye[MEMORY_SIZE_RESOURCE];
    char mouth[MEMORY_SIZE_RESOURCE];
    char glasses[MEMORY_SIZE_RESOURCE];
    char beard[MEMORY_SIZE_RESOURCE];

    int mouth_color[3];
    int hair_color[3];
} MemojiMatchResource;

typedef struct MemojiMatchEmbedding {
    int lenth_hair;
    int lenth_glasses;
    int lenth_beard;

    int lenth_brow;
    int lenth_eye;
    int lenth_mouth;
    int lenth_cl_rice;
    int lenth_color_mouth;
    int lenth_color_hair;

    float *hair_color; //rgb
    float *rice_cl; //rgb
    float *mouth_color; //rgb

    bool has_glasses;
    bool has_beard;
    bool has_bang;

    float *glasses;
    float *beard;
    float *hair;
    float *mouth;
    float *brow;
    float *eye;

    int nose;
    int faceshape;

    float confidence_hair;
    float confidence_eye;
    float confidence_brow;
    float confidence_mouth;
    float confidence_nose;
    float confidence_faceshape;
} MemojiMatchEmbedding;

typedef struct MemojiMatchRet {
    // TODO: 以下换成你自己的算法模块返回内容定义
    struct MemojiMatchEmbedding embeddings;
    struct MemojiMatchResource resource;
} MemojiMatchRet;
typedef struct MemojiMatchMultiRet {
    // TODO: 以下换成你自己的算法模块返回内容定义
    struct MemojiMatchEmbedding embeddings[MEMOJI_MATCH_MAX_FACE_MULTI];
    struct MemojiMatchResource resource[MEMOJI_MATCH_MAX_FACE_MULTI];
} MemojiMatchMultiRet;


// 创建句柄
AILAB_EXPORT int MemojiMatch_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int MemojiMatch_LoadModel(void* handle,
                                       MemojiMatchModelType type,
                                       const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int MemojiMatch_LoadModelFromBuff(void* handle,
                                               MemojiMatchModelType type,
                                               const char* mem_model,
                                               int model_size);

AILAB_EXPORT int MemojiMatch_LoadResourceFeature(void* handle,
                                                 MemojiMatchResourceFeatures &resources);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MemojiMatch_SetParamF(void* handle,
                                       MemojiMatchParamType type,
                                       float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MemojiMatch_SetParamS(void* handle,
                                       MemojiMatchParamType type,
                                       char* value);

// 算法主调用接口
AILAB_EXPORT int MemojiMatch_DO(void* handle, MemojiMatchArgs* args, MemojiMatchRet* ret);
AILAB_EXPORT int MemojiMatch_MULTIDO(void* handle, MemojiMatchMultiArgs* args, MemojiMatchMultiRet* ret);

// 销毁句柄
AILAB_EXPORT int MemojiMatch_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int MemojiMatch_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_FIGUREMATCHAPI_H_

