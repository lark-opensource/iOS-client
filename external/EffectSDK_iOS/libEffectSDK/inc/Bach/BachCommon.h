#ifdef __cplusplus
#ifndef _BACH_COMMON_H_
#define _BACH_COMMON_H_

#include "Bach/Base/BachBaseDefine.h"
#undef NO_ERROR // fix windows build
NAMESPACE_BACH_BEGIN
enum class BachInputType
{
    IMAGE_BUFFER,
    IMAGE_DATA_BUFFER,
    ARRAY_BUFFER,
    MULTI_INPUT
};

enum class BachErrorCode
{
    NO_ERROR = 0,
    INVALID_RES_FINDER = 1,
    NOT_INIT = 2,
    INVALID_CONFIG = 3,
    INVALID_GRAPH = 4,
    INVALID_MODEL = 5,
    INVALID_TYPE = 6,
    INVALID_NODE = 7,
    INVALID_FORMAT = 8,
    INTERNAL_ERROR = 9
};

enum class AEFlipMode
{
    FLIP_NONE = 0x0,
    FLIP_VERTICAL = 0x1,
    FLIP_HORIZONAL = 0x2,
    FLIP_BOTH = 0x3,
};

enum class AEPixelFormat
{
    INVALID = -1,
    RGBA8UNORM = 0,
    BGRA8UNORM = 1, ///! BGRAUnorm
    BGR8UNORM = 2,
    RGB8UNORM = 3,
    GRAY8 = 4, ///< 内部格式为RGBA8，在转换的时候该格式发挥作用.
    YUV420P = 5,
    NV12 = 6,
    NV21 = 7,
    RG8UNORM = 8,
    RGBA16SFLOAT = 9,
    RGBA32SFLOAT = 10,
    R32Sfloat = 11,
    R32Sint = 12,
    R16Sfloat = 13,
    R16Sint = 14,
    YUY2 = 15,
    RG16Sfloat,
    RG32Sfloat,
};

enum class AERotateMode
{
    ROTATE_CW_0 = 0x0,
    ROTATE_CW_90 = 0x1,
    ROTATE_CW_180 = 0x2,
    ROTATE_CW_270 = 0x3,
};

enum class DeviceDataType
{
    NONE = 0,
    IMU_ACC, // 加速度传感器数据，double[3]
    IMU_GYR, // 陀螺仪数据，double[3]
    IMU_GRA, // 重力传感器数据，double[3]
    IMU_WRB, // 旋转矩阵，double[9]
};

class BACH_EXPORT CameraIntrinsicConfig
{
public:
    double fx = 0.0;             // 相机内参
    double fy = 0.0;             // 相机内参
    double cx = 0.0;             // 相机内参
    double cy = 0.0;             // 相机内参
    double deltaTimestamp = 0.0; // 相机的图像数据相对于传感器的固定偏移，单位秒
    bool valid = false;          // Config是否有效
};

class BACH_EXPORT SensorConfig
{
public:
    int accelerometer = 0; // 是否支持加速度传感器
    int gyroscope = 0;     // 是否支持陀螺仪
    int gravity = 0;       // 是否支持重力传感器
    int orientation = 0;   // 是否支持方向传感器
    bool valid = false;    // Config是否有效
};

class BACH_EXPORT CameraConfig
{
public:
    double fovx = 0.0;                                    // 相机参数，fovx
    double fovy = 0.0;                                    // 相机参数，fovy
    int front = 0;                                        // 是否是前置摄像头
    AERotateMode orientation = AERotateMode::ROTATE_CW_0; // 摄像头方向以手机竖直向上为0度
    bool valid = false;                                   // Config是否有效
};

class BACH_EXPORT BachDeviceConfig
{
public:
    CameraIntrinsicConfig intrinsicConfig;
    SensorConfig sensorConfig;
    CameraConfig cameraConfig;

protected:
    int version = 1;
};

NAMESPACE_BACH_END
#endif // BACH_BASE_DEFINE_H

#endif