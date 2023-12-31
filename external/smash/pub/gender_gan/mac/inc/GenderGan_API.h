#ifndef _SMASH_GENDERGANAPI_H_
#define _SMASH_GENDERGANAPI_H_

#include "smash_module_tpl.h"
#include "smash_runtime_info.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void *GenderGanHandle;
#define TT_GENDER_GAN_MAX_FACE_LIMIT 10  // 最大支持人脸数

/**
 * @brief 模型参数类型
 */
typedef enum GenderGanParamType {
    kGenderGanParam1 = 1,
} GenderGanParamType;

/**
 * @brief 模型枚举
 *
 */
typedef enum GenderGanModelType {
    kGenderGanModel1 = 1,
    kGenderGanModel2 = 2,
    kGenderGanModelMax=10000,
} GenderGanModelType;

/**
 * @brief 封装预测接口的输入数据
 */
typedef struct GenderGanArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    int face_count;                 //人脸个数
    int id[TT_GENDER_GAN_MAX_FACE_LIMIT];
    float *landmark106[TT_GENDER_GAN_MAX_FACE_LIMIT];
    float yaws[TT_GENDER_GAN_MAX_FACE_LIMIT];
    float pitchs[TT_GENDER_GAN_MAX_FACE_LIMIT];
} GenderGanArgs;

typedef struct GenderGanImage {
    unsigned char *image;
    int width;
    int height;
    float matrix[6];
} GenderGanImage;

/**
 * @brief 封装预测接口的返回值
 *
 */
typedef struct GenderGanRet {
    GenderGanImage faceImage;
    int face_count;
    int invalidDegree;
} GenderGanRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return GenderGan_CreateHandle
 */
AILAB_EXPORT
int GenderGan_CreateHandle(GenderGanHandle *out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return GenderGan_LoadModel
 */
AILAB_EXPORT
int GenderGan_LoadModel(GenderGanHandle handle,
                        GenderGanModelType type,
                        const char *model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return GenderGan_LoadModelFromBuff
 */
AILAB_EXPORT
int GenderGan_LoadModelFromBuff(GenderGanHandle handle,
                                GenderGanModelType type,
                                const char *mem_model,
                                int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return GenderGan_SetParamF
 */
AILAB_EXPORT
int GenderGan_SetParamF(GenderGanHandle handle,
                        GenderGanParamType type,
                        float value);

/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return GenderGan_SetParamS
 */
AILAB_EXPORT
int GenderGan_SetParamS(GenderGanHandle handle,
                        GenderGanParamType type,
                        char *value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT GenderGan_DO
 */
AILAB_EXPORT
int GenderGan_DO(GenderGanHandle handle,
                 GenderGanArgs *args,
                 GenderGanRet *ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT GenderGan_ReleaseHandle
 */
AILAB_EXPORT
int GenderGan_ReleaseHandle(GenderGanHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT GenderGan_DbgPretty
 */
AILAB_EXPORT
int GenderGan_DbgPretty(GenderGanHandle handle);



/**
 * GenderGanRet 的free函数
 * @return                  sucessed SMASH_OK or failed others
 */
AILAB_EXPORT int GenderGan_FreeResultMemory(GenderGanRet * result);

/**
 * 分配GenderGanRet结构的malloc函数， 使用该函数分配的空间，一定要使用FaceFitting_FreeResultMemory来释放
 * @return                  分配失败会返回 NULL
*/
AILAB_EXPORT GenderGanRet * GenderGan_MallocResultMemory(GenderGanHandle handle);


/**
 * @breif 获取运行时数据
 * @return
 *
 */
AILAB_EXPORT int GenderGan_GetRuntimeInfo(GenderGanHandle handle, ModuleRunTimeInfo * result);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_GenderGANAPI_H_
