//
// Created by 王旭 on 2019/03/02.
//

#ifndef MODULES_CARSEGMENTATION_API_H
#define MODULES_CARSEGMENTATION_API_H

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

#define MAX_CAR_NUM 5

typedef void *CarSegmentationHandle;

//模型选择
enum CarSegmentationModelType {
  kCarSegmentationModelDefault = 0,
};

typedef struct AILAB_EXPORT CarSegmentationArgs {
  unsigned char *image;
  PixelFormatType pixel_format;
  int image_width;
  int image_height;
  int image_stride;
  ScreenOrient orientation;
  //最多分割的车辆数目，主要用于适配低端机的速度
  int maximum_segmentation_number = 1;
  //最多需要计算关键点的车辆数目，主要用于适配低端机的速度
  int maximum_landmark_number = 1;
  //是否执行分割
  bool calc_segmentation = false;
  //是否计算关键点
  bool calc_landmarks = false;
} CarSegmentationArgs;

//用于存储每一辆车的输出结果
typedef struct AILAB_EXPORT SingleCarInfo {
  //检测框像素位置
  int bounding_box[4];
  //车牌检测框位置
  int brand_bounding_box[4];
  //车辆方向信息
  int direction = -1;
  //跟踪中车辆的id
  int car_id;
  //当前车辆是否是第一次出现
  bool is_new = false;
  //车牌关键点 以x y 顺序排列 4组点
  int landmarks[8] = {-1, -1, -1, -1, -1, -1, -1, -1};
  //是否获取了有效的关键点
  bool valid_landmarks = false;
  //置信度 0 ～ 1.0
  float car_prob;
  //当前车辆的颜色
  int color = 0;
  //是否获取了有效的分割结果
  bool valid_segmentation = false;
  //用于存储分割结果 内存由SDK内部管理
  unsigned char *segmented_car;
  //分割边缘的x方向偏移
  int left_seg_border;
  //分割边缘的y方向偏移
  int up_seg_border;
  //分割图像的宽
  int seg_width;
  //分割图像的高
  int seg_height;
} SingleCarInfo;

//用于保存车身分割/关键点返回值的结构体参数
typedef struct AILAB_EXPORT CarSegmentationRet {
  //检测到的车的数量
  int detected_car_number;
  struct SingleCarInfo detected_info[MAX_CAR_NUM];
} CarSegmentationRet;

//创建handler
AILAB_EXPORT
int CarSegmentation_CreateHandle(CarSegmentationHandle *handle);

//设置sdk需要加载的模型文件，model_path为模型路径
AILAB_EXPORT
int CarSegmentation_LoadModel(CarSegmentationHandle handle,
                              CarSegmentationModelType type,
                              const char *model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int CarSegmentation_LoadModelFromBuff(
    void *handle,
    CarSegmentationModelType type,
    const unsigned char *mem_model,
    int model_size);

//输入一张图，进行车辆分割和关键点计算
AILAB_EXPORT
int CarSegmentation_DO(CarSegmentationHandle handle,
                       CarSegmentationArgs *args,
                       CarSegmentationRet *ret);

//释放资源
AILAB_EXPORT
void CarSegmentation_ReleaseHandle(CarSegmentationHandle handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int CarSegmentation_DbgPretty(void *handle);

#if defined __cplusplus
}
#endif

#endif
