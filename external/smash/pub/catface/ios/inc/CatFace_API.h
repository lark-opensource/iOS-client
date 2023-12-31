/**
 * @file CatFace_API.h
 * @author chenriwei (chenriwei@bytedance.com)
 * @brief 猫脸关键点检测，支持定义的82个关键点
 * @note 新业务接入建议直接用petface 模块，完整包含了catface，增加了狗脸检测
 * @deprecated 这个模块后面不在更新，建议已使用的模块迁移到petface模块
 * @version 0.1
 * @date 2019-05-29
 *
 * @copyright Copyright (c) 2019
 *
 */
#ifndef __CATFACEAPI__
#define __CATFACEAPI__
#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

// clang-format off
// prefix: CF -> CatFace
#define AI_CAT_POINT_NUM 82
#define AI_MAX_CAT_NUM   10

#define AI_CAT_OPEN_LEFT_EYE  0x00000001   ///<  左眼睛是否睁开
#define AI_CAT_OPEN_RIGHT_EYE 0x00000002   ///<  左眼睛是否睁开
#define AI_CAT_OPEN_MOUTH     0x00000004   ///<  嘴巴是否张开

typedef void *CatFaceHandle;               ///< 关键点检测句柄

/**
 * @brief 存储猫脸信息
 *
 */
typedef struct CatInfo {
  AIRect rect;                             ///< 代表面部的矩形区域
  float score;                             ///< 猫脸检测的置信度
  AIPoint points_array[AI_CAT_POINT_NUM];  ///< 人脸82关键点的数组
  float yaw;                               ///< 水平转角,真实度量的左负右正
  float pitch;                             ///< 俯仰角,真实度量的上负下正
  float roll;                              ///< 旋转角,真实度量的左负右正
  int id;                                  ///< face id 每个检测到的人脸拥有唯一的id.人脸跟踪丢失以后重新被检测到,会有一个新的id
  unsigned int action;                     ///< 脸部动作，目前只包括：左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，
                                           ///< action 的第1，2，3位分别编码：
                                           ///< 左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，其余位数预留
} CatInfo, *ptr_CatInfo;


/**
 * @brief 存储猫脸检测的结果数据
 *
 */
typedef struct CatResult {
  CatInfo p_faces[AI_MAX_CAT_NUM];         ///< 检测到的人脸信息
  int face_count;                          ///< 检测到的人脸数目，p_faces数组中，只有face_count个结果是有效的；
} CatResult, *ptr_CatResult;

/**
 * @brief 创建猫脸检测句柄
 * @param: 模型文件的路径, 如 models/catface_v1.model
 * @param: max_face_num：指定最多能够检测到的猫脸数目；
 * @param: 返回的人脸句柄
 * @return 0 表示成功, 其它表示识别
 */
AILAB_EXPORT
int CF_CreateHandler(const char *model_path,
                     unsigned int max_face_num,
                     CatFaceHandle *handle);

/**
 * @brief 从模型文件初始化检测句柄
 *
 * @param model_buf 模型文件的buf数据
 * @param model_buf_len 指示buf 长度
 * @param max_face_num 制定需要检测的最多的脸的个数
 * @param handle 初始化后的句柄
 * @return 0 表示成功，其它表示失败
 */
AILAB_EXPORT
int CF_CreateHandlerFromBuf(const char *model_buf,
                            unsigned int model_buf_len,
                            unsigned int max_face_num,
                            CatFaceHandle *handle);

/**
 * @brief: 猫脸检测，结果存放在p_cat_result 中
 * @param: handle 检测句柄
 * @param: image 图片指针
 * @param: pixel_format 图片像素格式
 * @param: image_width 图片宽度
 * @param: image_height 图片高度
 * @param: image_stride 图片每行的字节数目
 * @param: orientation 图片旋转方向
 * @param: p_cat_result 检测结果返回，需要分配好内存；
 */
AILAB_EXPORT
int CF_DoPredict(CatFaceHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 CatResult *p_cat_result);

/**
 * @brief: 释放资源
 * @param: handle 检测句柄
 */
AILAB_EXPORT
int CF_ReleaseHandle(CatFaceHandle handle);

#if defined __cplusplus
};
#endif

// clang-format on
#endif
