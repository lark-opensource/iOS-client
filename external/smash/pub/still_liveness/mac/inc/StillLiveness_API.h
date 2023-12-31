#ifndef _SMASH_STILLLIVENESSAPI_H_
#define _SMASH_STILLLIVENESSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void* StillLivenessHandle;

#define STILLLIVENESS_MAX_FACE_NUM 2
#define STILL_LIVE_SIZE_BIGMODEL 224
#define STILL_QUALITY_SIZE 112

/* flags: */
/* #define FACEGATE_FLAG_GOOD 0 */ //只有flag=0时间才需要将人脸图上传给服务器
/* #define FACEGATE_FLAG_WAIT 1 */ //flag=1表示同一个人间隔帧数太短，仍处于等待阶段
/* #define FACEGATE_FLAG_UNLIVE 2 */ //非活体，预留的flag
/* #define FACEGATE_FLAG_LOWQUALITY 3 */ //人脸质量低
/* #define FACEGATE_FLAG_BADPOSE 4 */ //人脸姿态过大
/* #define FACEGATE_FLAG_TOOFAR 5 */ //人脸离镜头太远，人脸占画面的比例太小
/* #define FACEGATE_FLAG_TOOCLOSE 6 */ //人脸离镜头太近，人脸占画面的比例太大
/* #define FACEGATE_FLAG_NOFACE 7 */ //没有检测到人脸
/* #define FACEGATE_FLAG_UNDEFINE 100 */ //未定义的预留flag


/**
 * @brief 模型参数类型
 *
 */
typedef enum StillLivenessParamType {
  kStillLivenessResetAllParams = 0,
  kStillLivenessMinAreaR = 1,
  kStillLivenessMaxAreaR = 2,
  kStillLivenessMinQuality = 3,
  kStillLivenessWaitSkip = 4,
  kStillLivenessMaxRoll = 5,
  kStillLivenessMaxYaw = 6,
  kStillLivenessMaxPitch = 7,
} StillLivenessParamType;

/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum StillLivenessModelType {
  kStillLivenessModel1 = 1,
} StillLivenessModelType;

/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct StillLivenessArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  AIFaceInfo *faces_info; // 此处可以添加额外的算法参数
} StillLivenessArgs;

// SDK返回的结果信息
typedef struct StillLivenessRet {
  AIFaceInfoBase face_info;//FaceSDK中定义的人脸检测框、106点等基本信息
  int flag;//FACEGATE_FLAG信息，只有flag=0时间才需要将人脸图上传给服务器
  float light;//取值范围0<light<1,当前环境的亮度信息，当light<0.1时需要打开补光灯
  float quality;//取值范围0<quality<1，人脸质量分数，当quality<min_quality时质量不合格
  AIPoint points_crop[5];//上传给服务器的小图中人脸的5点坐标
  unsigned char img_crop[STILL_LIVE_SIZE_BIGMODEL * STILL_LIVE_SIZE_BIGMODEL * 4];//上传给服务器的人脸图160*160*4
  //unsigned char img_q[STILL_QUALITY_SIZE * STILL_QUALITY_SIZE * 3]; //for debug
  int output_height;//上传给服务器的人脸图的高=160
  int output_width;//上传给服务器的人脸图的宽=160
} StillLivenessRet;

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return StillLiveness_CreateHandle
 */
AILAB_EXPORT
int StillLiveness_CreateHandle(StillLivenessHandle* out);

/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return StillLiveness_LoadModel
 */
AILAB_EXPORT
int StillLiveness_LoadModel(StillLivenessHandle handle,
                         StillLivenessModelType type,
                         const char* model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return StillLiveness_LoadModelFromBuff
 */
AILAB_EXPORT
int StillLiveness_LoadModelFromBuff(StillLivenessHandle handle,
                                 StillLivenessModelType type,
                                 const char* mem_model,
                                 int model_size);

/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return StillLiveness_SetParamF
 */
AILAB_EXPORT
int StillLiveness_SetParamF(StillLivenessHandle handle,
                         StillLivenessParamType type,
                         float value);

/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return StillLiveness_SetParamS
 */
AILAB_EXPORT
int StillLiveness_SetParamS(StillLivenessHandle handle,
                         StillLivenessParamType type,
                         char* value);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT StillLiveness_DO
 */
AILAB_EXPORT
int StillLiveness_DO(StillLivenessHandle handle,
                  StillLivenessArgs* args,
                  StillLivenessRet* ret);

AILAB_EXPORT
int StillLiveness_DO_Mask(StillLivenessHandle handle,
                     StillLivenessArgs* args,
                     StillLivenessRet* ret);



/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT StillLiveness_ReleaseHandle
 */
AILAB_EXPORT
int StillLiveness_ReleaseHandle(StillLivenessHandle handle);

// AILAB_EXPORT
// int StillLiveness_DoubleInputPredict(
//                   StillLivenessHandle handle,
//                   const unsigned char *image,
//                   PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB, // GRAY(YUV暂时不支持)
//                   int image_width,               // 图片宽度
//                   int image_height,              // 图片高度
//                   int image_stride,              // 图片行跨度
//                   ScreenOrient orientation,      // 图片的方向
//                   const unsigned char *image2,
//                   PixelFormatType pixel_format2,  // 图片格式，支持RGBA, BGRA, BGR, RGB, // GRAY(YUV暂时不支持)
//                   int image_width2,               // 图片宽度
//                   int image_height2,              // 图片高度
//                   int image_stride2,              // 图片行跨度
//                   ScreenOrient orientation2,      // 图片的方向
//                   StillLivenessRetInfo *
//                   facegate_info_ptr  // 存放结果信息，需外部分配好内存
// );

/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT StillLiveness_DbgPretty
 */
AILAB_EXPORT
int StillLiveness_DbgPretty(StillLivenessHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_STILLLIVENESSAPI_H_
