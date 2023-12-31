#ifndef _SMASH_SKINUNIFIEDAPI_H_
#define _SMASH_SKINUNIFIEDAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define SKINUNIFIED_CANVAS_SIZE 1024
#define SKINUNIFIED_CANVAS_SIZE_VIDEO 256
#define SKINUNIFIED_CANVAS_CHS 3

// clang-format off
typedef void* SkinUnifiedHandle;

/**
 * @brief 默认接受的图片尺寸
 *
 */
typedef struct SkinUnifiedRecommendConfig {
  int InputWidth = 2160;
  int InputHeight = 2160;
} SkinUnifiedRecommendConfig;

/**
 * @brief 模型参数类型
 *
 */
typedef enum SkinUnifiedParamType {
  kSkinUnifiedWidth = 1,
  kSkinUnifiedHeight = 2,
  kSkinUnifiedPixelFormat = 3,
  kSkinUnifiedMemoryLevel = 4,
  kSkinUnifiedLocalResult = 5,
} SkinUnifiedParamType;


/**
 * @brief 模型枚举，保留视频模式接口，未上线
 *
 */
typedef enum SkinUnifiedModelType {
  kSkinUnifiedImageModel = 1,
  kSkinUnifiedVideoModel = 2,
} SkinUnifiedModelType;


/**
* @brief 图片模式下, 选择输出原图大小还是模型原始输出大小
* 
*
*/
typedef enum LocalResultType{
  kLocalResultType_False = 0,
  kLocalResultType_True = 1,
} LocalResultType;

/**
* @brief 图片模式下的内存占用设定，通过改变输入的patch大小
* MAX - Lv1 - Lv2 - MIN = 1024 - 640 - 512 - 384
*
*/
typedef enum MemoryLevelType{
  kMemoryLevel_MAX = 0,
  kMemoryLevel_Lv1 = 1,
  kMemoryLevel_Lv2 = 2,
  kMemoryLevel_MIN = 255,
} MemoryLevelType;

/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct SkinUnifiedArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  int face_num;
  bool use_protect_mask;
} SkinUnifiedArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct SkinUnifiedRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* rgb;        ///< RGB pixels
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
  float matrix[6];
} SkinUnifiedRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return SkinUnified_CreateHandle
 */
AILAB_EXPORT
int SkinUnified_CreateHandle(SkinUnifiedHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return SkinUnified_LoadModel
 */
AILAB_EXPORT
int SkinUnified_LoadModel(SkinUnifiedHandle handle,
                          SkinUnifiedModelType type,
                          const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return SkinUnified_LoadModelFromBuff
 */
AILAB_EXPORT
int SkinUnified_LoadModelFromBuff(SkinUnifiedHandle handle,
                                  SkinUnifiedModelType type,
                                  const char* mem_model,
                                  int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return SkinUnified_SetParamF
 */
AILAB_EXPORT
int SkinUnified_SetParamF(SkinUnifiedHandle handle,
                          SkinUnifiedParamType type,
                          float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return SkinUnified_SetParamS
 */
AILAB_EXPORT
int SkinUnified_SetParamS(SkinUnifiedHandle handle,
                          SkinUnifiedParamType type,
                          char* value);




/**
 * @brief 内存占用较少(memoruy efficient)的主要调用接口
 *
 * 申请结果内存
 */
AILAB_EXPORT
void* SkinUnified_DO_ME_MallocResultMemory(void* handle);


/**
 * @brief 内存占用较少(memoruy efficient)的主要调用接口
 *
 * 释放结果内存
 */
AILAB_EXPORT
int SkinUnified_DO_ME_FreeResultMemory(SkinUnifiedRet* ret);

/**
 * @brief 内存占用较少(memoruy efficient)的主要调用接口
 *
 * 复制原图作为画布
 */
AILAB_EXPORT
int SkinUnified_DO_ME_CreateCanvas(SkinUnifiedHandle handle,
                                   SkinUnifiedArgs* args);


/**
*  @brief 内存占用较少(memoruy efficient)的主要调用接口
*
* 人脸对齐
*/

AILAB_EXPORT
int SkinUnified_DO_ME_PrepareCanvas(SkinUnifiedHandle handle,
                                    SkinUnifiedArgs* args, float* landmarks_in);

/**
* @brief 内存占用较少(memoruy efficient)的主要调用接口
*
* 处理并将结果绘制到画布
*/

AILAB_EXPORT
int SkinUnified_DO_ME_DrawOnCanvas(SkinUnifiedHandle handle,
                                    SkinUnifiedArgs* args,
                                    float alpha,
                                    unsigned char* protect_mask = nullptr);


/**
* @brief 内存占用较少(memoruy efficient)的主要调用接口
*
* 复制结果
*/

AILAB_EXPORT
int SkinUnified_DO_ME_CopyResult(SkinUnifiedHandle handle,
                                  SkinUnifiedRet* ret);



/**
* @brief 内存占用较少(memoruy efficient)的主要调用接口
*
* 获取画布数据指针
*/
AILAB_EXPORT
int SkinUnified_DO_ME_GetCanvasData(SkinUnifiedHandle handle,
                                    unsigned char** data_ptr);



/**
* @brief 内存占用较少(memoruy efficient)的主要调用接口
*
* 获取对齐人脸的关键点坐标
*/
AILAB_EXPORT
int SkinUnified_DO_ME_GetCanvasLandmarks(SkinUnifiedHandle handle,
                                    float** data_ptr);

AILAB_EXPORT
int SkinUnified_DO_ME_ClearStatus(SkinUnifiedHandle handle);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT SkinUnified_ReleaseHandle
 */
AILAB_EXPORT
int SkinUnified_ReleaseHandle(SkinUnifiedHandle handle);


/////////////////
// Video-Mode interface
AILAB_EXPORT
bool SkinUnified_Has_Video_Mode(void);

AILAB_EXPORT
int SkinUnified_VM_LoadModel(SkinUnifiedHandle handle, SkinUnifiedModelType type, const char* model_path);

AILAB_EXPORT
int SkinUnified_DO_VM_MallocResultMemory(void* handle);

AILAB_EXPORT
int SkinUnified_DO_VM_FreeResultMemory(SkinUnifiedRet* ret);

AILAB_EXPORT
int SkinUnified_DO_VM(SkinUnifiedHandle handle, SkinUnifiedArgs* args, float* landmarks_in, bool use_diff);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT SkinUnified_DbgPretty
 */
AILAB_EXPORT
int SkinUnified_DbgPretty(SkinUnifiedHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_SKINUNIFIEDAPI_H_
