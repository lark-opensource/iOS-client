#ifndef _SMASH_MODELTESTAPI_H_
#define _SMASH_MODELTESTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void *ModelTestHandle;
const static int TT_MODEL_TEST_MAX_FACE_LIMIT = 10;  // 最大支持人脸数

/**
 * @brief 模型参数类型
 */
enum ModelTestParamType {
};

/**
 * @brief 模型枚举
 *
 */
enum ModelTestModelType {
    kModelTestModel1 = 1,
    kModelTestModel2 = 2,
    kModelTestModel3 = 3,
    kModelTestModel4 = 4,
    kModelTestModel5 = 5,
    kModelTestModel6 = 6,

};

/**
 * @brief 封装预测接口的输入数据
 */
struct ModelTestArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
};

struct ModelTestImage {
    unsigned char *image;
    int width;
    int height;
};

/**
 * @brief 封装预测接口的返回值
 *
 */
struct ModelTestRet {
    ModelTestImage faceImage;
};


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ModelTest_CreateHandle
 */
AILAB_EXPORT
int ModelTest_CreateHandle(ModelTestHandle *out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ModelTest_LoadModel
 */
AILAB_EXPORT
int ModelTest_LoadModel(ModelTestHandle handle,
                        ModelTestModelType type,
                        const char *model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ModelTest_LoadModelFromBuff
 */
AILAB_EXPORT
int ModelTest_LoadModelFromBuff(ModelTestHandle handle,
                                ModelTestModelType type,
                                const char *mem_model,
                                int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return ModelTest_SetParamF
 */
AILAB_EXPORT
int ModelTest_SetParamF(ModelTestHandle handle,
                        ModelTestParamType type,
                        float value);

/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return ModelTest_SetParamS
 */
AILAB_EXPORT
int ModelTest_SetParamS(ModelTestHandle handle,
                        ModelTestParamType type,
                        char *value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ModelTest_DO
 */
AILAB_EXPORT
int ModelTest_DO(ModelTestHandle handle,
                 ModelTestArgs *args,
                 ModelTestRet *ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ModelTest_ReleaseHandle
 */
AILAB_EXPORT
int ModelTest_ReleaseHandle(ModelTestHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT ModelTest_DbgPretty
 */
AILAB_EXPORT
int ModelTest_DbgPretty(ModelTestHandle handle);



/**
 * ModelTestRet 的free函数
 * @return                  sucessed SMASH_OK or failed others
 */
AILAB_EXPORT int ModelTest_FreeResultMemory(ModelTestRet * result);

/**
 * 分配ModelTestRet结构的malloc函数， 使用该函数分配的空间，一定要使用FaceFitting_FreeResultMemory来释放
 * @return                  分配失败会返回 NULL
*/
AILAB_EXPORT ModelTestRet * ModelTest_MallocResultMemory(ModelTestHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
* @brief 获取模型版本和模型等级（大/小）的函数
*
* @param handle 句柄
* @param version 版本
* @param model_level ：  小模型：0  大模型：1
* @param max_buf_len 传入buf大小
* @return                  sucessed SMASH_OK or failed others
*/
AILAB_EXPORT int ModelTest_GetVersion(ModelTestHandle handle, char *version, int *modelLevel, long maxBufLength);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_MODELTESTAPI_H_
