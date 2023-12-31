#ifndef _C1_API_H_
#define _C1_API_H_

#include "tt_common.h"
#include "AttrSDK_API.h"

#if defined __cplusplus
extern "C"
{
#endif

  // prefix: C1 -> C1 Classification

#define NUM_CLASSES 22

  /*
   * @brief 模型枚举
   **/
  typedef enum
  {
    C1_MODEL_SMALL = 0x00000001,
    C1_MODEL_LARGE = 0x00000002,
    C1_MODEL_DET = 0x00000003

  } C1ModelType;

  typedef enum
  {
    Baby = 0,
    Beach,
    Building,
    Car,
    Cartoon,
    Cat,
    Dog,
    Flower,
    Food,
    Group,
    Hill,
    Indoor,
    Lake,
    Nightscape,
    Selfie,
    Sky,
    Statue,
    Street,
    Sunset,
    Text,
    Tree,
    Other
  } C1Type;


  typedef struct C1CategoryItem
  {
    float prob;
    bool satisfied;
  } C1CategoryItem;

  typedef struct C1Output
  {
    C1CategoryItem items[NUM_CLASSES];
  } C1Output;

  typedef void* C1Handle;

  /*
   @brief 创建分类句柄
   @param: 模型文件的路径
   @param: model_type 初始化的模型类型
   @param: 返回的分类句柄
   */
  AILAB_EXPORT
  int C1_CreateHandler(const char* model_path, C1ModelType model_type, C1Handle* handle);

  /*
   @brief 创建分类句柄, 从buf 读入
   @param: 模型文件的路径
   @param: 返回的分类句柄
   @param: model_buf 模型文件buf
   @param: len 模型大小长度
   @param: model_type 初始化的模型类型
   */
  AILAB_EXPORT
  int C1_CreateHandlerFromBuf(const char* model_buf, int len, C1ModelType model_type, C1Handle* handle);

  /*
   *@brief: 分类，结果存放在ptr_output中
   @param: handle 检测句柄
   @param: image 图片指针
   @param: pixel_format 图片像素格式
   @param: image_width 图片宽度
   @param: image_height 图片高度
   @param: image_stride 图片每行的字节数目
   @param: orientation 图片旋转方向
   @param: ptr_output 场景分类的检测结果返回，需要分配好内存
   */
  AILAB_EXPORT
  int C1_DoPredict(C1Handle handle,
                   const unsigned char* image,
                   PixelFormatType pixel_format,
                   int image_width,
                   int image_height,
                   int image_stride,
                   ScreenOrient orientation,
                   C1Output* ptr_output);

  AILAB_EXPORT
  int C1_Refine(C1Output* ptr_c1_output, AttrResult* ptr_attr_result, bool is_multi_label);

  typedef enum
  {
    C1_USE_VIDEO_MODE = 1,  //默认值为1，表示视频模式, 0:图像模式
    C1_USE_MultiLabels = 2, //默认为0， 表示不用多标签模式，1：多标签模式
  } C1ParamType;

  /*
   *@brief: 超参数设置
   @param: handle 检测句柄
   @C1ParamType: 参数类型
   @param: value 参数值
   */
  AILAB_EXPORT
  int C1_SetParam(C1Handle handle, C1ParamType type, float value);

  /*
   @brief: 释放资源
   @param: handle 检测句柄
   */
  AILAB_EXPORT
  int C1_ReleaseHandle(C1Handle handle);

#if defined __cplusplus
};
#endif

#endif // _C1_API_H_
