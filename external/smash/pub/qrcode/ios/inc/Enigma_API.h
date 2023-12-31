#ifndef _SMASH_ENIGMA_API_H_
#define _SMASH_ENIGMA_API_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "tt_common.h"

// clang-format off
#define CODE_TYPE_QRCODE        0x00000001
#define CODE_TYPE_VORTEX_CODE   0x00000002
#define CODE_TYPE_UPC_A_CODE    0x00000004
#define CODE_TYPE_UPC_E_CODE    0x00000008
#define CODE_TYPE_EAN_8_CODE    0x00000010
#define CODE_TYPE_EAN_13_CODE   0x00000020
#define CODE_TYPE_CODE39_CODE   0x00000040
#define CODE_TYPE_CODE128_CODE  0x00000080
#define CODE_TYPE_DATA_MATRIX   0x00000100
#define CODE_TYPE_PDF_417       0x00000200
// clang-format on

typedef struct EnigmaPoint {
  float x;
  float y;
} EnigmaPoint;

typedef struct EnigmaCode {
  int type;    // 二维码的类型，目前支持2种: CODE_TYPE_QRCODE 和
               // CODE_TYPE_VORTEX_CODE
  char *text;  // 二维码的内容

  // 二维码的定位点坐标，QR二维码和漩涡码都有3个定位点
  // 目前坐标是以输入原图为标准大小的绝对坐标
  EnigmaPoint *points;
  int points_len;
} EnigmaCode;

// 二维码识别结果，默认情况下 code_count 为 1，如果需要返回图片上的所有二维码，
// 需要打开 EnigmaParamType.DecodeMultiple 配置，但该功能目前还不支持
typedef struct EnigmaResult {
  EnigmaCode *code;
  int code_count;
  // 推进系数为 {0,[1.0, 2.0]} 之间的值，0
  // 表示不需要推进,[1.0, 2.0]表示相机在原有的放大系数上需要推进的倍数。
  float zoom_in_factor;
} EnigmaResult;

typedef enum {
  KeepROISize = 1,  // 设置是否改变ROI的大小 (目前暂不支持)
  // 指定二维码的类型，目前有2种 {CODE_TYPE_QRCODE, CODE_TYPE_VORTEX_CODE}
  CodeType = 2,
  // 设置验证级别的高低, 目前有4个等级: {0, 1, 2, 3},
  // 数字越大，级别越高，级别越高，二维码的容错性更强，但可编码的字符数越小
  ECLevel = 3,
  // 设置版本的高低, 目前有6个版本: {1, 2, 3, 4, 5, 6},
  // 版本越高，能容纳的数据越多
  Version = 4,
  // 如果拍摄的图片上有多种码，那么把该值设置为1, 则会返回多种码的结果,
  // 默认只返回一种结果
  DecodeMultiple = 5,
  // 在二维码比较小的情况下，设置是否自动放缩
  AutoZoomIn = 6,
  //指定编码生成的图片是否带透明通道, 0表示无透明通道,生成三通道图片
  // 1表示码的环形区域和logo外都为透明，生成四通道图片
  // 2表示除了漩涡码的所占的圆形区域，其余部分都为透明，生成四通道图片
  BackgroundMode = 7,

  //扫描方式，默认0
  // 0表示相机模式
  // 1表示相册模式
  ScanType = 8,
    
  //支持反码和镜像码扫描，默认1
  EnableRF = 9,
    
  //增强相机扫码，将带来一定的延迟增加
  EnhanceCamera = 10,
    
} EnigmaParamType;

typedef void *EnigmaHandle;

AILAB_EXPORT
int Enigma_CreateHandle(EnigmaHandle *handle);

int Enigma_CreateHandleExt(EnigmaHandle *handle);

// 解码配置
// 如果不设置，默认会识别QR二维码和漩涡码
AILAB_EXPORT
int Enigma_SetDecodeHint(EnigmaHandle handle,
                         EnigmaParamType type,
                         float value);

// 编码配置
AILAB_EXPORT
int Enigma_SetEncodeHint(EnigmaHandle handle,
                         EnigmaParamType type,
                         float value);

// 从文件路径加载模型
//AILAB_EXPORT
//int Enigma_LoadModel(EnigmaHandle handle,
//                     const char* model_path);

//加载模型（从内存中加载，Android 推荐使用该接口）
//mem_model 模型文件buf指针
//model_size buf文件的大小
//attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
//AILAB_EXPORT
//int Enigma_LoadModelFromBuff(EnigmaHandle handle,
//                             const char* mem_model,
//                             int model_size);

// clang-format off
//
// 二维码/漩涡码解码API
//
// Args:
//   handle: 创建的句柄
//   image: 图像数据的内存位置
//   pixel_format: 图像数据的格式，目前支持以下几种格式:
//     kPixelFormat_RGBA8888 = 0,
//     kPixelFormat_BGRA8888 = 1,
//     kPixelFormat_BGR888 = 2,
//     kPixelFormat_RGB888 = 3,
//     kPixelFormat_NV12 = 4,
//   image_width: 图像的宽度
//   image_height: 图像的高度
//   image_stride: 图像的stride, 该值需要从API直接得到
//     该值跟image_width的关系: https://docs.microsoft.com/en-us/windows/desktop/medfound/image-stride
//   roi_left: 设置扫描区域离图片左边界的偏移
//   roi_top:  设置扫描区域离图片上边界的偏移
//   roi_width:  设置扫描区域的宽度
//   roi_height: 设置扫描区域的高度
//   orientation: 该值不需要随屏幕的横竖屏变化而变化，传入kClockwiseRotate_0即可
//
// Return:
//   ret: 返回值，内存由API里分配和释放
// clang-format on

AILAB_EXPORT
int Enigma_Decode(EnigmaHandle handle,
                  const unsigned char *image,
                  PixelFormatType pixel_format,
                  int image_width,
                  int image_height,
                  int image_stride,
                  int roi_left,
                  int roi_top,
                  int roi_width,
                  int roi_height,
                  ScreenOrient orientation,
                  EnigmaResult **ret);

int Enigma_DecodeExt(EnigmaHandle handle,
                     const unsigned char *image,
                     PixelFormatType pixel_format,
                     int image_width,
                     int image_height,
                     int image_stride,
                     int roi_left,
                     int roi_top,
                     int roi_width,
                     int roi_height,
                     ScreenOrient orientation,
                     EnigmaResult **ret);
//
// 二维码编码接口, 得到JPG数据
//
AILAB_EXPORT
int Enigma_QRCode_Encode(EnigmaHandle handle,
                         const char *content,
                         int scale,
                         int padding,
                         void **dst_data,
                         int *data_len);

//
// 二维码编码接口, 得到原码的bitmap，内存由API内部分配和释放
//
AILAB_EXPORT
int Enigma_QRCode_Encode2(EnigmaHandle handle,
                          const char *content,
                          void **dst_data,
                          int *width,
                          int *height);

// clang-format off
//
// 漩涡码编码接口
//
// Args:
//   center_logo_buff          : 中间 logo 区的字节流
//   center_logo_buff_size     : 中间 logo 区的字节流的长度
//   vortex_logo_buff          : 右上间 logo 区的字节流
//   vortex_logo_buff_size     : 右上间 logo 区的字节流的长度
//   decoration_logo_buff      : 大 V 图像的字节流
//   decoration_logo_buff_size : 大 V 图像的字节流的长度
//   add_v_logo: 表示是否在中心在的 logo 区加入大 V 的标记, 值为 {0, 1}
//   scale     : 表示漩涡码的大小，当 scale 为 1 时，漩涡码的直径约为 400
//               像素点, scale 为 2 时，直径约为 800 像素点，以此类推
//   padding   : 生成的图四周留白的大小，像素值
//
// Return:
//   dst_data  : 生成的图片字节流，编码格式为 jpg
//   data_len  : 图片字节流的长度
// clang-format on
AILAB_EXPORT
int Enigma_VortexCode_Encode(EnigmaHandle handle,
                             const char *content,
                             const char *center_logo_buff,
                             int center_logo_buff_size,
                             const char *vortex_logo_buff,
                             int vortex_logo_buff_size,
                             const char *decoration_logo_buff,
                             int decoration_logo_buff_size,
                             int add_v_logo,
                             int scale,
                             int padding,
                             void **dst_data,
                             int *data_len);

AILAB_EXPORT
int Enigma_Release(EnigmaHandle handle);

int Enigma_ReleaseExt(EnigmaHandle handle);

#ifdef __cplusplus
}
#endif

#endif  // _SMASH_ENIGMA_API_H_
