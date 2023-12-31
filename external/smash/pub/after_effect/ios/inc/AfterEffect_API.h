#ifndef _SMASH_AFTEREFFECTAPI_H_
#define _SMASH_AFTEREFFECTAPI_H_

#include "AttrSDK_API.h"
#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE AfterEffectHandle

  typedef void* MODULE_HANDLE;

  // 模型参数类型
  typedef enum AfterEffectParamType
  {
    // 是否使用摘要模式，0代表不使用，1代表使用，默认是0
    kAfterEffectSummaryMode,
    // 最大抽帧数目，默认是60
    kAfterEffectSampleMaxNum,
    // 抽帧频率，设置kAfterEffectSampleFPS后，kAfterEffectSampleMaxNum将失效
    // 参数类型为浮点型
    kAfterEffectSampleFPS,
    // 最大封面数目，默认是6
    kAfterEffectSampleMaxCover,
    // 使用人脸属性，0代表不使用，1代表使用，默认是0
    kAfterEffectUseFaceAttr,
    // 打分权重组合的版本，目前有（1，2，3）三个版本，默认是1
    kAfterEffectScoreVersion,
  } AfterEffectParamType;

  // 模型枚举，有些模块可能有多个模型
  typedef enum AfterEffectModelType
  {
    kAfterEffectModel1,
    kAfterEffectModelWithMeaningless,
    kAfterEffectModelWithAll,
  } AfterEffectModelType;

  typedef enum AfterEffectFuncType
  {
    kAfterEffectFuncGetFrameTimes,
    kAfterEffectFuncCalcScore,
    kAfterEffectFuncGetCoverInfos,
    kAfterEffectFuncShotSegment,
    kAfterEffectFuncSummary,
  } AfterEffectFuncType;

  // clang-format off
// 以下参数用于计算要抽取的帧时刻(ms)
// func_type = kAfterEffectFuncGetFrameTimes
// int video_duration_ms;  // 视频的时长，单位是毫秒

// 以下参数用于计算当前帧的得分
// func_type = kAfterEffectFuncCalcScore
// ModuleBaseArgs base;             // 当前帧的图像信息
// int time_stamp_ms;               // 当前帧的时刻
// const AIFaceInfo *face_info_ptr; // 当前帧人脸SDK结果

// 以下参数用于获取最终的封面
// func_type = kAfterEffectFuncGetCoverInfos
// 无

// 以下参数用于对视频切片
// func_type = kAfterEffectFuncShotSegment
// 无

// 以下参数用于对视频摘要
// func_type = kAfterEffectFuncSummary
// int summary_duration_ms;         // 从原视频中截取的总时长，单位是毫秒
  // clang-format on
  typedef struct AfterEffectArgs
  {
    AfterEffectFuncType func_type;
    ModuleBaseArgs base;
    int video_duration_ms;
    int time_stamp_ms;
    const AIFaceInfo* face_info_ptr;
    int summary_duration_ms;

    //
    // 当kAfterEffectUseFaceAttr == 1的时候需要设置attr_info_ptr这个参数
    // 该参数的设置会使得有人的视频，封面效果更好，但也会增加30%的计算时间
    // 按如下方式获取最佳人脸的人脸属性，并赋值给attr_info_ptr
    //
    // int face_cnt = face_info_ptr->face_count;
    // if (face_cnt > 0) {
    //   int center_n = 0;
    //   float center_dist = FLT_MAX;
    //   float center_x = base.image_width / 2.0f;
    //   float center_y = base.image_height / 2.0f;
    //   for (int n = 0; n < face_cnt; ++n) {
    //     const AIFaceInfoBase &base_info = face_info_ptr->base_infos[n];
    //     float x = (base_info.rect.left + base_info.rect.right) / 2.0f;
    //     float y = (base_info.rect.bottom + base_info.rect.top) / 2.0f;
    //     float dist = (center_x - x) * (center_x - x) + (center_y - y) * (center_y - y);
    //     if (dist < center_dist) {
    //       center_n = n;
    //       center_dist = dist;
    //     }
    //   }
    //   AttrInfo attr_info;
    //   FS_DoAttrPredict(_attr_handle, base.image,
    //                    base.pixel_fmt,
    //                    base.image_width,
    //                    base.image_height,
    //                    base.image_stride,
    //                    &face_info_ptr->base_infos[center_n],
    //                    ATTRACTIVE|HAPPINESS,
    //                    &attr_info);
    //   attr_info_ptr = &attr_info;
    // } else {
    //   attr_info_ptr = nullptr;
    // }
    //
    const AttrInfo* attr_info_ptr;
  } AfterEffectArgs;

  typedef struct AfterEffectScoreInfo
  {
    // 得分对应的时刻
    int time;
    // 最终得分
    float score;
    // 人脸得分
    float face_score;
    // 综合质量得分
    float quality_score;
    // 清晰度得分
    float sharpness_score;
  } AfterEffectScoreInfo;

  typedef struct AfterEffectShotSegment
  {
    // 切片得分最高点时刻
    int time_highlight;
    // 切片开始时间
    int time_start;
    // 切片结束时间
    int time_end;
    // 切片得分
    float score;
  } AfterEffectShotSegment;

  typedef struct AfterEffectRet
  {
    // 对应 func_type : kAfterEffectFuncGetFrameTimes
    // 要抽取帧时间的数量
    int frame_time_num;
    // 抽取帧时间的首地址，内存由SDK内部管理,包含frame_time_num个元素
    int* frame_time_ptr;

    // 对应 func_type :  kAfterEffectFuncCalcScore
    // 最终得分 score = (face_score * 0.3 + quality_score + sharpness_score * 0.1) / 1.4
    float score;
    // 人脸得分
    float face_score;
    // 综合质量得分
    float quality_score;
    // 清晰度得分
    float sharpness_score;
    // 无意义模型得分
    float meaningless_score;
    // 人像得分
    float portrait_score;

    // 对应 func_type :  kAfterEffectFuncGetCoverInfos
    // 要抽取封面的数量
    int cover_num;
    // 抽取封面时间的首地址，内存由SDK内部管理,包含cover_num个元素
    int* cover_time_ptr;
    // 封面得分的首地址，内存由SDK内部管理, 包含cover_num个元素
    float* cover_score_ptr;

    // 对应 func_type :  kAfterEffectFuncShotSegment
    // 得分数量
    int score_info_num;
    // 得分信息的首地址，内存由SDK内部管理，包含score_info_num个元素
    AfterEffectScoreInfo* score_info_ptr;
    // 切片的数目
    int shot_segment_num;
    // 切片的首地址，内存由SDK内部管理，包含shot_segment_num个元素
    AfterEffectShotSegment* shot_segment_ptr;

    // 对应 func_type :  kAfterEffectFuncShotSegment
    // 切片的数目
    int summary_shot_num;
    // 切片的首地址，内存由SDK内部管理，包含summary_shot_num个元素
    AfterEffectShotSegment* summary_shot_ptr;
  } AfterEffectRet;

  // 创建句柄
  AILAB_EXPORT int AfterEffect_CreateHandle(AfterEffectHandle* handle);

  // 加载模型（从文件系统中加载）
  AILAB_EXPORT int AfterEffect_LoadModel(AfterEffectHandle handle,
                                         AfterEffectModelType type,
                                         const char* model_path);

  // 加载模型（从内存中加载，Android 推荐使用该接口）
  AILAB_EXPORT int AfterEffect_LoadModelFromBuff(AfterEffectHandle handle,
                                                 AfterEffectModelType type,
                                                 const char* mem_model,
                                                 int model_size);

  // 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
  // 接口进行更换
  AILAB_EXPORT int AfterEffect_SetParamF(AfterEffectHandle handle, AfterEffectParamType type, float value);

  // 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
  // 接口进行更换
  AILAB_EXPORT int AfterEffect_SetParamS(AfterEffectHandle handle, AfterEffectParamType type, char* value);

  // 算法主调用接口
  AILAB_EXPORT int AfterEffect_DO(AfterEffectHandle handle, AfterEffectArgs* args, AfterEffectRet* ret);

  // 销毁句柄
  AILAB_EXPORT int AfterEffect_ReleaseHandle(AfterEffectHandle handle);

  // 销毁返回对象
  AILAB_EXPORT int AfterEffect_ReleaseRet(AfterEffectRet* ret);

  // 打印该模块的参数，用于调试
  AILAB_EXPORT int AfterEffect_DbgPretty(AfterEffectHandle handle);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // _SMASH_AFTEREFFECTAPI_H_
