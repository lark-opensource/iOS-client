/**
 * @file AttrSDK_API.h
 * @author chenriwei (chenriwei@byteance.com)
 * @brief 人脸属性检测，依赖于人脸106关键点结果
 * @version 0.2
 * @date 2019-05-29
 *
 * @copyright Copyright (c) 2019
 *
 */
#ifndef __AttrSDK_API_h__
#define __AttrSDK_API_h__

#include "FaceSDK_API.h"
#if defined __cplusplus
extern "C" {
#endif

typedef void *AttrHandle;       ///<  人脸属性检测句柄

// clang-format off

/**
 * @brief 支持的人脸属性列表
 * @note 请按需调用
 *       目前 {AGE, GENDER} 由一个模型预测得到, {EXPRESSION, ATTRACTIVE, HAPPINESS}
 *       由另一个模型预测得到。为了降低时间消耗，使用时请有选择性的打开需要的类型.
 *       设置方式：FS_DoAttrPredict/FS_DoAttrPredictBatch 中的 config 参数。
 *
 */


typedef enum {
  AGE          = 0x00000001,     ///< 年龄
  GENDER       = 0x00000002,     ///< 性别
  EXPRESSION   = 0x00000004,     ///< 表情
  ATTRACTIVE   = 0x00000008,     ///< 颜值
  HAPPINESS    = 0x00000010,     ///< 开心程度
  FILTER       = 0x00000040,     ///< 人脸类型
  QUALITY      = 0x00000080,     ///< 质量
  EXP_DEGREE   = 0x00000100,     ///< 表情程度
  EXTRA        = 0x00000200,     ///< 额外的属性
  CONFUSED     = 0x00000400,     ///< 疑惑表情
} AttrTypes;


typedef enum {
  ForceDetect = 0x10000000,     ///< 未加平滑的裸数据，重置缓存，在切换摄像头时等上下帧剧烈变化时使用
                                ///< 用于处理切换摄像头，跟踪的人脸ID 混淆的问题
} AttrConfig;


/**
 * @brief 表情类别枚举
 *
 */
typedef enum {
  ANGRY = 0,                   ///< 生气
  DISGUST = 1,                 ///< 厌恶
  FEAR = 2,                    ///< 害怕
  HAPPY = 3,                   ///< 高兴
  SAD = 4,                     ///< 伤心
  SURPRISE = 5,                ///< 吃惊
  NEUTRAL = 6,                 ///< 平静
  NUM_EXPRESSION = 7           ///< 支持的表情个数
}ExpressionType;


/**
 * @breif 单个人脸属性结构体
 */
typedef struct AttrInfo {
  float age;                          ///< 预测的年龄值， 值范围【0，100】之间
  float boy_prob;                     ///< 预测为男性的概率值，值范围【0.0，1.0】之间
  float attractive;                   ///< 预测的颜值分数，范围【0，100】之间
  float happy_score;                  ///< 预测的微笑程度，范围【0，100】之间
  ExpressionType exp_type;            ///< 预测的表情类别
  float exp_probs[NUM_EXPRESSION];    ///< 预测的每个表情的概率，未加平滑处理
  float real_face_prob;               ///< 预测属于真人脸的概率，用于区分雕塑、漫画等非真实人脸
  float quality;                      ///< 预测人脸的质量分数，范围【0，100】之间
  float arousal;                      ///< 情绪的强烈程度
  float valence;                      ///< 情绪的正负情绪程度
  float sad_score;                    ///< 伤心程度
  float angry_score;                  ///< 生气程度
  float surprise_score;               ///< 吃惊的程度
  float mask_prob;                    ///< 预测带口罩的概率
  float wear_hat_prob;                ///< 戴帽子的概率
  float mustache_prob;                ///< 有胡子的概率
  float lipstick_prob;                ///< 涂口红的概率
  float wear_glass_prob;              ///< 带普通眼镜的概率
  float wear_sunglass_prob;           ///< 带墨镜的概率
  float blur_score;                   ///< 模糊程度
  float illumination;                 ///< 光照

} AttrInfo, *PtrAttrInfo;


typedef struct AttrInfo_tob {
  float age;                          ///< 预测的年龄值， 值范围【0，100】之间
  float boy_prob;                     ///< 预测为男性的概率值，值范围【0.0，1.0】之间
  float attractive;                   ///< 预测的颜值分数，范围【0，100】之间
  float happy_score;                  ///< 预测的微笑程度，范围【0，100】之间
  ExpressionType exp_type;            ///< 预测的表情类别
  float exp_probs[NUM_EXPRESSION];    ///< 预测的每个表情的概率，未加平滑处理
  float real_face_prob;               ///< 预测属于真人脸的概率，用于区分雕塑、漫画等非真实人脸
  float quality;                      ///< 预测人脸的质量分数，范围【0，100】之间
  float arousal;                      ///< 情绪的强烈程度
  float valence;                      ///< 情绪的正负情绪程度
  float sad_score;                    ///< 伤心程度
  float angry_score;                  ///< 生气程度
  float surprise_score;               ///< 吃惊的程度
  float mask_prob;                    ///< 预测带口罩的概率
  float wear_hat_prob;                ///< 戴帽子的概率
  float mustache_prob;                ///< 有胡子的概率
  float lipstick_prob;                ///< 涂口红的概率
  float wear_glass_prob;              ///< 带普通眼镜的概率
  float wear_sunglass_prob;           ///< 带墨镜的概率
  float blur_score;                   ///< 模糊程度
  float illumination;                 ///< 光照
  float confused_prob;

} AttrInfo_tob, *PtrAttrInfo_tob;



/**
 * @brief 多个人脸属性结构体
 * @param attr_info 属性数组
 * @param face_count 有效的人脸个数
 */
typedef struct AttrResult {
  AttrInfo attr_info[AI_MAX_FACE_NUM];    ///< 存放人脸属性结果数组
  int face_count;                         ///< 有效的人脸个数，即表示attr_info中的前face_count个人脸是有效的
} AttrResult, *PtrAttrResult;


//tob
typedef struct AttrResult_tob {
  AttrInfo_tob attr_info[AI_MAX_FACE_NUM];    ///< 存放人脸属性结果数组
  int face_count;                         ///< 有效的人脸个数，即表示attr_info中的前face_count个人脸是有效的
} AttrResult_tob, *PtrAttrResult_tob;

/**
 * @brief 人脸属性模型枚举
 *
 */
typedef enum AttrModelType {
  kQualityType = 1,                      ///< 质量和过滤的模型
  kAgeType = 2,                          ///<年龄和性别模型
  kExpType = 3,                          ///<表情颜值模型
  kConfusedType = 4,
}AttrModelType;

/**
 * @brief 创建handle句柄，仅创建handle，不加载模型，需配合FS_AttrLoadModel或FS_AttrLoadModelFromBuff使用，仅适合加载单个模型
 *
 * @param handle 句柄
 * @return status
 */
AILAB_EXPORT int FaceAttr_CreateHandle(void** handle);


AILAB_EXPORT int FS_AttrLoadModel(void* handle,
                                  AttrModelType type,
                                  const char* model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle  句柄
 * @param type 初始化的模型类型
 * @param mem_model 初始化的模型文件buf
 * @param model_size 模型大小
 * @return status
 */
AILAB_EXPORT int FS_AttrLoadModelFromBuff(void* handle,
                                          AttrModelType type,
                                          const char* mem_model,
                                          int model_size);



/**
 * tob专用
 * @brief 用于创建人脸属性句柄，仅可加载tt_face_attribute_vxx.model模型
 * @note 目前模型未拆分
 * @param:
 *       config 可选，目前无效，写 0 即可
 *       param_path 模型路径
 */
AILAB_EXPORT
int FS_CreateAttrHandler_tob(unsigned long long config,
                         const char *param_path,
                         AttrHandle *handle);

/**
 * tob专用
 * @brief 从buf初始化模型，仅可加载tt_face_attribute_vxx.model模型
 *
 * @param config
 * @param param_buf
 * @param param_buf_len
 * @param handle
 * @return AILAB_EXPORT FS_CreateAttrHandlerFromBuf
 */
AILAB_EXPORT
int FS_CreateAttrHandlerFromBuf_tob(unsigned long long config,
                                const char *param_buf,
                                unsigned int param_buf_len,
                                AttrHandle *handle);



/**
 * @brief 用于创建人脸属性句柄，仅可加载tt_face_attribute_vxx.model模型
 * @note 目前模型未拆分
 * @param:
 *       config 可选，目前无效，写 0 即可
 *       param_path 模型路径
 */
AILAB_EXPORT
int FS_CreateAttrHandler(unsigned long long config,
                         const char *param_path,
                         AttrHandle *handle);

/**
 * @brief 从buf初始化模型，仅可加载tt_face_attribute_vxx.model模型
 *
 * @param config
 * @param param_buf
 * @param param_buf_len
 * @param handle
 * @return AILAB_EXPORT FS_CreateAttrHandlerFromBuf
 */
AILAB_EXPORT
int FS_CreateAttrHandlerFromBuf(unsigned long long config,
                                const char *param_buf,
                                unsigned int param_buf_len,
                                AttrHandle *handle);

/**
 * @brief 基于单张人脸属性预测
 * @param handle 句柄
 * @param pixel_format 图像格式
 * @param image_width 图像宽度
 * @param image_height 图像高度
 * @param image_stride 图像每行的字节数
 * @param ptr_face_array 人脸检测的基本关键106点结构体
 * @param config 设置请求的属性，AttrTypes 枚举的与操作
 * @param ptr_attr_info 存放结果，需先分配好内存
 */
AILAB_EXPORT
int FS_DoAttrPredict(AttrHandle handle,
                     const unsigned char *image,
                     PixelFormatType pixel_format,
                     int image_width,
                     int image_height,
                     int image_stride,
                     const AIFaceInfoBase *ptr_face_array,
                     long long config,
                     AttrInfo *ptr_attr_info);


//tob
AILAB_EXPORT
int FS_DoAttrPredict_tob(AttrHandle handle,
                     const unsigned char *image,
                     PixelFormatType pixel_format,
                     int image_width,
                     int image_height,
                     int image_stride,
                     const AIFaceInfoBase *ptr_face_array,
                     long long config,
                     AttrInfo_tob *ptr_attr_info_tob);

/**
 * @brief: 基于多人脸属性预测
 * @param handle 句柄
 * @param pixel_format 图像格式
 * @param image_width 图像宽度
 * @param image_height 图像高度
 * @param image_stride 图像每行的字节数
 * @param ptr_face_array 人脸检测的基本关键106点结构体
 * @param face_count 指定ptr_face_array有多少有效人脸
 * @param config 设置请求的属性，AttrTypes 枚举的与操作
 * @param ptr_attr_result: 存放结果，需先分配好内存
 */
AILAB_EXPORT
int FS_DoAttrPredictBatch(AttrHandle handle,
                          const unsigned char *image,
                          PixelFormatType pixel_format,
                          int image_width,
                          int image_height,
                          int image_stride,
                          const AIFaceInfoBase *ptr_face_array,
                          int face_count,
                          long long config,
                          AttrResult *ptr_attr_result);


//tob
AILAB_EXPORT
int FS_DoAttrPredictBatch_tob(AttrHandle handle,
                          const unsigned char *image,
                          PixelFormatType pixel_format,
                          int image_width,
                          int image_height,
                          int image_stride,
                          const AIFaceInfoBase *ptr_face_array,
                          int face_count,
                          long long config,
                          AttrResult_tob *ptr_attr_result_tob);



/**
 * @brief 释放人脸属性句柄
 *
 * @param handle
 * @return AILAB_EXPORT FS_ReleaseAttrHandle
 */
AILAB_EXPORT
void FS_ReleaseAttrHandle(AttrHandle handle);

/**
 * @brief 人脸属性可配置的参数类别
 *
 */
typedef enum {
  ///< 身份相关的属性(性别、年龄、肤色)检测隔帧数，默认值为12;
  AttrIDRelatedDetectInterval = 1,
  ///< 非身份相关的属性(表情、颜值、微笑程度）检测隔帧数，默认值为1，即每帧都识别；
  ///< 保留字段，当前不可设；
  AttrDetectInterval = 2,
  ///< 当身份相关的属性识别置信度足够高时，停止计算该属性（结果在SDK中存储中正常返回，对外不感知）
  ///< 默认值为1，表示打开，设置为0,表示关闭；
  AttrIDRelatedAccumulateResult = 3,
} AttrParamConfigType;

/**
 * @brief 设置检测参数
 *
 * @param handle 句柄
 * @param type 要设置的配置类别
 * @param value 要设置的值
 * @return int
 */
AILAB_EXPORT
int FS_AttrSetParam(AttrHandle handle,
                    AttrParamConfigType type,
                    float value);

#if defined __cplusplus
};
#endif
// clang-format on
#endif /* AttrSDK_API_h */
