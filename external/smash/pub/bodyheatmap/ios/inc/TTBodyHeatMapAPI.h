#ifndef _TTBODYHEATMAPAPI_H_
#define _TTBODYHEATMAPAPI_H_
#ifdef __cplusplus
extern "C" {
#endif

#include "tt_common.h"

typedef void *TTBodyHeatMapHandle;

AILAB_EXPORT
int TTBodyHeatMapCreate(TTBodyHeatMapHandle *handle_ptr);

AILAB_EXPORT
void TTBodyHeatMapFree(TTBodyHeatMapHandle handle);

// 初始化模型
// param_path_ptr    : 模型的路径
// net_input_width   : 设置模型输入图片的宽度，默认是96，需要能被8整除
// net_input_height  : 设置模型输入图片的高度，默认是168，需要能被8整除
// moving_check      : 0代表不检查关节是否运动击中目标，非0代表检查是否运动击中
//                     注：只有调用TTBodyHeatMapPredict接口，moving_check才起作用
AILAB_EXPORT
int TTBodyHeatMapInit(TTBodyHeatMapHandle handle,
                      const char *param_path_ptr,
                      const int net_input_width = 96,
                      const int net_input_height = 168,
                      const int moving_check = 0);

AILAB_EXPORT
int TTBodyHeatMapInitFromBuf(TTBodyHeatMapHandle handle,
                             const char *param_buf,
                             unsigned int param_buf_len,
                             const int net_input_width = 96,
                             const int net_input_height = 168,
                             const int moving_check = 0);
// 计算heatmap并判断
// img_data_ptr             : 图片数据
// img_format               : 图片格式，例如kPixelFormat_BGRA8888
// img_width, img_height    : 图片的宽高
// img_stride               : 图片一行的字节数
// img_orient               : 图片的方向，例如kClockwiseRotate_0
// heatmap_data_ptr_ptr     : 返回heatmap数据的地址
// heatmap_width            : 返回heatmap的宽
// heatmap_height           : 返回heatmap的高
AILAB_EXPORT
int TTBodyHeatMapCalculate(TTBodyHeatMapHandle handle,
                           const unsigned char *img_data_ptr,
                           PixelFormatType img_format,
                           int img_width,
                           int img_height,
                           int img_stride,
                           ScreenOrient img_orient,
                           float **heatmap_data_ptr_ptr,
                           int *heatmap_width,
                           int *heatmap_height);

// 判断是否击中目标区域
// heatmap_data_ptr         : heatmap数据
// heatmap_width            : heatmap的宽
// heatmap_height           : heatmap的高
// img_width, img_height    : 图片的宽高
// target_region_tetrad_ptr : 目标区域四元组，大小为target_num * 4,
// 每一组分别是(x, y, w, h) target_num               : 目标区域的数目
// hit_results_ptr          : 击打结果，长度和target_num一致
//                            需要调用者预先分配sizeof(float) *
//                            target_num大小的空间
//                            得分大于0代表击中，得分区间(0, 1]
AILAB_EXPORT
int TTBodyHeatMapHitCheck(const float *heatmap_data_ptr,
                          int heatmap_width,
                          int heatmap_height,
                          int img_width,
                          int img_height,
                          int *target_region_tetrad_ptr,
                          int target_num,
                          float *hit_results_ptr);

// 计算heatmap并判断是否击中目标区域，等价于TTBodyHeatMapCalculate +
// TTBodyHeatMapHitCheck img_data_ptr             : 图片数据 img_format :
// 图片格式，例如kPixelFormat_BGRA8888 img_width, img_height    : 图片的宽高
// img_stride               : 图片一行的字节数
// img_orient               : 图片的方向，例如kClockwiseRotate_0
// target_region_tetrad_ptr : 目标区域四元组，大小为target_num * 4,
// 每一组分别是(x, y, w, h) target_num               : 目标区域的数目
// hit_results_ptr          : 击打结果，长度和target_num一致
//                            需要调用者预先分配sizeof(float) *
//                            target_num大小的空间
//                            得分大于0代表击中，得分区间(0, 1]
AILAB_EXPORT
int TTBodyHeatMapPredict(TTBodyHeatMapHandle handle,
                         const unsigned char *img_data_ptr,
                         PixelFormatType img_format,
                         int img_width,
                         int img_height,
                         int img_stride,
                         ScreenOrient img_orient,
                         int *target_region_tetrad_ptr,
                         int target_num,
                         float *hit_results_ptr);

// 获取关节点的坐标，需要先调用TTBodyHeatMapCalculate或者TTBodyHeatMapPredict
// joints_ptr_ptr               : 返回关节点的坐标，SDK内部分配空间
// joints_num_ptr               : 检测到关节点的数量
AILAB_EXPORT
int TTBodyHeatMapGetPoints(TTBodyHeatMapHandle handle,
                           TTJoint **joints_ptr_ptr,
                           int *joints_num_ptr);

#ifdef __cplusplus
}
#endif
#endif /* _TTBODYHEATMAPAPI_H_ */
