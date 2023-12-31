//
// Created by liuzhichao on 2018/1/11.
//

#ifndef EarSegmentationSDK_API_HPP
#define EarSegmentationSDK_API_HPP

#include "tt_common.h"
#include "FaceSDK_API.h"
typedef void* EarSegHandle;

#define ES_FACE_KEY_POINT_NUM 106
#define ES_EAR_KEY_POINT_NUM 5
#define ES_EAR_KEY_POINT_NUM_BK 13
#define ES_EAR_SEEDS_NUM 5 // (ES_EAR_KEY_POINT_NUM_BK - 1) % (ES_EAR_SEEDS_NUM - 1) == 0

//网络配置
typedef struct EarSegConfig {
  int net_input_width;  //网络输入的宽
  int net_input_height; //网络输入的高
} EarSegConfig;

//单只耳朵结果
typedef struct EarSegEarResult {
  unsigned char* alpha; //小图alpha
  double matrix[6];     //仿射变换矩阵
  AIPoint points[ES_EAR_KEY_POINT_NUM]; //耳朵关键点
  int cls;              //二分类：0 大遮挡，1 小遮挡
  float cls_prob;       //耳朵露出的概率
  float center_x;       //耳朵接脸边缘中点x坐标
  float center_y;       //耳朵接脸边缘中点y坐标
  int ear_height;       //耳朵高
  int ear_width;        //耳朵宽
} EarSegEarResult;

//单个人脸结果
typedef struct EarSegFaceResult {
  int face_id;  //人脸id
  int width;    //小图宽
  int height;   //小图高
  int channel;  //原图通道数
  float yaw;    //人脸yaw角度
  EarSegEarResult ear_result[2];  //两只耳朵结果
} EarSegFaceResult;

//输入信息
typedef struct EarSegInput {
  unsigned char* image; //原图地址
  int image_width;  //原图宽
  int image_height; //原图高
  int image_stride; //原图stride
  PixelFormatType
      pixel_format;  // kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
  ScreenOrient orient;  //原图方向
  AIFaceInfoBase* face_info;  //所有人脸信息
  int face_count; //人脸数
} EarSegInput;

//输出结果
typedef struct EarSegOutput {
  EarSegFaceResult* face_result; //所有人脸结果
  int face_count; //人脸数
  int max_face;   //最大可检测人脸数
} EarSegOutput;

//模型类型
typedef enum EarSegModelType {
  EARSEG_SEG_MODEL = 1, //耳朵分割模型
  EARSEG_KP_MODEL = 2,  //耳朵关键点模型
} EarSegModelType;

//模块参数
typedef enum EarSegParamType {
  ES_ENABLE_TRACKING = 1, //平滑开关，默认为true用于防抖
  ES_MAX_FACE = 2,        //最大可检测人脸数，默认为5
  ES_YAW_THRES_FACE = 3,  //人脸yaw绝对值大于此阈值才检测耳朵，推荐值为0（全触发，默认值）或5（侧脸触发）
  ES_YAW_THRES_SIDE = 4,  //人脸yaw侧脸阈值，侧脸超过阈值时只检测一个耳朵，默认为15
  ES_ITER_EROSION = 5,    //腐蚀膨胀的迭代次数，用于去黑边，默认为2
  ES_ESCALE = 6,          //关键点平滑度，一般在1.5~10之间，默认为1.5
} EarSegParamType;

/**
 创建句柄

 @param out 创建的句柄
 @return 无效handle返回SMASH_E_INVALID_HANDLE，否则返回SMASH_OK
 */
AILAB_EXPORT
int ESeg_CreateHandler(EarSegHandle* out);

/**
 设置网络输入参数

 @param handle EarSegHandle句柄
 @param config EarSegConfig，config.net_input_width和config.net_input_height为网络输入的宽和高
 @return SMASH_E_INVALID_HANDLE，或SMASH_E_INVALID_CONFIG，或SMASH_OK
 */
AILAB_EXPORT
int ESeg_SetConfig(EarSegHandle handle, EarSegConfig* config);

/**
 设置模块参数

 @param handle EarSegHandle句柄
 @param type EarSegParamType
 @param value 设置type类型参数的值
   ES_ENABLE_TRACKING，开启防抖：1，关闭：0，默认为1
   ES_MAX_FACE，最大可检测人脸数，1到5之间，默认为5
   ES_YAW_THRES_FACE，人脸yaw绝对值大于此阈值才检测耳朵，0到90之间，推荐值为0（全触发，默认值）或5（侧脸触发）
   ES_YAW_THRES_SIDE，人脸yaw侧脸阈值，侧脸超过阈值时只检测一个耳朵，0到90之间，默认为15
   ES_ITER_EROSION，腐蚀膨胀的迭代次数，用于去黑边，0到3之间，推荐值为2或3，默认为2
 @return SMASH_E_INVALID_HANDLE，或SMASH_E_INVALID_PARAM，或SMASH_OK
 */
AILAB_EXPORT
int ESeg_SetParam(EarSegHandle handle, EarSegParamType type, float value);

/**
 初始化模型，在ESeg_SetConfig设置了网络输入参数，ESeg_SetParam设置了最大人脸数后调用
 
 @param handle EarSegHandle句柄
 @param param 模型数据buffer
 @param param_len 模型数据buffer长度
 @param image_width 原图宽
 @param image_height 原图高
 @return 模型初始化失败返回SMASH_E_INVALID_MODEL，否则返回SMASH_OK
 */
AILAB_EXPORT
int ESeg_SetModelFromBuff(EarSegHandle handle,
                          const unsigned char* param,
                          unsigned int param_len,
                          int image_width,
                          int image_height,
                          int model_type);

/**
 初始化模型，在ESeg_SetConfig设置了网络输入参数，ESeg_SetParam设置了最大人脸数后调用

 @param handle EarSegHandle句柄
 @param param_path 模型路径
 @param image_width 原图宽
 @param image_height 原图高
 @return SMASH_E_INVALID_HANDLE，或SMASH_E_INVALID_MODEL，或SMASH_OK
 */
AILAB_EXPORT
int ESeg_InitModel(EarSegHandle handle,
                   const char* param_path,
                   int image_width,
                   int image_height,
                   int model_type);

/**
 耳朵分割入口

 @param handle EarSegHandle句柄
 @param input 输入数据
 @param output 输出结果
 @return SMASH_E_INVALID_HANDLE，或SMASH_E_INVALID_PIXEL_FORMAT，或SMASH_E_INVALID_MODEL，或SMASH_OK
 */
AILAB_EXPORT
int ESeg_DoEarSeg(EarSegHandle handle,
                  EarSegInput* input,
                  EarSegOutput* output);


/**
 按照最大人脸数申请内存，在ESeg_SetParam设置了最大人脸数、且初始化模型后才能调用

 @param handle EarSegHandle句柄
 @return 存结果的EarSegOutput指针
 */
AILAB_EXPORT
EarSegOutput* ESeg_MallocResultMemory(EarSegHandle handle);

/**
 释放申请的内存

 @param earseg_out 调用ESeg_MallocResultMemory得到的EarSegOutput指针
 @return SMASH_OK
 */
AILAB_EXPORT
int ESeg_FreeResultMemory(EarSegOutput* earseg_out);

/**
 释放EarSegHandle句柄

 @param handle ESeg_CreateHandler创建的句柄
 @return 无效handle返回SMASH_E_INVALID_HANDLE，否则返回SMASH_OK
 */
AILAB_EXPORT
int ESeg_ReleaseHandle(EarSegHandle handle);

#endif  // EarSegmentationSDK_API_HPP
