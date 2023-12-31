#ifndef _SMASH_MVRECOMMENDAPI_H_
#define _SMASH_MVRECOMMENDAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "smash_moment_base.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* MVRecommendHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum MVRecommendParamType {
  kMVRecommendMode = 1,  // unused
} MVRecommendParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum MVRecommendModelType {
  kMVRecommendModel1 = 1,
} MVRecommendModelType;


/**
 * @brief 模板和moment信息的封装
 *
 */

typedef struct MVVideoSegInfo {
  float target_start_time;  // second
  float target_end_time;  // second
  const char* fragment_id;
  float crop_ratio;
  const char* material_type;
  float source_duration;  // second
  int group_id;
} MVVideoSegInfo;

typedef struct MVTemplateInfo {
  int64_t template_id;
  const char* tag;
  const char* style;
  const char* expr;
  int num_segs;
  bool is_common;
  int source;  // 1: jtk, 2: yj
  const char* zip_url;
  MVVideoSegInfo* segs_info;
} MVTemplateInfo;

typedef struct MVMomentInfo {
  const char* moment_id;
  int num_materials;
  MomentMaterialInfo* materials_info;
} MVMomentInfo;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct MVRecommendArgs {
  MVTemplateInfo* mv_templates_info;
  MVMomentInfo* mv_moments_info;
  int num_templates;
  int num_moments;
  int mode;  // 0: common, 1: backup
} MVRecommendArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct MVRecommendRet {
  VideoTempRecType* match_info;
  int num_match;
} MVRecommendRet;

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return MVRecommend_CreateHandle
 */
AILAB_EXPORT
int MVRecommend_CreateHandle(MVRecommendHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return MVRecommend_LoadModel
 */
AILAB_EXPORT
int MVRecommend_LoadModel(MVRecommendHandle handle,
                         MVRecommendModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return MVRecommend_LoadModelFromBuff
 */
AILAB_EXPORT
int MVRecommend_LoadModelFromBuff(MVRecommendHandle handle,
                                 MVRecommendModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return MVRecommend_SetParamF
 */
AILAB_EXPORT
int MVRecommend_SetParamF(MVRecommendHandle handle,
                         MVRecommendParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT MVRecommend_DO
 */
AILAB_EXPORT
int MVRecommend_DO(MVRecommendHandle handle,
                  MVRecommendArgs* args,
                  MVRecommendRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT MVRecommend_ReleaseHandle
 */
AILAB_EXPORT
int MVRecommend_ReleaseHandle(MVRecommendHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT MVRecommend_DbgPretty
 */
AILAB_EXPORT
int MVRecommend_DbgPretty(MVRecommendHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief 释放句柄的返回值私有变量所占用的空间
 *
 * @param handle
 * @return AILAB_EXPORT MVRecommend_ReleaseRet
 */
AILAB_EXPORT
int MVRecommend_ReleaseRet(MVRecommendHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_MVRECOMMENDAPI_H_
