#ifndef _SMASH_LAUGHGANAPI_H_
#define _SMASH_LAUGHGANAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// clang-format off
typedef void* LaughGanHandle;
#define TT_LAUGH_GAN_MAX_FACE_LIMIT 10

//最小支持分辨率192x192，推荐1280x720

typedef enum LaughGanParamType {
    kLaughGanParam1 = 1,
} LaughGanParamType;

typedef enum LaughGanModelType {
    kLaughGanModel1 = 1,
    kLaughGanModel2 = 2,
    kLaughGanModelMax = 10000,
} LaughGanModelType;

typedef struct LaughGanArgs {
    ModuleBaseArgs base;
    int face_count;
    int id[TT_LAUGH_GAN_MAX_FACE_LIMIT];
    float *landmark106[TT_LAUGH_GAN_MAX_FACE_LIMIT];
} LaughGanArgs;



typedef struct LaughGanRet {
    unsigned char* alpha;
    int width;
    int height;
    float matrix[6];
    int face_count;
} LaughGanRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return LaughGan_CreateHandle
 */
AILAB_EXPORT
int LaughGan_CreateHandle(LaughGanHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return LaughGan_LoadModel
 */
AILAB_EXPORT
int LaughGan_LoadModel(LaughGanHandle handle,
                       LaughGanModelType type,
                       const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return LaughGan_LoadModelFromBuff
 */
AILAB_EXPORT
int LaughGan_LoadModelFromBuff(LaughGanHandle handle,
                               LaughGanModelType type,
                               const char* mem_model,
                               int model_size);



AILAB_EXPORT
int LaughGan_SetParamF(LaughGanHandle handle,
                       LaughGanParamType type,
                       float value);




AILAB_EXPORT
int LaughGan_DO(LaughGanHandle handle,
                LaughGanArgs* args,
                LaughGanRet* ret);


AILAB_EXPORT
int LaughGan_ReleaseHandle(LaughGanHandle handle);


AILAB_EXPORT
int LaughGan_DbgPretty(LaughGanHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

AILAB_EXPORT int LaughGan_FreeResultMemory(LaughGanRet * result);

AILAB_EXPORT LaughGanRet * LaughGan_MallocResultMemory(LaughGanHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_LAUGHGANAPI_H_
