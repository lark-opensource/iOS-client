#ifndef _PET_MATTING_API_H
#define _PET_MATTING_API_H

#include "smash_module_tpl.h"
#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

#define PET_MATTING_CATEGORIES 2

typedef void* PetMattingHandle;

/*
* @brief 算法返回mask类型枚举
**/
typedef enum PetM_AlphaType {
  PetM_Alpha_Pet = 1, // 将猫狗当成一个宠物类输出一个mask
  PetM_Alpha_All = 2, // 将猫狗当成不同类输出两个mask
  PetM_Alpha_Cat = 3, // 只输出猫的一个mask
  PetM_Alpha_Dog = 4, // 只输出狗的一个mask
} PetM_AlphaType;

/*
 * @brief SDK参数
 * PetM_EdgeMode:
 *    算法参数，用来设置边界的模式
 *    - 1: 不加边界
 *    - 2: 加边界
 *    - 3: 加边界, 其中, 2 和 3 策略不太一样，但效果上差别不大，可随意取一个
 * PetM_OutputMinSideLen:
 *    不设置，只做GetParam；模型输入的短边长度, 默认值为256, 需要为16的倍数；
 * PetM_OutputWidth 不设置，只做GetParam
 * PetM_OutputHeight 不设置，只做GetParam
 * PetM_OutputType:
 *    算法返回mask类型，可选值见PetM_Alpha_Type
 */
typedef enum PetM_ParamType {
  PetM_EdgeMode = 0,
  PetM_OutputMinSideLen = 1,
  PetM_OutputWidth = 2,
  PetM_OutputHeight = 3,
  PetM_OutputType = 4,
} PetM_ParamType;

/*
 * @brief 模型类型枚举
 **/
typedef enum PetM_ModelType {
  PetM_UNREALTIME_MODEL = 1,
} PetM_ModelType;

/*
 * @brief 输入参数结构体
 **/
typedef struct PetM_Args {
  ModuleBaseArgs base;   //基本的视频帧相关的数据
  bool need_flip_alpha;  //指定是否需要对结果翻转
} PetM_Args;

/*
 * @brief 返回结果结构体，调用PetM_MallocResultMemory申请内存，PetM_FreeResultMemory释放
 */
typedef struct PetM_Ret {
  unsigned char*
    alpha[PET_MATTING_CATEGORIES];  // alpha[c][i, j] 表示第c类 第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;   // alpha 的宽度
  int height;  // alpha 的高度
  int num_mask; // 有效的mask个数
} PetM_Ret;

/*
 * @brief 创建Matting 句柄
 **/
AILAB_EXPORT
int PetM_CreateHandler(PetMattingHandle* out);

/*
 * @brief 从文件初始化模型参数
 **/
AILAB_EXPORT
int PetM_InitModel(PetMattingHandle handle,
                  PetM_ModelType type,
                  const char* param_path);

/*
 * @brief 从buffer 初始化模型参数，android 推荐使用
 **/
AILAB_EXPORT
int PetM_InitModelFromBuf(PetMattingHandle handle,
                        PetM_ModelType type,
                        const char* param_buf,
                        unsigned int len);
/*
 * @brief 设置SDK参数
 **/
AILAB_EXPORT
int PetM_SetParam(PetMattingHandle handle, PetM_ParamType type, int value);

/*
 * @brief 获取SDK参数
 **/
AILAB_EXPORT
int PetM_GetParam(PetMattingHandle handle, PetM_ParamType type, int* value);

/*
 * @brief 进行抠图操作
 * @note ret结果内存需要调用PetM_MallocResultMemory申请
 **/
AILAB_EXPORT
int PetM_DoPetMatting(PetMattingHandle handle, PetM_Args* arg, PetM_Ret* ret);

/*
* @brief 结果内存申请
**/
AILAB_EXPORT
PetM_Ret* PetM_MallocResultMemory(PetMattingHandle handle);

/*
* @brief 结果内存释放
**/
AILAB_EXPORT
int PetM_FreeResultMemory(PetM_Ret* ret);

/*
 * @brief 释放句柄
 **/
AILAB_EXPORT
int PetM_ReleaseHandle(PetMattingHandle handle);

#if defined __cplusplus
};
#endif
#endif  // _PET_MATTING_API_H
