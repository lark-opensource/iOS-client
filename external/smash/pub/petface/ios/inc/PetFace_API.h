/**
 * @file PetFace_API.h
 * @author chenriwei (chenriwei@bytedance.com)
 * @brief 宠物脸检测，目前包含了猫脸82点，狗脸76点，以及动作检测
 * @version 0.1
 * @date 2019-05-29
 *
 * @copyright Copyright (c) 2019
 *
 */
#ifndef __PETFACE_API__
#define __PETFACE_API__
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif
// prefix: PF -> PetFace
// clang-format off
#define AI_PET_MAX_POINT_NUM 90                     ///< 宠物脸的关键点的最大点数
#define AI_CAT_POINT_NUM 82                         ///< 猫：82点
#define AI_DOG_POINT_NUM 76                         ///< 狗：76点（不加耳朵）
#define AI_OTHER_POINT_NUM 4                        ///< 其它动物：4点(目前不支持)
#define AI_MAX_PET_NUM 10

#define AI_PET_OPEN_LEFT_EYE          0x00000001    ///< 左眼睛是否睁开
#define AI_PET_OPEN_RIGHT_EYE         0x00000002    ///< 左眼睛是否睁开
#define AI_PET_OPEN_MOUTH             0x00000004    ///< 嘴巴是否张开

typedef void *PetFaceHandle;                        ///< 关键点检测句柄
/**
 * @brief 支持的宠物类别
 *
 */
typedef enum {
    CAT                 =                       1,   ///< 猫
    DOG                 =                       2,   ///< 狗
    HUMAN               =                       3,   ///< 人（目前不支持）
    OTHERS              =                      99,   ///< 其它宠物类型（目前不支持）
}PetTypes;

/**
 * @brief 检测的可选参数
 *
 */
typedef enum {
    DetCat              =             0x00000001,    ///< 开启猫脸检测
    DetDog              =             0x00000002,    ///< 开启狗脸检测
    QuickMode           =             0x00000004,    ///< 开启快速版本
    SingleFrameMode     =             0x00000008,    ///< 开启单张图片模式
}PetConfigTypes;

/**
 * @brief 存储单个宠物脸结果
 *
 */
typedef struct PetInfo {
    PetTypes type;                                   ///< 宠物类型
    AIRect rect;                                     ///< 代表面部的矩形区域
    float score;                                     ///< 宠物脸检测的置信度
    AIPoint points_array[AI_PET_MAX_POINT_NUM];      ///< 宠物脸关键点的数组
    float yaw;                                       ///< 水平转角,真实度量的左负右正
    float pitch;                                     ///< 俯仰角,真实度量的上负下正
    float roll;                                      ///< 旋转角,真实度量的左负右正
    int id;                                          ///< faceID: 每个检测到的宠物脸拥有唯一id，跟踪丢失以后重新被检测到,会有一个新的id
    unsigned int action;                             ///< 脸部动作，目前只包括：左眼睛睁闭，右眼睛睁闭，嘴巴睁闭, action 的第1，2，3位分别编码： 左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，其余位数预留
    int ear_type;                                    ///< 判断是竖耳还是垂耳，竖耳为0，垂耳为1
} PetInfo, *ptr_PetInfo;


/**
 * @brief 存储检测结果
 *
 */
typedef struct PetResult {
    PetInfo p_faces[AI_MAX_PET_NUM];                 ///< 检测到的宠物脸信息
    int face_count;                                  ///< 检测到的宠物脸数目，p_faces 数组中，只有face_count个结果是有效的；
} PetResult, *ptr_PetResult;


/**
 * @brief 创建宠物脸检测句柄, 与PF_CreateHandlerFromBuf 初始化方法二选一
 * @param 模型文件的路径, 如 models/petface_v2.model
 * @param max_face_num：指定最多能够检测到的猫脸数目；
 * @param detect_config 检测配置, 可以配置只检测猫，只检测狗，或者同时检测猫狗
 *                      例如：只检测狗 detect_config = PetConfigTypes::DetDog
 *                      同时检测猫狗： 只检测狗 detect_config = PetConfigTypes::DetDog|PetConfigTypes::DetCat
 * @param handle 返回的宠物脸句柄
 */
AILAB_EXPORT
int PF_CreateHandler(const char* model_path,
                     unsigned int max_face_num,
                     long long detect_config,
                     PetFaceHandle *handle);


/**
 * @brief 创建宠物脸检测句柄，与PF_CreateHandler 初始化方法二选一
 * @param 模型文件的路径, 如 models/petface_v2.model
 * @param max_face_num：指定最多能够检测到的猫脸数目；
 * @param detect_config 检测配置
 * @param 返回的宠物脸句柄
 */
AILAB_EXPORT
int PF_CreateHandlerFromBuf(const char* model_buf,
                            unsigned int buf_len,
                            unsigned int max_face_num,
                            long long detect_config,
                            PetFaceHandle *handle);



/**
 * @brief 宠物脸检测跟踪，结果存放在p_pet_result 中
 * @param handle 检测句柄
 * @param image 图片指针
 * @param pixel_format 图片像素格式
 * @param image_width 图片宽度
 * @param image_height 图片高度
 * @param image_stride 图片每行的字节数目
 * @param orientation 图片旋转方向
 * @param p_pet_result 检测结果返回，需要分配好内存；
 */
AILAB_EXPORT
int PF_DoPredict(
                PetFaceHandle handle,
                const unsigned char *image,
                PixelFormatType pixel_format,
                int image_width,
                int image_height,
                int image_stride,
                ScreenOrient orientation,
                PetResult *p_pet_result
                );


/**
 * @brief 宠物脸检测，结果存放在p_pet_result 中, 只检测框，不检测关键点；
 * @param handle 检测句柄
 * @param image 图片指针
 * @param pixel_format 图片像素格式
 * @param image_width 图片宽度
 * @param image_height 图片高度
 * @param image_stride 图片每行的字节数目
 * @param orientation 图片旋转方向
 * @param p_pet_result 检测结果返回，需要分配好内存；
 * @note 不对外release，只做检测器测试使用
 */
AILAB_EXPORT
int PF_DoDetect(
                 PetFaceHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 PetResult *p_pet_result
                 );
/**
 * @brief: 释放资源
 * @param: handle 检测句柄
 */
AILAB_EXPORT
int PF_ReleaseHandle(PetFaceHandle handle);

typedef enum PetFaceParamType {
  PET_FACE_IMAGE_OR_VIDEO_MODE = 0,  //选择图片或视频模式，int，1 为图片模式，0 为视频模式
} PetFaceParamType;

/*
 *@brief: 设置使用图片模式或视频模式
 @param: handle 句柄
 @param: type 参数类型
 @param: value 参数值
 */
AILAB_EXPORT
int PF_SetParam(PetFaceHandle handle, PetFaceParamType type, int value);


#if defined __cplusplus
};
#endif

// clang-format on
#endif
