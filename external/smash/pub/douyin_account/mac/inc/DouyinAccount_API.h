/*!
 @author 庄妮
 @version 1.0 2019/07/15 Creation
 */
#pragma once
#include "smash_module_tpl.h"
#include "tt_common.h"
#include <string>

#if defined __cplusplus
extern "C" {
#endif
typedef void* DouyinAccountHandle;

/**
 * @brief 
 * 
 */
typedef struct AILAB_EXPORT douyinAccountArgs {
  ModuleBaseArgs base;
} douyinAccountArgs;

/**
 * @brief 用于存储检测结果,默认一张图片只检测到一个对象
 * 
 */
typedef struct AILAB_EXPORT douyinAccountDetInfo {
  int bounding_box[4];           ///< 检测框像素位置
  float prob = 0;                ///< 置信度
  bool has_det = false;          ///< 是否检测到抖音号
} douyinAccountDetInfo;

/**
 * @brief 用于存储抖音号检测及识别结果
 *
 */
typedef struct AILAB_EXPORT douyinAccountInfo {
  douyinAccountDetInfo det_res;    ///< 检测结果
  bool has_recog_info = false;        ///< 是否识别到抖音号内容
  std::string douyin_account_recog_res;        ///< 抖音号识别结果
} douyinAccountInfo;

/**
 * @brief 创建handler
 * 
 * @param handle 句柄指针
 * @return CardOCR_CreateHandle 
 */
AILAB_EXPORT
int douyinAccountCreateHandle(DouyinAccountHandle* handle);

/**
 * @brief 设置sdk需要加载的模型文件，model_path为模型路径
 * 
 * @param handle 
 * @param model_path 
 * @return AILAB_EXPORT CardOCR_LoadModel 
 */
AILAB_EXPORT
int douyinAccountLoadModel(DouyinAccountHandle handle, const char* model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 * 
 * @param handle 句柄
 * @param mem_model 模型内存
 * @param model_size 模型内存长度
 * @return CardOCR_LoadModelFromBuff 
 */
AILAB_EXPORT int douyinAccountLoadModelFromBuff(void* handle,
                                           const unsigned char* mem_model,
                                           int model_size);

/**
 * @brief 输入一张图，进行抖音号检测和识别
 * 
 * @param handle 句柄
 * @param args 输出参数
 * @param bankCardRes 输出参数
 * @return AILAB_EXPORT CardOCR_DO_Bank
 */
AILAB_EXPORT
int douyinAccountDo(DouyinAccountHandle handle, douyinAccountArgs* args, douyinAccountInfo* douyinAccountRes);

/**
 * @brief 释放资源
 * 
 * @param handle 
 * @return void 
 */
AILAB_EXPORT
void douyinAccountReleaseHandle(DouyinAccountHandle handle);

#if defined __cplusplus
}
#endif
