#ifndef ARSCAN_ARSCAN_API_H_
#define ARSCAN_ARSCAN_API_H_

#ifdef __cplusplus
#ifdef SDK_EXPORTS
#define ARSCAN_API extern "C" __attribute__((visibility("default")))
#else
#define ARSCAN_API extern "C"
#endif
#else
#ifdef SDK_EXPORTS
#define ARSCAN_API __attribute__((visibility("default")))
#else
#define ARSCAN_API
#endif
#endif

typedef enum {
  ARScanClockwiseRotate_0 = 0,
  ARScanClockwiseRotate_90 = 1,
  ARScanClockwiseRotate_180 = 2,
  ARScanClockwiseRotate_270 = 3,
  ARScanClockwiseRotate_0_mirror = 4,
  ARScanClockwiseRotate_90_mirror = 5,
  ARScanClockwiseRotate_180_mirror = 6,
  ARScanClockwiseRotate_270_mirror = 7,
  ARScanClockwiseRotate_Unknown = 99
} ARScanImageOrient;

typedef enum {
  ARScanPixelFormat_RGBA8888 = 0,
  ARScanPixelFormat_BGRA8888 = 1,
  ARScanPixelFormat_BGR888 = 2,
  ARScanPixelFormat_RGB888 = 3,
  ARScanPixelFormat_NV12 = 4,
  ARScanPixelFormat_GRAY = 5,
  ARScanPixelFormat_Unknown = 255,
} ARScanPixelFormatType;

struct TargetArea {
  float top_left_x;
  float top_left_y;
  float top_right_x;
  float top_right_y;
  float bottom_left_x;
  float bottom_left_y;
  float bottom_right_x;
  float bottom_right_y;
};

// Args:
//   status: 算法的状态，总共4种状态
//      PARAMETER_ERROR -1
//      SEARCHING 0
//      MATCHING 1
//      TRACKING(succeed) 2
//   target_index: 识别出来logo的index，-1代码失败
//   buffer[1]: 预留字段
typedef struct {
  int status;
  int target_index;
  TargetArea target_area;
  int buffer[1];
} ARScanResult;

typedef void *ArScanHandle;

// Args:
//   raw_data_path: feature文件路径
//   vocabulary_path: 码本文件路径
//
// Return:
//   ret: 返回值，内存由API里分配和释放
ArScanHandle ARS_InitARScan(const char *raw_data_path,
                            const char *vocabulary_path);

// Args:
//   raw_data_buffer: feature文件二进制
//   raw_data_buffer_length: feature文件二进制的长度
//   vocabulary_buffer: 码本文件二进制
//   vocabulary_buffer_length: 码本文件二进制的长度
//
// Return:
//   ret: 返回值，内存由API里分配和释放
ArScanHandle ARS_InitARScanFromBuffer(const char *raw_data_buffer,
                                      unsigned int raw_data_buffer_length,
                                      const char *vocabulary_buffer,
                                      unsigned int vocabulary_buffer_length);

// Args:
//   arscan_handler: 创建的句柄
//   image_data: 图像数据的内存位置
//   image_width: 图像的宽度
//   image_height: 图像的高度
//   stride: 图像的stride, 该值需要从API直接得到
//     该值跟image_width的关系:
//     https://docs.microsoft.com/en-us/windows/desktop/medfound/image-stride
//   image_format: 图像数据的格式，目前支持以下几种格式:
//     ARScanPixelFormat_RGBA8888 = 0,
//     ARScanPixelFormat_BGRA8888 = 1,
//     ARScanPixelFormat_BGR888 = 2,
//     ARScanPixelFormat_RGB888 = 3,
//     ARScanPixelFormat_GRAY = 5,
//   image_orientation:
//   该值不需要随屏幕的横竖屏变化而变化，传入ARScanClockwiseRotate_0即可
//   roi_x:  设置扫描区域离图片左边界的偏移
//   roi_y:  设置扫描区域离图片上边界的偏移
//   roi_width:  设置扫描区域的宽度
//   roi_height: 设置扫描区域的高度
//   is_draw: debug用，绘制结果
//
// Return:
//   ret: 返回值，内存由API里分配和释放
ARScanResult ARS_RunARScan(ArScanHandle arscan_handler,
                           const unsigned char *image_data,
                           int image_width,
                           int image_height,
                           int stride,
                           ARScanPixelFormatType image_format,
                           ARScanImageOrient image_orientation,
                           int roi_x,
                           int roi_y,
                           int roi_width,
                           int roi_height,
                           bool is_draw = false);

// Return:
//   ret: 返回值，支持识别的logo数目
int ARS_GetScannableNum(ArScanHandle arscan_handler);

// Args:
//   target_index: 识别出来logo的index
//
// Return:
//   ret: 返回值，识别的logo的名字
// 内存由SDK内部管理
const char *ARS_GetName(ArScanHandle arscan_handler, int target_index);

// Return:
//   ret: 返回值，-1代表识别
// 分辨率变化，切到后台再回来，必须调用
int ARS_ResetARScan(ArScanHandle handler);

void ARS_DestroyARScan(ArScanHandle arscan_handler);

#endif  // ARSCAN_ARSCAN_API_H_
