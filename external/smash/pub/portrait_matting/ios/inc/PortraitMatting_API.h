#ifndef _PORTRAIT_MATTING_API_H
#define _PORTRAIT_MATTING_API_H

#include "smash_module_tpl.h"
#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif
// prefix: PM -> PortraitMatting

typedef void* PortraitMattingHandle;

/*
 * @brief 推荐配置
 **/

typedef struct MP_RecommendConfig {
  int OutputMinSideLen;
  int FrashEvery;
  int EdgeMode;
} MP_RecommendConfig;
/*
 * @brief SDK参数
 * edge_mode:
 *    算法参数，用来设置边界的模式
 *    - 1: 不加边界
 *    - 2: 加边界
 *    - 3: 加边界, 其中, 2 和 3 策略不太一样，但效果上差别不大，可随意取一个
 * fresh_every:
 *    算法参数，设置调用多少次强制做预测，目前设置 15 即可
 * MP_OutputMinSideLen:
 *    不设置，只做GetParam；返回短边的长度, 默认值为128, 需要为16的倍数；
 * MP_OutputWidth 不设置，只做GetParam 兼容之前的调用
 * MP_OutputHeight 不设置，只做GetParam 兼容之前的接口；
 * MP_VideoMode:
 *    算法参数，用来设置是否使用视频模式
 *    - 0: 图片模式
 *    - 1: 视频模式
 * MP_ForwardType:
 *    模型inference时的backend类型，需要在调用 MP_InitModel 或 MP_InitModelFromBuf 前设置
 *    -1为默认值，有效值与ByteNNBasicType.h中的ByteNN::ForwardType一致
 *    建议值：跑cpu选CPU；跑gpu在iOS/macOS上选METAL，其他选GPU
 *    - 0: CPU,  // Android, iOS, Mac, Windows and Linux
 *    - 1: GPU,  // Android, iOS, Mac, Windows
 *    - 2: DSP,  // Android, iOS
 *    - 3: NPU,  // Android
 *    - 4: Auto, // Android, iOS, Mac, Windows and Linux
 *
 *    - 5: METAL,  // iOS
 *    - 6: OPENCL, // Android, Mac, Windows
 *    - 7: OPENGL,
 *    - 8: VULKAN,
 *    - 9: CUDA,   // Windows
 *    - 10: CoreML, // iOS and Mac
 */
typedef enum MP_ParamType {
  MP_EdgeMode = 0,
  MP_FrashEvery = 1,
  MP_OutputMinSideLen = 2,
  MP_OutputWidth = 3,
  MP_OutputHeight = 4,
  MP_VideoMode = 5,
  MP_ForwardType = 6,
} MP_ParamType;

/*
 * @brief 模型类型枚举
 **/
typedef enum MP_ModelType {
  MP_LARGE_MODEL = 0,
  MP_SMALL_MODEL = 1,
  MP_UNREALTIME_MODEL = 2,
  MP_SUBJECT_MODEL = 3,
  MP_VIDEO_MODEL = 4,
  MP_COREML_MODEL = 5,
  MP_COREMLC_MODEL = 6  // coreml model with encryption
} MP_ModelType;

/*
 * @brief 输入参数结构体
 **/
typedef struct MP_Args {
  ModuleBaseArgs base;   //基本的视频帧相关的数据
  bool need_flip_alpha;  //指定是否需要对结果翻转
} MP_Args;



/*
 * @brief 返回结构体，alpha
 * 空间需要调用方负责分配内存和释放，保证有效的控场大于等于widht*height
 * @note
 * 根据输入的大小，短边固定到MP_OutputMinSideLen参数指定的大小，长边保持长宽比缩放；
 *       如果输入的image_height > image_width: 则
 *                width = MP_OutputMinSideLen,
 *                height =
 * (int)(1.0*MP_OutputMinSideLen/image_width*image_height);
 *                //如果长度不为16的倍数，则取最近的16的倍数
 *                net_input_w = 16*(int(float(net_input_w)/16+0.5f));
 */
typedef struct MP_Ret {
  unsigned char*
      alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;   // alpha 的宽度
  int height;  // alpha 的高度
} MP_Ret;

/*
 * @brief 返回结构体，
 * 有效alpha外接框
 */
typedef struct MP_Ret_Rect {
    float left;
    float right;
    float top;
    float down;
} MP_Ret_Rect;



/*
 * @brief 创建Matting 句柄
 **/
AILAB_EXPORT
int MP_CreateHandler(PortraitMattingHandle* out);

/*
 * @brief 从文件初始化模型参数
 **/
AILAB_EXPORT
int MP_InitModel(PortraitMattingHandle handle,
                 MP_ModelType type,
                 const char* param_path);

/*
 * @brief 从buffer 初始化模型参数，android 推荐使用
 **/
AILAB_EXPORT
int MP_InitModelFromBuf(PortraitMattingHandle handle,
                        MP_ModelType type,
                        const char* param_buf,
                        unsigned int len);
/*
 * @brief 设置SDK参数
 **/
AILAB_EXPORT
int MP_SetParam(PortraitMattingHandle handle, MP_ParamType type, int value);

/*
 * @brief 设置SDK参数
 **/
AILAB_EXPORT
int MP_GetParam(PortraitMattingHandle handle, MP_ParamType type, int* value);

/*
 * @brief 设置ByteNN oclKernelBinPath
 * @note
 * IOS默认值为"/private/{container_dir}/Documents"，其他平台为"./"
 * 设置为可写路径，可加快Android/Mac/Windows端ByteNN引擎的初始化速度
 * 一般不需要自定义路径，如需设置，在MP_InitModel和MP_InitModelFromBuf前调用
 **/
AILAB_EXPORT
int MP_SetOclKernelBinPath(PortraitMattingHandle handle, const char* ocl_path);

/*
 * @brief 获取返回alpha尺寸
 **/
AILAB_EXPORT
int MP_GetAlphaSize(PortraitMattingHandle handle, int image_width, int image_height, int *alpha_width, int *alpha_height);

/*
 * @brief 进行抠图操作
 * @note ret 结构图空间需要外部分配
 **/
AILAB_EXPORT
int MP_DoPortraitMatting(PortraitMattingHandle handle,
                         MP_Args* arg,
                         MP_Ret* ret);

/*
 * @brief 进行抠图操作
 * @note ret，ret_box 结构图空间需要外部分配
 **/
AILAB_EXPORT
int MP_DoPortraitMattingRect(PortraitMattingHandle handle,
                         MP_Args* arg,
                         MP_Ret* ret, MP_Ret_Rect* ret_rect);


/*
 * @brief 进行边界优化
 * @note image_width, image_height 目标alpha 宽高
 **/
AILAB_EXPORT
int MP_ProcessBorder(PortraitMattingHandle handle,
                         MP_Args* arg,
                         int image_width, int image_height,
                         MP_Ret* ret);

/*
 * @brief 忽略历史帧，重置光流&平滑
 **/
AILAB_EXPORT
int MP_IgnorePrevious(PortraitMattingHandle handle);

/*
 * @brief 释放句柄
 **/
AILAB_EXPORT
int MP_ReleaseHandle(PortraitMattingHandle handle);


#if defined __cplusplus
};
#endif
#endif  // _HAIR_PARSER_API_H
