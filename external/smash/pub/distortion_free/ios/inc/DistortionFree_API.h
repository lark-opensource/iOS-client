#ifndef _SMASH_DISTORTIONFREEAPI_H_
#define _SMASH_DISTORTIONFREEAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include <HeadSeg_API.h>
#include <FaceSDK_API.h>


#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void *DistortionFreeHandle;


#define kDistortionFreeGridColsDefault      (113)
#define kDistortionFreeGridRowsDefault      (78)
#define kDistortionFreeGridPaddingDefault   (4)
#define kDistortionFreeUseCpuWarpDefault    (1)

/**
 * @brief 模型参数类型
 */
typedef enum DistortionFreeParamType {
    kDistortionFreeGridCols = 1,            ///<  grid 的列数（宽度)          默认是113
    kDistortionFreeGridRows = 2,            ///<  grid 的行数（高度)          默认是78
    kDistortionFreeGridPadding = 3,         ///<  grid 的padding            默认是4
    kDistortionFreeUseCpuWarp = 4           ///<  是否使用cpu进行图像的warp    大于0就是True
} DistortionFreeParamType;


typedef struct DistortionFreeCameraInfo{
    float verticalViewAngle;                ///<  required  单位是角度
    float horizontalViewAngle;              ///<  required  单位是角度
    float focalLength;                      ///<  required  单位是mm
    float focalLengthIn35mm;                ///<  optional  单位是mm
} DistortionFreeCameraInfo;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct DistortionFreeArgs {
    ModuleBaseArgs base;                    ///< 对视频帧数据做了基本的封装
    HeadSegOutput * headSegOutput;          ///< 大头的分割结果，需要的是所有人头的结果
    DistortionFreeCameraInfo cameraInfo;    ///< 拍摄当前图像的fov信息，单位是角度
} DistortionFreeArgs;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct DistortionFreeRet {
    // 下面只做举例，不同的算法需要单独设置
    bool use_cpu_warp;                      ///< 是否使用cpu进行图像的warp操作，如果改值为true，那么下面的图像是处理后的结果
    unsigned char *image;                   ///< 返回图像 值位于[0, 255] 之间
    int width;                              ///< 指定image的宽度
    int height;                             ///< 指定image的高度
    PixelFormatType pixel_fmt;              ///< 图像格式


    float * src_grid;                       ///< 原始的网格，每一个点是一个(x,y)的值， 该数组大小是(grid_cols + 2 * padding) * (grid_rows + 2 * padding) * 2
    float * opt_grid;                       ///< 优化后的网格，每一个点是一个(x,y)的值, 该数组大小是(grid_cols + 2 * padding) * (grid_rows + 2 * padding) * 2
    int grid_cols;                          ///< 网格的宽度  可以通过设置kDistortionFreeGridCols修改默认值
    int grid_rows;                          ///< 网格的高度  可以通过设置kDistortionFreeGridRows修改默认值
    int grid_padding;                       ///< 网格的padding数值

    int * grid_triangle;                    ///< 原始的网格进行三角剖分的顶点索引值
    int grid_triangle_length;               ///< grid_triangle_index数组的长度。
} DistortionFreeRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return DistortionFree_CreateHandle
 */
AILAB_EXPORT
int DistortionFree_CreateHandle(DistortionFreeHandle *out);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return DistortionFree_SetParamF
 */
AILAB_EXPORT
int DistortionFree_SetParamF(DistortionFreeHandle handle,
                             DistortionFreeParamType type,
                             float value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT DistortionFree_DO
 */
AILAB_EXPORT
int DistortionFree_DO(DistortionFreeHandle handle,
                      DistortionFreeArgs *args,
                      DistortionFreeRet *ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT DistortionFree_ReleaseHandle
 */
AILAB_EXPORT
int DistortionFree_ReleaseHandle(DistortionFreeHandle handle);


#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_DISTORTIONFREEAPI_H_
