//
// Created by liuzhichao on 2018/1/11.
//

#ifndef FaceGanSDK_API_HPP
#define FaceGanSDK_API_HPP

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

// **** *** *** tt_facegan_class_v2.0.model 包含功能有 生成功能：单眼皮变双眼皮，增加卧蝉，分类功能：双眼皮的程度， 卧蝉的程度。 可以使用以下标志**** *** ***//
// **** *** *** tt_facegan_class_v3.0.model 包含功能有 生成功能：单眼皮变双眼皮，双眼皮变单眼皮，分类功能：双眼皮的程度， 卧蝉的程度。 可以使用以下标志**** *** ***//
#define TT_GAN_LEFT_DOUBLE  0x00000001          // 打开 左双眼皮生成
#define TT_GAN_RIGHT_DOUBLE  0x00000002         // 打开 右双眼皮生成
#define TT_GAN_LEFT_PLUMP  0x00000004           // 打开 左卧蚕生成
#define TT_GAN_RIGHT_PLUMP  0x00000008          // 打开 右卧蚕生成
#define TT_GAN_LEFT_CLASS  0x00000010           // 打开 左双眼皮/卧蚕类别计算
#define TT_GAN_RIGHT_CLASS  0x00000020          // 打开 右双眼皮/卧蚕类别计算
#define TT_GAN_LEFT_DOUBLE_TO_SINGLE 0x00000040      // 双眼皮变成单眼皮
#define TT_GAN_RIGHT_DOUBLE_TO_SINGLE 0x00000080      // 双眼皮变成单眼皮

#define TT_GAN_DOUBLE (TT_GAN_LEFT_DOUBLE|TT_GAN_RIGHT_DOUBLE)  // 打开 两眼双眼皮生成
#define TT_GAN_PLUMP (TT_GAN_LEFT_PLUMP|TT_GAN_RIGHT_PLUMP)     // 打开 两眼卧蚕生成
#define TT_GAN_CLASS (TT_GAN_LEFT_CLASS|TT_GAN_RIGHT_CLASS)     // 打开 两眼双眼皮/卧蚕类别计算
#define TT_GAN_DOUBLE_TO_SINGLE (TT_GAN_LEFT_DOUBLE_TO_SINGLE | TT_GAN_RIGHT_DOUBLE_TO_SINGLE)
#define TT_GAN_ALL (TT_GAN_DOUBLE|TT_GAN_PLUMP|TT_GAN_CLASS|TT_GAN_DOUBLE_TO_SINGLE)    // 全部打开(包括类别计算)

#define TT_GAN_MAX_FACE_LIMIT   (10)   // 最大支持人脸数
#define TT_GAN_MAX_FACE_DEFAULT (2)  // 默认最大支持人脸数, 对于AI双眼皮项目，PM给出的值

typedef void *FaceGanHandle;

//FaceGanObjectResult中生成数据的类型，可以是只生成双眼皮，卧蚕，分类值，也可以是组合
typedef enum FaceGanObjectType {
    UNDEFINED = 0,
    LEFT_DOUBLE = 1,
    LEFT_PLUMP = 2,
    LEFT_DOUBLE_PLUMP = 3,
    RIGHT_DOUBLE = 4,
    RIGHT_PLUMP = 5,
    RIGHT_DOUBLE_PLUMP = 6,
    LEFT_CLASS_ONLY = 7,
    RIGHT_CLASS_ONLY = 8,
    LEFT_DOUBLE_TO_SINGLE=9,
    RIGHT_DOUBLE_TO_SINGLE=10
} FaceGanObjectType;

typedef struct FaceGanObjectResult {
    int faceID;
    unsigned char * data;   // 单眼双眼皮生成结果
    float doubleRate;       // 单眼为双眼皮的概率 (0.0 - 1.0, 未执行时为0.0)
    float plumpRate;        // 单眼为双眼皮的概率 (0.0 - 1.0, 未执行时为0.0)

    FaceGanObjectType objectType;
    int outWidth;
    int outHeight;
    int outChannel;
    float matrix[6];

    AIRect rect;            // rect in 128*128
} FaceGanObjectResult;


typedef struct FaceGanResult {      // 数组中分别为 face1_left, face1_right, face2_left, face2_right, ...
    FaceGanObjectResult eye_result[TT_GAN_MAX_FACE_LIMIT * 2];
    int eye_count;
} FaceGanResult;


//输入参数 pack
typedef struct FaceGanInputArgs {
    int face_count;
    int id[TT_GAN_MAX_FACE_LIMIT];
    float *landmark106[TT_GAN_MAX_FACE_LIMIT];
    int view_width;
    int view_height;

    //image
    unsigned char *image;
    int image_width;
    int image_height;
    int image_stride;
    PixelFormatType image_format;
} FaceGanInputArgs;

#define DEFAULT_USE_TRACKING (true)
#define DEFAULT_DOUBLE_ALPHA (1.0f)
#define DEFAULT_PLUMP_ALPHA (1.0f)
#define DEFAULT_CLASS_INTERVAL_FRAME (12)
#define DEFAULT_CLASS_MAX_FRAME (100000000)
#define DEFAULT_CLASS_FIRST_FRAME (4)
    
typedef enum GanParamType {
    USE_TRACKING = 0,           // 是否执行跟踪
    DOUBLE_ALPHA = 1,           // 双眼皮输出混合程度
    PLUMP_ALPHA = 2,            // 卧蚕输出混合程度
    CLASS_INTERVAL_FRAME = 3,   // 每几帧执行一次分类模型
    CLASS_MAX_FRAME = 4,        // 每个人脸最多执行几次分类模型后, 将不再执行
    CLASS_FIRST_FRAME = 5,      // 第几帧开始执行第一次分类模型
} GanParamType;

/**
 * @param handle        FaceGanHandle
 * @return              succeed 0, others failed;
 */
AILAB_EXPORT
int Gan_CreateHandler(FaceGanHandle *handle);

/**
 *  模型初始化
 * @param handle        FaceGanHandle
 * @param model_path    模型的绝对路径
 * @param detect_config 使用哪些模型， Gan_DoFaceGan中的detect_config 应该小于 该detect_config
 * @param max_face      使用的最大个数，应该小于等于TT_GAN_MAX_FACE_LIMIT
 * @return              success 0, others failed;
 */
AILAB_EXPORT
int Gan_InitModel(FaceGanHandle handle, const char *model_path, unsigned long detect_config, int max_face);

AILAB_EXPORT
int Gan_InitModelFromBuf(FaceGanHandle handle, const char *model_buf, unsigned int len, unsigned long detect_config, int max_face);

/**
 *  用来设置GanParamType中的参数数据
 * @param handle        FaceGanHandle
 * @param type          参数类型
 * @param value         参数的值
 * @return              success 0, others failed;
 */
int Gan_SetParam(FaceGanHandle handle, GanParamType type, float value);


/**
 *  运行模型
 * @param handle            FaceGanHandle
 * @param args              input 包括关键点信息  与  图像信息
 * @param detect_config     运行哪些模型  参考TT_**的宏定义
 * @param result            返回结果，查看FaceGanResult的具体定义
 * @return                  success 0, others failed;
 */
AILAB_EXPORT
int Gan_DoFaceGan(FaceGanHandle handle, const FaceGanInputArgs *args, unsigned long detect_config, FaceGanResult *result);


/**
 * 释放模型，必须调用的
 * @param handle
 * @return      success 0, others failed;
 */
AILAB_EXPORT
int Gan_ReleaseHandle(FaceGanHandle handle);


#if defined __cplusplus
};
#endif

#endif //FaceGanSDK_API_HPP
