#ifndef _FACESDK_API_H_
#define _FACESDK_API_H_

#include "smash_runtime_info.h"
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

// prefix: FS -> FaceSDK

//***************************** begin Create-Config *****************/
// Config when creating handle
#define TT_INIT_LARGE_MODEL 0x00100000 // 106模型初始化参数，更准, 现已废弃
#define TT_INIT_SMALL_MODEL 0x00200000 // 106模型初始化参数，更快
#define TT_MOBILE_FACE_240_DETECT_FASTMODE 0x00300000 // 240模型初始化参数，更快
//**************************** end of Create-Config *****************/

//***************************** begin Mode-Config ******************/
#define TT_MOBILE_DETECT_MODE_VIDEO 0x00020000 // 视频检测，初始化+预测参数
#define TT_MOBILE_DETECT_MODE_IMAGE 0x00040000 // 图片检测，初始化+预测参数
#define TT_MOBILE_DETECT_MODE_IMAGE_SLOW                                       \
    0x00080000 // 图片检测，人脸检测模型效果更好，能检测更小的人脸，初始化+预测参数
//***************************** enf of Mode-Config *****************/

//***************************** Begin Config-106 point and action **/
// for 106 key points detect
// NOTE 当前版本 张嘴、摇头、点头、挑眉默认都开启，设置相关的位不生效
#define TT_MOBILE_FACE_DETECT 0x00000001 // 检测106点
// 人脸动作
#define TT_MOBILE_EYE_BLINK 0x00000002  // 眨眼
#define TT_MOBILE_MOUTH_AH 0x00000004   // 张嘴
#define TT_MOBILE_HEAD_YAW 0x00000008   // 摇头
#define TT_MOBILE_HEAD_PITCH 0x00000010 // 点头
#define TT_MOBILE_BROW_JUMP 0x00000020  // 挑眉
#define TT_MOBILE_MOUTH_POUT 0x00000040 // 嘟嘴

#define TT_MOBILE_DETECT_FULL 0x0000007F // 检测上面所有的特征，初始化+预测参数

#define TT_MOBILE_EYE_BLINK_LEFT                                               \
    0x00000080 // 左眼眨眼，只用于提取对应的action，动作检测依然是眨眼
#define TT_MOBILE_EYE_BLINK_RIGHT                                              \
    0x00000100 // 右眼眨眼，只用于提取对应的action，动作检测依然是眨眼
#define TT_MOBILE_SIDE_NOD                                                     \
    0x00000200 // 摇头2，左右摇摆摇头，只用于提取对应的action，动作检测依然是摇头

//**************************** End Config-106 point and action *******/

//******************************* Begin Config-280 point *************/
// for 280 points
// NOTE: 现在改了二级策略，眉毛、眼睛、嘴巴关键点会在一个模型中出
#define TT_MOBILE_FACE_240_DETECT                                              \
    0x00000100 // 检测二级关键点: 眉毛, 眼睛, 嘴巴，初始化+预测参数
#define AI_BROW_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT  // 眉毛 13*2个点
#define AI_EYE_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT   // 眼睛 22*2个点
#define AI_MOUTH_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT // 嘴巴 64个点
#define AI_MOUTH_MASK_DETECT 0x00000300                 // 嘴巴 mask
#define AI_FACE_MASK_DETECT 0x00000500                  // 人脸 mask
#define AI_IRIS_EXTRA_DETECT 0x00000800                 // 虹膜 20*2个点

#define TT_MOBILE_FACE_280_DETECT                                              \
    0x00000900 // 检测二级关键点: 眉毛, 眼睛, 嘴巴，虹膜，初始化+预测参数
//******************************* End Config-280 point ***************/

#define TT_MOBILE_FORCE_DETECT 0x00001000 // 强制这帧人脸检测，并显示结果

#define AI_MAX_FACE_NUM 10

typedef void *FaceHandle; // 关键点检测句柄

typedef struct AIFaceInfoBase {
    AIRect rect;               // 代表面部的矩形区域
    float score;               // 置信度
    AIPoint points_array[106]; // 人脸106关键点的数组
    float visible_array[106]; // 未实现，对应点的能见度,点未被遮挡1.0,被遮挡0.0
    float yaw;      // 水平转角,真实度量的左负右正
    float pitch;    // 俯仰角,真实度量的上负下正
    float roll;     // 旋转角,真实度量的左负右正
    float eye_dist; // 两眼间距
    int id;         // faceID:
            // 每个检测到的人脸拥有唯一的faceID.人脸跟踪丢失以后重新被检测到,会有一个新的faceID
    unsigned int action; // 动作信息，在对应的bit上存放对应的动作信息, 1
                         // 表示动作发生，0表示不发生
    unsigned int
        tracking_cnt; // 脸跟踪的帧数，用于判断是否是新出现的人脸，以及新人脸触发动作等；
} AIFaceInfoBase, *PtrAIFaceInfoBase;

// 眼睛,眉毛,嘴唇,虹膜关键点详细检测结果
typedef struct AIFaceInfoExtra {
    int eye_count;             // 检测到眼睛数量
    int eyebrow_count;         // 检测到眉毛数量
    int lips_count;            // 检测到嘴唇数量
    int iris_count;            // 检测到虹膜数量
    AIPoint eye_left[22];      // 左眼关键点
    AIPoint eye_right[22];     // 右眼关键点
    AIPoint eyebrow_left[13];  // 左眉毛关键点
    AIPoint eyebrow_right[13]; // 右眉毛关键点
    AIPoint lips[64];          // 嘴唇关键点
    AIPoint left_iris[20];     // 左虹膜关键点
    AIPoint right_iris[20];    // 右虹膜关键点
} AIFaceInfoExtra, *PtrAIFaceInfoExtra;

// 检测结果
typedef struct AIFaceInfo {
    AIFaceInfoBase base_infos
        [AI_MAX_FACE_NUM]; // 检测到的基本的人脸信息，包含106点、动作、姿态
    AIFaceInfoExtra extra_infos
        [AI_MAX_FACE_NUM]; // 眼睛，眉毛，嘴唇、虹膜关键点等额外的信息
    int face_count; // 检测到的人脸数目
} AIFaceInfo, *PtrAIFaceInfo;

// Mouth Mask
typedef struct AIMouthMaskInfoBase {
    int face_mask_size;       // face_mask_size
    unsigned char *face_mask; // face_mask
    float *warp_mat;          // warp mat data ptr, size 2*3
    int id;
} AIMouthMaskInfoBase, *PtrAIMouthMaskInfoBase;

typedef struct AIMouthMaskInfo {
    AIMouthMaskInfoBase base_mouth_infos[AI_MAX_FACE_NUM];
    int face_count;
} AIMouthMaskInfo, *PtrAIMouthMaskInfo;

// Teen Mask
typedef struct AITeenMaskInfoBase {
    int face_mask_size;       // face_mask_size
    unsigned char *face_mask; // face_mask
    float *warp_mat;          // warp mat data ptr, size 2*3
    int id;
} AITeenMaskInfoBase, *PtrAITeenMaskInfoBase;

// Teen Mask
typedef struct AIFaceOcclusionInfoBase {
    float prob;
    int id;
} AIFaceOcclusionInfoBase, *PtrAIFaceOcclusionInfoBase;

typedef struct AITeenMaskInfo {
    AITeenMaskInfoBase base_teen_info[AI_MAX_FACE_NUM];
    int face_count;
} AITeenMaskInfo, *PtrAITeenMaskInfo;

// Teen Mask
typedef struct AIFaceMaskInfoBase {
    int face_mask_size;       // face_mask_size
    unsigned char *face_mask; // face_mask
    float *warp_mat;          // warp mat data ptr, size 2*3
    int id;
} AIFaceMaskInfoBase, *PtrAIFaceMaskInfoBase;

typedef struct AIFaceMaskInfo {
    AIFaceMaskInfoBase base_face_info[AI_MAX_FACE_NUM];
    int face_count;
} AIFaceMaskInfo, *PtrAIFaceMaskInfo;

typedef struct AIFaceOcclusionInfo {
    AIFaceOcclusionInfoBase base_occ_info[AI_MAX_FACE_NUM];
    int face_count;
} AIFaceOcclusionInfo, *PtrAIFaceOcclusionInfo;

/*
 *@brief 初始化handle
 *@param [in] config 指定一级模型的模型参数，如 TT_INIT_SMALL_MODEL |
 *TT_MOBILE_DETECT_FULL， 图像模式：TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL
 *| TT_MOBILE_DETECT_MODE_IMAGE or 更好的图像模式：TT_INIT_SMALL_MODEL |
 *TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE_SLOW
 *@param [in] param_path 一级模型的文件路径
 */
AILAB_EXPORT
int FS_CreateHandler(unsigned long long config, const char *param_path,
                     FaceHandle *handle);
/*
 *@param [in] config 指定一级模型的模型参数，如 TT_INIT_SMALL_MODEL |
 *TT_MOBILE_DETECT_FULL， 图像模式：TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL
 *| TT_MOBILE_DETECT_MODE_IMAGE or 更好的图像模式：TT_INIT_SMALL_MODEL |
 *TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE_SLOW
 *@param Create Handler from buff
 **/
AILAB_EXPORT
int FS_CreateHandlerFromBuf(unsigned long long config, const char *param_buf,
                            unsigned int param_buf_len, FaceHandle *handle);

/*
 *@brief 初始化handle
 *@param [in] config 指定240模型的模型参数，创建240或者280
 *Config-240，TT_MOBILE_FACE_240_DETECT
 *Config-280，TT_MOBILE_FACE_280_DETECT
 *Config-240 快速模式, TT_MOBILE_FACE_240_DETECT |
 *TT_MOBILE_FACE_240_DETECT_FASTMODE Config-280 快速模式,
 *TT_MOBILE_FACE_280_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 *@param [in] param_path 240/280模型的文件路径
 */
AILAB_EXPORT
int FS_AddExtraModel(
    FaceHandle handle,
    unsigned long long config, // 配置config，创建240或者280
                               // Config-240，TT_MOBILE_FACE_240_DETECT
                               // Config-280，TT_MOBILE_FACE_280_DETECT
                               // Config-240 快速模式, TT_MOBILE_FACE_240_DETECT
                               // | TT_MOBILE_FACE_240_DETECT_FASTMODE
                               // Config-280 快速模式, TT_MOBILE_FACE_280_DETECT
                               // | TT_MOBILE_FACE_240_DETECT_FASTMODE
    const char *param_path);

/*
 *@brief 初始化handle
 *@param [in] config 指定240模型的模型参数，创建240或者280
 *Config-240，TT_MOBILE_FACE_240_DETECT
 *Config-280，TT_MOBILE_FACE_280_DETECT
 *Config-240 快速模式, TT_MOBILE_FACE_240_DETECT |
 *TT_MOBILE_FACE_240_DETECT_FASTMODE Config-280 快速模式,
 *TT_MOBILE_FACE_280_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 *@param Create Handler from buff
 */
AILAB_EXPORT
int FS_AddExtraModelFromBuf(FaceHandle handle, unsigned long long config,
                            const char *param_buf, unsigned int param_buf_len);

AILAB_EXPORT
int FS_AddExtraFastModel(FaceHandle handle, const char *param_path);

AILAB_EXPORT
int FS_AddExtraFastModelFromBuf(FaceHandle handle, const char *param_buf,
                                unsigned int param_buf_len);

AILAB_EXPORT
int FS_DoPredict(
    FaceHandle handle, const unsigned char *image,
    PixelFormatType pixel_format, // 图片格式，支持RGBA, BGRA, BGR, RGB,
                                  // GRAY(YUV暂时不支持)
    int image_width,              // 图片宽度
    int image_height,             // 图片高度
    int image_stride,             // 图片行跨度
    ScreenOrient orientation,     // 图片的方向
    unsigned long long
        detection_config, // 需要设置图片或视频模型 Mode-Config 及要检测的部件
                          // Config-106，包含所有action检测，
                          // 如 TT_MOBILE_DETECT_MODE_VIDEO |
                          // TT_MOBILE_DETECT_FULL
                          // 其中，TT_MOBILE_DETECT_FULL，可以改成要检测的部件，
                          // 如 TT_MOBILE_FACE_DETECT | TT_MOBILE_MOUTH_POUT
                          // Config-240，如 TT_MOBILE_DETECT_MODE_VIDEO |
                          // TT_MOBILE_DETECT_FULL | TT_MOBILE_FACE_240_DETECT
                          // Config-240 快速模式，如
                          // TT_MOBILE_DETECT_MODE_VIDEO |
                          // TT_MOBILE_DETECT_FULL | TT_MOBILE_FACE_240_DETECT
                          // | TT_MOBILE_FACE_240_DETECT_FASTMODE Config-Image
                          // TT_MOBILE_DETECT_MODE_IMAGE |
                          // TT_MOBILE_DETECT_FULL，或者
                          // 效果更好的图像模式，TT_MOBILE_DETECT_MODE_IMAGE_SLOW
                          // | TT_MOBILE_DETECT_FULL 另外，Config
                          // 240、图片模式和其他模式都需要在handle创建时指定具体的config进行初始化，参见上面
                          // FS_CreateHandler, FS_AddExtraModel
    AIFaceInfo *
        p_face_info // 存放结果信息，需外部分配好内存，需保证空间大于等于设置的最大检测人脸数；
);

/**
 * @breif 获取嘴巴mask数据
 * @return 返回嘴巴mask
 *
 */
AILAB_EXPORT
int FS_GetMouthMaskResult(FaceHandle handle, unsigned long long det_cfg,
                          AIMouthMaskInfo *mouthInfo);

/**
 * @breif 获取人脸遮挡概率数据
 * @return 返回遮挡概率
 *
 */
AILAB_EXPORT
int FS_GetFaceOcclusionInfo(FaceHandle handle, AIFaceOcclusionInfo *occinfo);

/**
 * @breif 获取牙齿mask数据
 * @return 返回嘴巴mask
 *
 */
AILAB_EXPORT
int FS_GetTeenMaskResult(FaceHandle handle, unsigned long long det_cfg,
                         AITeenMaskInfo *teenInfo);

/**
 * @breif 获取人脸mask数据
 * @return 返回嘴巴mask
 *
 */
AILAB_EXPORT
int FS_GetFaceMaskResult(FaceHandle handle, unsigned long long det_cfg,
                         AIFaceMaskInfo *faceInfo);
typedef enum {
    // 设置每隔多少帧进行一次人脸检测(默认值有人脸时24, 无人脸时24/3=8), 值越大,
    // cpu占用率越低, 但检测出新人脸的时间越长.
    FS_FACE_PARAM_FACE_DETECT_INTERVAL = 1, // default 24
    // 设置能检测到的最大人脸数目(默认值5),
    // 当跟踪到的人脸数大于该值时，不再进行新的检测. 该值越大, 但相应耗时越长.
    // 设置值不能大于 AI_MAX_FACE_NUM
    FS_FACE_PARAM_MAX_FACE_NUM = 2, // default 5
    // 动态调整能够检测人脸的大小，视频模式强制是4，图片模式可以通过设置为8，检测更小的人脸，检测级别，越高代表能检测更小的人脸，取值范围：4～10
    FS_FACE_PARAM_MIN_DETECT_LEVEL = 3,
    // base 关键点去抖参数，[1-30]
    FS_FACE_PARAM_BASE_SMOOTH_LEVEL = 4,
    // extra 关键点去抖参数，[1-30]
    FS_FACE_PARAM_EXTRA_SMOOTH_LEVEL = 5,
    // 嘴巴 mask 去抖动参数， [0-1], 默认0， 平滑效果更好，速度更慢
    FS_FACE_PARAM_MASK_SMOOTH_TYPE = 6,
    FS_USE_FILTER_V2 = 7,
    FS_USE_FACEMASK_SMOOTH = 8,
    FS_FACE_PARAM_IRIS_SMOOTH_LEVEL = 9
} fs_face_param_type;

// 设置检测参数
AILAB_EXPORT int FS_SetParam(FaceHandle handle, fs_face_param_type type,
                             float value);

AILAB_EXPORT int FS_GetFrameFaceOrientation(const AIFaceInfoBase *result);

/**
 * @breif 获取运行时数据
 * @return
 *
 */
AILAB_EXPORT int FS_GetRuntimeInfo(FaceHandle handle,
                                   ModuleRunTimeInfo *result);

/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT void FS_ReleaseHandle(FaceHandle handle);

#if defined __cplusplus
};
#endif
#endif // _FACESDK_API_H_
