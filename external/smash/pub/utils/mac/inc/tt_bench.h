#ifndef _SMASH_UTILS_BENCH_H_
#define _SMASH_UTILS_BENCH_H_
#include <mobilecv2/mobilecv2.hpp>
#include "internal_smash.h"
#include "tt_common.h"
SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(utils)

typedef struct ImageBaseParam {
  //图像的长宽
  int h;
  int w;
  int stride;
  void* data;
  //图像格式
  PixelFormatType pixel_format;
  //图像方向(目前不支持设置)
  ScreenOrient oritention;

} ImageBaseParam;

// GaussianBlur 参数
typedef struct GaussianBlurParam {
  int kernel_size;
  int sigma;

} GaussianParam;

// GaussianBlur 参数
typedef struct EqualizeHistParam {
} EqualizeHist;

typedef struct InputParam {
  ImageBaseParam image_param;
  GaussianParam gaussian_blur_param;
  EqualizeHistParam equ_hist_param;
} InputParam;

typedef struct Ret {
  //函数运行错误码,0表示运行正确
  int err_code;

  //单位ms(暂时没用)
  long time;

} Ret;

//只支持三通道画图像(rgb bgr)
void SmashBench_GaussianBlur(InputParam* input_param, Ret* ret);

//只支持灰度图(gray 也可以只传入 r,g,b 单通道)
void SmashBench_EqualizeHist(InputParam* input_param, Ret* ret);

//内部使用函数
int SmashBench_InitializeMat(ImageBaseParam& image_param, mobilecv2::Mat& mat);
NAMESPACE_CLOSE(utils)
SMASH_NAMESPACE_CLOSE

#endif  // _SMASH_UTILS_BENCH_H_
