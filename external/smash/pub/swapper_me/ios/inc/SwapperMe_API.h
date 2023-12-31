#ifndef _SMASH_SWAPPERMEAPI_H_
#define _SMASH_SWAPPERMEAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"
#include "face_fitting_API2.h"


/**
 * 简要介绍算法的主要流程：
 * 0. json文件解析，进行模型加载（SwapperMe_LoadModel）
 * 1. 人脸关键点检测（FS_DoPredict）
 * 2. 3d人脸重建（FaceFitting_DoFitting3dMesh2）
 * 3. 姿态判断是否符合要求 (SwapperMe_AngleCheck)
 * 4. 清除上一次的缓存(SwapperMe_ResetCache)
 * for ....
 *      5. 最大的人脸进行祛斑（FaceBeautify_Process）
 *      6. 执行3d人脸转正  (SwapperMe_Frontalization)
 *      7. 转正的人脸进行人脸关键点检测（FS_DoPredict）
 *      8. 融合操作获得输出结果 （SwapperMe_DO）
 * end
 */

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void *SwapperMeHandle;

#define SWAPPER_LANDMARK_COUNT 212

/**
 * SwapperMeFSAlgoConfig --> SwapperMeFSFaceConfig --> SwapperMeFSModelConfig 这三个结构需要从json来读取数据进行填充,
 * 然后 传递给 SwapperMe_LoadModel 来加载配置
 */
typedef struct SwapperMeFSAlgoConfig {
    int kAlgoType;              // FS_ADVANCE_BLEND_MIX_SHAPE_LIGHT;  6

    float kDeformRate;          // 0.5f;
    float kTriangleBlurRate;    // 0.2f;
    int kDespecklePercent;      // 100;
    int kBrightenEyePercent;    // 50;
    int kBrightenEyebagPercent; // 100, 80;
    int kSmoothPercent;         // 80, 50;

    float kBgWeight;            // 1.0f;
    float kEyeWeight;           // 0.628f;
    float kMouthWeight;         // 0.235f;
    float kMaskBlurWeight;      // 0.25f;
    int kLPW;                   // -1;
} SwapperMeFSAlgoConfig;

typedef struct SwapperMeFSFaceConfig {
    SwapperMeFSAlgoConfig kAlgoConfig;

    int kStdMaskId;   // 0;
    int kShapeType;   // 1;
    int kShape[SWAPPER_LANDMARK_COUNT];

    int k3DRect[4];
    float k3DParams[432];
} SwapperMeFSFaceConfig;

typedef enum SwapperMeFSType {
    // 未定义的
    FS_UNDEFINED = -1,
} SwapperMeFSType;

/**
 * 对应服务端的配置文件faceswap2.conf
 */
typedef struct SwapperMeProtobufConfig {
    float k_3d_angle_mean[3];                   // {-15.4526f, 0.868237f, 0.981351f}
    float k_3d_angle_threshold_model_max[3];    // {20.0f, 15.0, 0.0}
    float k_2d_angle_threshold_model_max[3];    // {25.0f, 12.0f, 0.0f}

    float k_3d_angle_threshold_source_max[3];   // {35.0f, 30.0f, 0.0f}
    float k_3d_angle_threshold_source_min[3];   // {10.0f, 6.0f, 0.0f}
    float k_2d_angle_threshold_source_max[3];   // {35.0f, 18.0, 0.0f}

    float k_3d_distance_yaw_to_picth_rate;      // 2.0f;
    float k_3d_finetune_rate[3];                // {0.3f, 0.8f, 1.0f}
    float k_3d_finetune_range[3];               // {360.0f, 360.0f, 360.0f}
    float k_render_size_rate;                   // 1.0f
    int k_render_size_max;                      // 600
    int k_render_size_min;                      // 100
    float facedetect_min_probs;                 // 0.5f
    bool dont_use_default_value;                // 模块内有一些预设的参数, 如果不使用预设参数可以将这个值设置为true，然后填充上面的变量
} SwapperMeProtobufConfig;

typedef struct SwapperMeFSModelConfig {
    int kVersion;           // 兼容 3 4(增加去眼袋/美妆) 5(增加亮眼/转脸角度修正/亮光修正) 6(美妆/滤镜/贴纸全面支持,增加融合算法7) 三个版本
    SwapperMeFSType kStyleType;
    SwapperMeFSType kStyleType1;
    SwapperMeFSType kStyleType2;

    int kFaceCount;
    SwapperMeFSFaceConfig kFaceConfigs[10]; // 换脸的一些配置(例子素材包中的00001.json中的FaceConfig项)， 一般情况下只有一个FaceConfig

    ModuleBaseArgs modelImage;      // 模版图像(例子素材包中的00001.jpg), 彩色图像, 数据格式是 kPixelFormat_RGBA8888, kPixelFormat_BGRA8888, kPixelFormat_BGR888, kPixelFormat_RGB888
    ModuleBaseArgs maskStdImage;    // 标准人脸mask(例子素材包中的facemask.png), 灰度图像，数据格式是 kPixelFormat_GRAY

    SwapperMeProtobufConfig pbConfig;   // 配置文件(对应服务端的faceswap2.conf中的一部分)

    char *standardFaceBuffer;      // 标准人脸相关(例子素材包中的standardface.bin), 将standardface.bin进行二进制读到内存buffer, 内部会解析出标准人脸相关的数据
    int standardFaceBufferLen;      // standardFaceBuffer的长度
} SwapperMeFSModelConfig;


/**
 * 参数类型, 暂时需要设置, 没有可设置的参数, 留在这里保持接口的兼容性
 */
typedef enum SwapperMeParamType {
    kSwapperMeVertexCountHorizonal = 1,        ///< TODO: 根据实际情况修改
    kSwapperMeVertexCountVertical = 2,        ///< TODO: 根据实际情况修改
} SwapperMeParamType;

/**
 * 一组对应关系， 检测到的人脸关键点信息中的faceArrayIndex的人脸 会被换到 模版图像中modelArrayIndex的模版人脸。
 */
typedef struct SwapperMeMapper{
    int faceArrayIndex;   // AIFaceInfoBase base_infos[AI_MAX_FACE_NUM]; 中的数组索引
    int modelArrayIndex;    // 模版数据中的 SwapperMeFSFaceConfig kFaceConfigs[10]  中的数组索引;
} SwapperMeMapper;

/**
 * @brief 封装预测接口的输入数据的封装
 * base 输入的图像数据, 数据格式是(kPixelFormat_RGBA8888, kPixelFormat_BGRA8888, kPixelFormat_BGR888, kPixelFormat_RGB888)之一
 * faceInfo 人脸检测FS_DoPredict函数 返回的结果
 * mapper   检测到的人脸与模版上人脸的对应关系
 * faceFittingResult 3d人脸重建FaceFitting_DoFitting3dMesh2函数返回的结果, 需要使用的FaceFitting中的Model_1220获得结果
 */
typedef struct SwapperMeArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    AIFaceInfo *faceInfo;
    FaceFittingResult2 *faceFittingResult;
    SwapperMeMapper mapper;
} SwapperMeArgs;


/**
 * @brief 封装预测接口的返回值 返回的数据组成一个图像
 * image  返回数据的的指针的应用, SwapperMe_DO中返回的数据如果需要使用请 deepcopy 一份图像。
 * image.pixel_fmt 图像格式 kPixelFormat_RGB888 注意这里返回数据格式是固定的.
 * face_landmark_array 输出图像中的人脸landmark 106个点, 可能有多个人脸
 * face_count 输出图像中人脸的个数, 1个或者多个.
 */
typedef struct SwapperMeRet {
    unsigned char *data;
    int width;
    int height;
    int channel;
    int image_stride;
    PixelFormatType pixel_fmt;

    float face_landmark_array[10][SWAPPER_LANDMARK_COUNT];
    int face_count;
} SwapperMeRet;


/**
 * @brief 创建句柄
 * @param out 初始化的句柄
 * @return success: SMASH_OK, failed: others
 */
AILAB_EXPORT
int SwapperMe_CreateHandle(SwapperMeHandle *out);


/**
 * @brief 从SwapperMeFSModelConfig中加载模型
 * @param handle 句柄
 * @param model SwapperMeFSModelConfig的结构, 需要从一个json文件来读取数据, 解析图像.
 * @return success: SMASH_OK, failed: others
 */
AILAB_EXPORT
int SwapperMe_LoadModel(SwapperMeHandle handle, SwapperMeFSModelConfig *model);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return success: SMASH_OK, failed: others
 */
AILAB_EXPORT
int SwapperMe_SetParamF(SwapperMeHandle handle, SwapperMeParamType type, float value);


/**
 * @brief 算法的主要调用接口 用来进行输入图像base与模版图像进行换脸
 * @param handle
 * @param args  封装的数据输入 SwapperMeArgs(必须包括base，faceInfo, mapper 不需要faceFittingResult), 如果走了3d人脸转正，
 * 那么base应该是SwapperMe_Frontalization返回的结果， faceInfo是SwapperMe_Frontalization返回图像的人脸检测结果。
 * @param ret   返回的数据数据 SwapperMeRet(返回一个kPixelFormat_RGB888格式图像， 大小与modelImage是一致的)
 * @return success: SMASH_OK, failed: SMASH_E_INVALID_PARAM(输入参数失败), -1(换脸主函数失败), 5(正脸判断失败),
 */
AILAB_EXPORT
int SwapperMe_DO(SwapperMeHandle handle, SwapperMeArgs *args, SwapperMeRet *ret);


/**
 * @brief 输入图像正脸化, 在一定的角度范围内对输入的图像进行3d人脸转正的操作, 如果角度太大会失败
 * @param handle
 * @param args  封装的数据输入 SwapperMeArgs(必须包括base，faceInfo, mapper，faceFittingResult)
 * @param ret   返回的数据数据 SwapperMeRet(返回一个kPixelFormat_RGB888格式图像， 是一个经过裁剪的3d人脸转换后的图像)
 * @return success: SMASH_OK, failed: SMASH_E_INVALID_PARAM(输入参数失败)，4(人脸太小导致判断无人脸)，5(正脸判断失败), others(其他错误)
 */
int SwapperMe_Frontalization(SwapperMeHandle handle, SwapperMeArgs *args, SwapperMeRet *ret);

/**
 * @brief 在执行Frontalization之前做一步轻量级的正脸阈值判断， 如果失败不进行正脸化及换脸操作
 * @param handle
 * @param args 封装的数据输入 SwapperMeArgs(必须包括base，faceInfo, mapper， faceFittingResult)
 * @return success: SMASH_OK, failed: SMASH_E_INVALID_PARAM(输入参数失败)，4(人脸太小导致判断无人脸)，5(正脸判断失败), others(其他错误)
 */
int SwapperMe_AngleCheck(SwapperMeHandle handle, SwapperMeArgs *args);

/**
 * @brief 在多个人脸，多个模版的情况下, 内部会缓存上一次的换脸结果, 调用这个函数将缓存清除。
 * @param handle
 * @return SMASH_OK, failed: others
 */
int SwapperMe_ResetCache(SwapperMeHandle handle);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return success: SMASH_OK, failed: others
 */
AILAB_EXPORT
int SwapperMe_ReleaseHandle(SwapperMeHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT SwapperMe_DbgPretty
 */
AILAB_EXPORT
int SwapperMe_DbgPretty(SwapperMeHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_SWAPPERMEAPI_H_
