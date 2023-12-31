// HdrnetSDK_API.h

#ifndef HdrnetSDK_API_HPP
#define HdrnetSDK_API_HPP

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

//// 图片格式
typedef enum HdrnetImageFormat {
    HDRNET_RGB = 0,
    HDRNET_RGBA = 1,
    HDRNET_BGR = 2,
    HDRNET_BGRA = 3
} HdrnetImageFormat;
  
typedef enum HdrnetErrorType {
    HDRNET_ERR_BAD_SIZE = -111,
} HdrnetErrorType;
    
//// 不同模型版本: 对应不同的算法效果, 注意InitModel时传入对应的.model文件
typedef enum HdrnetModelType {
    HDRNET_BACK = 0,            // 后置场景 拍照模型, 输入图尺寸256*256, 对应.model模型文件名 MODEL_TT_HDRNET
    HDRNET_FRONT = 1,           // 自拍场景 拍照模型, 输入图尺寸256*256, 对应.model模型文件名 MODEL_TT_HDRNET
    HDRNET_BACK_FAST = 2,       // 后置场景 视频模型, 输入图尺寸128*128, 对应.model模型文件名 MODEL_TT_HDRNET_EFFECT
    HDRNET_TONE_FAST = 3,       // 影调模型 视频模型, 输入图尺寸128*128, 对应.model模型文件名 MODEL_TT_HDRNET_TONE
    HDRNET_TONE = 4,            // 影调模型 图片模型, 输入图尺寸256*256, 对应.model模型文件名 MODEL_TT_HDRNET_TONEPIC
} HdrnetModelType;

//// 参数类型, 通过 Hdrnet_SetParam 进行设置
typedef enum HdrnetParamType {
    //// 间隔设置: 影响到视频实时速度以及平滑策略
    // 如果同一个handle如果在视频模式与图片模式之间进行了切换, 务必进行设置
    // 数值代表执行模型间隔, 默认为1. 必须>=1, 图片模式为1, 视频模式建议值4-8
    HDRNET_PARAM_INTERVAL = 0,
} HdrnetParamType;
    
//// 模型参数, 通过Hdrnet_GetModelParam获取
typedef struct HdrnetModelParam {
    float ccm[9];
    float ccm_bias[3];
    float shifts[48];
    float slopes[48];
    float channel_mix_weight[3];
    float channel_mix_bias[1];
} HdrnetModelParam;

typedef void *HdrnetHandle;

// /**
//  * 创建handle
//  * @param handle         HdrnetHandle
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_CreateHandler(HdrnetHandle *handle);

// /**
//  * 参数设置, 详见 HdrnetParamType 宏说明
//  * @param handle         HdrnetHandle
//  * @param interval       HdrnetParamType
//  * @param value          参数值
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_SetParam(HdrnetHandle handle, HdrnetParamType param_type, float value);
    
// /**
//  * 基于文件路径的模型初始化 (一个handle仅能加载一个模型)
//  * @param handle         HdrnetHandle
//  * @param type           HdrnetModelType (详见enum说明)
//  * @param model_path     模型的绝对路径
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_InitModel(HdrnetHandle handle, const HdrnetModelType type, const char *model_path);

// /**
//  * 基于BUF的模型初始化 (一个handle仅能加载一个模型)
//  * @param handle         HdrnetHandle
//  * @param type           HdrnetModelType (详见enum说明)
//  * @param param_buf      BUFFER地址
//  * @param param_buf_len  BUFFER长度
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_InitModelFromBuf(HdrnetHandle handle, const HdrnetModelType type, const char *param_buf, unsigned int param_buf_len);
    
// /**
//  * 获得模型固定参数, 用于GPU运算
//  * 注意: 给定模型时参数固定不变, 仅需获取一次.
//  * @param handle         HdrnetHandle
//  * @param param          输出参数地址 (内存在模块中管理, 外部可以不申请内存或拷贝)
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_GetModelParam(HdrnetHandle handle, HdrnetModelParam** param);
    
// /**
//  * 运行模型并得到Grid参数, 用于GPU运算
//  * 注意: 给定模型与给定图片时参数不变, 图片变化时需要再次获取.
//  *      图像方向要和GPU输入图像方向保持一致.
//  *      对于图片模式, 务必先 Hdrnet_SetInterval 设置interval为1
//  *      输出Grid参数大小: 3(rgb) * 16(height) * 16(width) * 8(depth) * 4(params)
//  * @param handle         HdrnetHandle
//  * @param image_data     图像地址 (原图 或者 传入方向一致的缩略图)
//  * @param height         图像高度
//  * @param width          图像宽度
//  * @param stride         图像stride
//  * @param format         图像格式 HdrnetImageFormat (RGB格式速度最佳)
//  * @param out_grid       输出Grid参数地址 (内存在模块中管理, 外部可以不申请内存或拷贝)
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_RunGridNet(HdrnetHandle handle, const unsigned char *image_data, const int height, const int width, const int stride, const HdrnetImageFormat format, float** out_grid);

// /**
//  * 基于上次 Hdrnet_RunGridNet 的结果预估diff值, diff[0],diff[1],diff[2] 分别代表结果图与原图 亮度(L)/颜色(a)/颜色(b)通道 的差值
//  * 注意: 对于图片模式, 务必先 Hdrnet_SetInterval 设置interval为1, 然后 Hdrnet_RunGridNet, 执行本函数此时返回才是当前图片的diff值;
//  *      对于视频模式, 本函数返回的是所有调用的平均diff值, 清零需再次调用 Hdrnet_SetInterval
//  * @param handle         HdrnetHandle
//  * @param diff           输出结果地址 (内存在模块中管理, 外部可以不申请内存或拷贝)
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_PredictDiff(HdrnetHandle handle, float** diff);
    
// /**
//  * CPU上对原图进行全部处理, 结果覆盖原图 (速度非常慢, 仅供测试)
//  * @param handle         HdrnetHandle
//  * @param image_data     图像地址
//  * @param height         图像高度
//  * @param width          图像宽度
//  * @param stride         图像stride
//  * @param format         图像格式 HdrnetImageFormat (RGB格式速度最佳)
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_ProcessAllInCPU(HdrnetHandle handle, unsigned char *image_data, const int height, const int width, const int stride, const HdrnetImageFormat format);

// /**
//  * 释放模型
//  * @param handle         HdrnetHandle
//  * @return               success 0, others failed;
//  */
AILAB_EXPORT
int Hdrnet_ReleaseHandle(HdrnetHandle handle);

#if defined __cplusplus
};
#endif

#endif //HdrnetSDK_API_HPP
