#ifndef _HAIR_PARSER_API_H
#define _HAIR_PARSER_API_H

#include "tt_common.h"
#include "smash_module_tpl.h"

// prefix: HP -> HairParser

#if defined __cplusplus
extern "C" {
#endif
// clang-format off
typedef void* HairParserHandle;

#define HP_GER_CHANNEL_NUM 5   //
#define HP_MAX_OUTPUT_SIZE 256 // 挑染输出最大长度

/* add by wuxinglong
 * @brief SDK参数
 * HP_DetectMode:
 *    算法参数，用来设置模式，默认为视频模式
 *    - 0: 视频模式
 *    - 1: 图像模式
 * HP_OutputMinSideLen:
 *    返回短边的长度, 默认值为128, 需要为8的倍数；
 * HP_RefineBoundary:
 *    是否启用头皮边缘优化, 默认为启用(>=1),设为0不启用；
 * HP_GaussianKsize/HP_GaussianSigma/HP_GaussianScale:
 *    头皮边缘优化强度，建议由Lab RD给出设置建议,目前建议调节的强度范围为9/1~3/1~2
 * HP_GaussianKsizeOutside/HP_GaussianSigmaOutside/HP_GaussianScaleOutside:
 *    头发外边缘优化强度，建议由Lab RD给出设置建议,目前建议调节的强度范围为9/1~3/1~2
 * HP_OutputScale
      默认是0.5，那么HairParserRetInfo里面宽高最大为128，如果是1.0，则宽高最大为256
 * HP_StaticNum:
 *    判断几帧以上视频流没有变化输入即判断为图片，建议设置为25帧
 **/
typedef enum HP_ParamType {
    HP_DetectMode = 0,
    HP_OutputMinSideLen = 1,
    HP_RefineBoundary = 2,
    HP_GaussianKsize = 3,
    HP_GaussianSigma = 4,
    HP_GaussianScale = 5,
    HP_GaussianKsizeOutside = 6,
    HP_GaussianSigmaOutside = 7,
    HP_GaussianScaleOutside = 8,
    HP_OutputScale = 9,
//    HP_StaticNum = 9
} HP_ParamType;

/*
 * @brief 设置SDK参数
 **/
typedef enum HairParserModelType {
  kHairParserSegModel1 = 0, // 头发分割模型
  kHairParserGERModel1 = 1, // 头发挂耳染(GER)分割模型
} HairParserModelType;

/*
 0 左外挂耳染
 1 左内挂耳染
 2 右外挂耳染
 3 右内挂耳染
 
 参考飞书链接
 https://bytedance.feishu.cn/docs/doccnfva8RapWiLERX5OOTXUP1c#
 
 return_index代表返回的前4个mask的信息（alpha[0-3]）
 return_index 默认为-1，按需获取mask，这样可以省一些性能开销
 举例说明
 return_index[0] = [0, -1, -1, -1]，alpha[0]为左外挂耳mask
 return_index[1] = [1, -1, -1, -1]，alpha[1]为右外挂耳mask
 return_index[2] = [1, 2, -1, -1]，alpha[2]为右外挂耳和左内挂耳合并在一个mask的结果
 return_index[3] = [0, 1, 2, 3]，alpha[3]为左外挂耳、右外挂耳、左内挂耳、右内挂耳全在一个mask上面的结果
 */
typedef struct HairParserArgsInfo {
  ModuleBaseArgs base;
  int return_index[HP_GER_CHANNEL_NUM-1][HP_GER_CHANNEL_NUM-1]; //
} HairParserArgsInfo;

typedef struct HairParserRetInfo {
unsigned char *alpha[HP_GER_CHANNEL_NUM]; // 前4个为return_index设置的结果，最后一个是头发分割mask
//  AIRect bbox[1];
  int width; // alpha 宽度 最大为128
  int height; // alpha 高度 最大为128
} HairParserRetInfo;


AILAB_EXPORT
int HP_SetParamNew(HairParserHandle handle, HP_ParamType type, int value);

/*
 * @brief 设置优化头发边缘的参数
 **/
AILAB_EXPORT
int HP_SetRefineParam(HairParserHandle handle, HP_ParamType type, float value);

AILAB_EXPORT
// 初始化光流
int HP_ResetFlow(HairParserHandle handle);

AILAB_EXPORT
int HP_CreateHandler(HairParserHandle* out);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int HP_InitModel(HairParserHandle handle, const char* param_path);

AILAB_EXPORT
int HP_InitModelFromBuf(HairParserHandle handle, const unsigned char* param_buff, unsigned int len);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int HP_InitModelV2(HairParserHandle handle, HairParserModelType type, const char* param_path);

AILAB_EXPORT
int HP_InitModelFromBufV2(HairParserHandle handle, HairParserModelType type, const unsigned char* param_buff, unsigned int len);

// 废弃， 后面使用 HP_SetParamNew
// net_input_width 和 net_input_height
// 表示神经网络的传入，一般情况下不同模型不太一样，具体值需要 lab-cv 的人提供。
// 此处（HairParser）传入值约定为 net_input_width = 128, net_input_height = 224
//
// use_tracking: 算法时的参数，目前传入 true 即可
// use_blur: 算法时的参数, 目前传入 true 即可
AILAB_EXPORT
int HP_SetParam(HairParserHandle handle,
                int net_input_width,
                int net_input_height,
                bool use_tracking,
                bool use_blur);

AILAB_EXPORT
int HP_GetHairBbox(HairParserHandle handle,
                   float* left,
                   float* right,
                   float* top,
                   float* bottom);
// output_width, output_height, channel 用于得到 HP_DoHairParseing 接口输出的
// alpha 大小 如果在 HP_SetParam 的参数中，net_input_width，net_input_height
// 已按约定传入，即 net_input_width = 128, net_input_height = 224
// 那么返回值：output_width = 64, output_height = 112
//
//
// (net_input_width, net_input_height) 与 (output_width, output_height)
// 之间的关系不同模型 不太一样，需要询问 lab-cv 的同学 在该接口中，channel
// 始终返回 1
AILAB_EXPORT
int HP_GetOutputShape(HairParserHandle handle,
                      int* output_width,
                      int* output_height,
                      int* channel);

// src_image_data 为传入图片的大小，图片大小任意
// pixel_format， width, height, image_stride 为传入图片的信息
AILAB_EXPORT
int HP_DoHairParseing(HairParserHandle handle,
                      const unsigned char* src_image_data,
                      PixelFormatType pixel_format,
                      int width,
                      int height,
                      int image_stride,
                      ScreenOrient orient,
                      unsigned char* dst_alpha_data,
                      bool need_flip_alpha);

AILAB_EXPORT
int HP_DoHairParseingGER(HairParserHandle handle,
                      HairParserArgsInfo* hairParserArgsInfo,
                      HairParserRetInfo* hairParserRetInfo);


AILAB_EXPORT
int HP_GetOutputShapeWithInputShape(HairParserHandle handle,
                      int input_width,
                      int input_height,
                      int* output_width,
                      int* output_height);

AILAB_EXPORT
int HP_DoHairParseingWithSize(HairParserHandle handle,
                      const unsigned char* src_image_data,
                      PixelFormatType pixel_format,
                      int width,
                      int height,
                      int image_stride,
                      ScreenOrient orient,
                      unsigned char* dst_alpha_data,
                      int dst_alpha_size,
                      bool need_flip_alpha);

AILAB_EXPORT
float HP_GetHairParam(HairParserHandle handle);

AILAB_EXPORT
int HP_ReleaseHandle(HairParserHandle handle);

// 内存申请
AILAB_EXPORT
HairParserRetInfo* HP_MallocResultMemory(void* handle);

// 内存释放
AILAB_EXPORT
int HP_FreeResultMemory(HairParserRetInfo* res);

// clang-format on
#if defined __cplusplus
};
#endif

#endif  // _HAIR_PARSER_API_H

