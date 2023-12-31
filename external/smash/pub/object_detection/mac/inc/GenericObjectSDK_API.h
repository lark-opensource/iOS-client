#ifndef __GENERIC_OBJECT_API__
#define __GENERIC_OBJECT_API__
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif
// prefix: GO -> GenericObject

// clang-format off
#define AI_MAX_GO_NUM 10

typedef void *GO_Handle;              /// < 目标检测句柄

typedef enum {
  DET_RED           =    0x00000001,  /// < 开启红包检测
  DET_DUMPLINGS     =    0x00000002,  /// < 开启饺子检测
  DET_FEAST         =    0x00000004,  /// < 开启年夜饭检测
} GO_ObjectType;

typedef enum {
  MaxObjectNum      =    1,
  TypeToDetect      =    2,
} GO_ParamType;

/// @brief SDK的输入
typedef struct {
  unsigned char *image;               /// < 图片指针
  PixelFormatType pixel_format;       /// < 图片像素格式
  int image_width;                    /// < 图片宽度
  int image_height;                   /// < 图片高度
  int image_stride;                   /// < 图片每行的字节数目
  ScreenOrient orientation;           /// < 图片旋转方向
  int bbox_classify;                  /// < 用于检测模式下，判断是否要加额外的分类过滤结果
                                      /// < 0代表不加分类，1代表要加分类过滤
} GO_Input;

/// @brief 检测结果
typedef struct GO_Info {
  AIRect rect;                        /// < 目标的矩形区域
  float score;                        /// < 目标检测的置信度
  int id;                             /// < GO_ID: 每个检测到的目标拥有唯一id,
                                      ///          跟踪丢失以后重新被检测到,
                                      ///          会有一个新的id
} GO_Info;

typedef struct GO_Output {
  GO_Info go_infos[AI_MAX_GO_NUM];    /// < 检测到的目标信息
  int count;                          /// < 检测到的目标数目，go_infos数组中，
                                      /// < 只有前count个结果是有效的
} GO_Output;

/*
@brief 创建目标检测句柄
@param: handle: 返回的目标句柄
*/
AILAB_EXPORT
int GO_CreateHandler(GO_Handle *handle);

/*
@brief 设置SDK参数
@param: handle: 检测句柄
@param: type: 参数类型, 如 MaxObjectNum, TypeToDetect
@param: value: 参数的值
@usage:
    GO_SetParam(handle, MaxObjectNum, 1);
    GO_SetParam(handle, TypeToDetect, DET_FEAST);
@notice:
    1.一个handle只能处理一种TypeToDetect;
    2.如果需要修改Type，那么需要重新调用GO_SetParam
    3.设置完TypeToDetect之后，需要InitModel才能生效
*/
AILAB_EXPORT
int GO_SetParam(GO_Handle handle, GO_ParamType type, float value);

/*
@brief 初始化模型，与GO_InitModelFromBuf初始化方法二选一
@param: handle: 检测句柄
@param: model_path: 模型文件的路径, 如 models/tt_object_detection_v1.0.model
*/
AILAB_EXPORT
int GO_InitModel(GO_Handle handle, const char* model_path);

/*
@brief 初始化模型，与GO_InitModel初始化方法二选一
@param: handle: 检测句柄
@param: model_buf: 模型，如 models/tt_object_detection_v1.0.model，的二进制数据
@param: buf_len: 模型二进制数据的长度
*/
AILAB_EXPORT
int GO_InitModelFromBuf(GO_Handle handle,
                        const char* model_buf,
                        unsigned int buf_len);

/*
*@brief: 目标检测跟踪
@param: handle: 检测句柄
@param: input: 图片信息
@param: output: 计算结果
*/
AILAB_EXPORT
int GO_DoPredict(GO_Handle handle,
                 const GO_Input* input,
                 GO_Output* output);

/*
*@brief: 目标检测
@param: handle: 检测句柄
@param: input: 图片信息
@param: output: 计算结果
*/
AILAB_EXPORT
int GO_DoDetect(GO_Handle handle,
                const GO_Input* input,
                GO_Output* output);

/*
@brief: 释放资源
@param: handle: 检测句柄
*/
AILAB_EXPORT
int GO_ReleaseHandle(GO_Handle handle);

// clang-format on
#if defined __cplusplus
};
#endif

#endif
