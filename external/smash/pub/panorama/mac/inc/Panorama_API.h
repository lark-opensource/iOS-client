#ifndef _SMASH_PANORAMAAPI_H_
#define _SMASH_PANORAMAAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* PanoramaHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum PanoramaParamType {
  kPanoramaOutPILen = 1,        // pi's pixel for sphere projection
  kPanoramaUseCameraFix = 2,    // if to fix the camera's k
  kPanoramaImageScale = 3,      // resize scale for image reading
  kPanoramaImageNum = 4,        // number of the image; according to capture method
} PanoramaParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum PanoramaModelType {
  kPanoramaModel1 = 1,          // not used
} PanoramaModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
//struct PanoramaArgs {
//  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
//  // 此处可以添加额外的算法参数
//};

typedef struct PanoImageInput {
    // image data
    ModuleBaseArgs base;
    // camera info
    // 3x3 for k + 4x4 for transform = 25
    float camera[25];
    // 3d point data
    float* pts;
    int numPts;
    // indicator for ring position
    // if not provided, should set ring_index to -1
    bool isUp;
    int ring_index;
} PanoImageInput;


typedef struct PanoramaProg {
    float progress = 0.0f;
} PanoramaProg;

typedef struct PanoramaArgs {
  PanoImageInput* data;
} PanoramaArgs;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct PanoramaRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        // image data buffer
  int width;                   // sphere projeciton image's width
  int height;                  // sphere projeciton image's height
} PanoramaRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return Panorama_CreateHandle
 */
AILAB_EXPORT
int Panorama_CreateHandle(PanoramaHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return Panorama_LoadModel
 */
AILAB_EXPORT
int Panorama_LoadModel(PanoramaHandle handle,
                         PanoramaModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return Panorama_LoadModelFromBuff
 */
AILAB_EXPORT
int Panorama_LoadModelFromBuff(PanoramaHandle handle,
                                 PanoramaModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return Panorama_SetParamF
 */
AILAB_EXPORT
int Panorama_SetParamF(PanoramaHandle handle,
                         PanoramaParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT Panorama_DO
 */
AILAB_EXPORT
int Panorama_DO(PanoramaHandle handle,
                  PanoramaArgs* args,
                  PanoramaRet* ret);


// insert image for process
// would do resize during insertion and *release* the memory
// of the image for reducing memory consume
AILAB_EXPORT
int Panorama_InsertImage(PanoramaHandle handle,
                         PanoImageInput args);

// excute the stitching
AILAB_EXPORT
int Panorama_Excute(PanoramaHandle handle, PanoramaRet* ret);

// get running status
AILAB_EXPORT
int Panorama_GetPorgress(PanoramaHandle handle, PanoramaProg* prog);

// release status, for example reset progress
AILAB_EXPORT
int Panorama_ReleaseStatus(PanoramaHandle handle);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT Panorama_ReleaseHandle
 */
AILAB_EXPORT
int Panorama_ReleaseHandle(PanoramaHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT Panorama_DbgPretty
 */
AILAB_EXPORT
int Panorama_DbgPretty(PanoramaHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_PANORAMAAPI_H_
