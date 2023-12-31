#ifndef _SMASH_NAILAPI_H_
#define _SMASH_NAILAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define MAX_NAIL_NUM 5  // 最大指甲个数
#define MAX_NAIL_KPTS_NUM 8 //最大指甲关键点个数
#define NAIL_MAX_SIZE 224
  // clang-format off
  typedef void* NailHandle;
  
  /**
   * @brief 模型枚举，有些模块可能有多个模型
   *
   */
  typedef enum NailModelType {
    NailSegModel = 0x0001,          ///默认都需要
    NailKptsModel = 0x0002,
  } NailModelType;
  
  typedef enum NailParamType {
    NailSetPredKpts = 1,        ///是否需要关键点
    NailSetMaxLength = 2
  } NailParamType;
  
  /**
   * @brief 创建句柄
   *
   * @param handle 初始化的句柄
   * @return status
   */
  AILAB_EXPORT
  int Nail_SetParam(NailHandle handle,
                    NailParamType type,
                    int value);
  
  /**
   * @brief 封装预测接口的返回值
   *
   * @note 不同的算法，可以在这里添加自己的自定义数据
   */
  typedef struct NailInfo {
    // 给算法输入图片大小为 HxW
    unsigned char* alpha; // 指甲分割的mask, 其长宽高会根据输入图片大小把最长边resize到448
    int width; // mask的宽度, 不超过448
    int height; // mask的高度, 不超过448
    struct AIRect bboxes[MAX_NAIL_NUM]; // 指甲框 默认 detected 为 false, left/right 范围为 [0, W-1], top/bottom 范围为 [0, H-1]
    struct AIKeypoint kpts[MAX_NAIL_NUM][MAX_NAIL_KPTS_NUM]; // 指甲关键点, x/y默认为 0, x 范围为 [0, W-1], y 范围为 [0, H-1]
    int cls[MAX_NAIL_NUM]; // 指甲类别 范围 [0-5],默认为0，代表未知，1代表大拇指，2代表食指，3代表中指，4代表无名字，5代表小拇指
//    AIRect seg_airect;
  } NailInfo;
  
  /**
   * @brief 创建句柄
   *
   * @param out 初始化的句柄
   * @return Nail_CreateHandle
   */
  AILAB_EXPORT
  int Nail_CreateHandle(NailHandle* out);
  
  /**
   * @brief 从文件路径加载模型
   *
   * @param handle 句柄
   * @param type 需要初始化的句柄
   * @param model_path 模型路径
   * @note 模型路径不能为中文、火星文等无法识别的字符
   * @return Nail_LoadModel
   */
  AILAB_EXPORT
  int Nail_LoadModel(NailHandle handle,
                     NailModelType type,
                     const char* model_path);
  
  /**
   * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
   *
   * @param handle 句柄
   * @param type 初始化的模型类型
   * @param mem_model 模型文件buf指针
   * @param model_size buf文件的大小
   * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
   * @return Nail_LoadModelFromBuff
   */
  AILAB_EXPORT
  int Nail_LoadModelFromBuff(NailHandle handle,
                             NailModelType type,
                             const char* mem_model,
                             int model_size);
  
  /**
   * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
   *
   
   * @param handle 句柄
   * @param net_input_width 模型输入图片的宽度
   * @param net_input_height 模型输入图片的高度
   * @attention 不调用该函数，或者设置net_input_width, net_input_height任意一个为-1时, 则默认按照将图像的最长边resize到224，比如 720x1280的图片，模型输入的大小为128x224
   * @return Nail_SetInputShape
   */
  AILAB_EXPORT
  int Nail_SetInputShape(NailHandle handle,
                         int net_input_width,
                         int net_input_height);
  
  /**
   * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
   *
   
   * @param handle 句柄
   * @param need_kpts_result 是否需要返回关键点结果
   * @return Nail_SetInputShape
   */
  AILAB_EXPORT
  int Nail_PredictKpts(NailHandle handle,
                       bool need_kpts_result);
  /**
   * @param handle 句柄
   * @param max_length 设置最长边resize的长度，默认为224，
   */
  AILAB_EXPORT
  int Nail_SetMaxLength(NailHandle handle,
                        int max_length);
  
  /**
   * @brief 算法的主要调用接口
   *
   * @param handle 句柄
   * @param image 输入图像，最好是等比例resize，
   * @param pixel_format 输入图像的数据类型
   * @param image_width 输入图像的宽度
   * @param image_height 输入图像的高度
   * @param image_stride
   * @param orientation 方向
   * @param p_nail_res 返回的结果，
   * @return AILAB_EXPORT Nail_DoPredict
   */
  AILAB_EXPORT
  int Nail_DoPredict(NailHandle handle,
                     const unsigned char *image,
                     PixelFormatType pixel_format,
                     int image_width,
                     int image_height,
                     int image_stride,
                     ScreenOrient orientation,
                     NailInfo *p_nail_res);
  
  /**
   * @brief 内存申请
   *
   * @param handle
   * @return AILAB_EXPORT Nail_ReleaseHandle
   */
  AILAB_EXPORT
  NailInfo* Nail_MallocResultMemory(NailHandle handle);
  
  /**
   * @brief 销毁结果，释放资源
   *
   * @param NailInfo
   * @return AILAB_EXPORT Nail_FreeResultMemory
   */
  AILAB_EXPORT
  int Nail_FreeResultMemory(NailInfo *res);
  
  /**
   * @brief 销毁句柄，释放资源
   *
   * @param handle
   * @return AILAB_EXPORT Nail_ReleaseHandle
   */
  AILAB_EXPORT
  int Nail_ReleaseHandle(NailHandle handle);
  
  ////////////////////////////////////////////
  // 如果需要添加新接口，需要找工程组的同学 review 下
  ////////////////////////////////////////////
  
#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_NAILAPI_H_
