
// Copyright (C) 2020 Beijing Bytedance Network Technology Co., Ltd. All rights reserved.

#ifndef __LENS_ENGINE_EXT_H__
#define __LENS_ENGINE_EXT_H__

#ifndef LENS_EXPORT
#ifdef _WIN32
    #define LENS_EXPORT __declspec(dllexport)
#elif __APPLE__
    #define LENS_EXPORT
#elif __ANDROID__
    #define LENS_EXPORT __attribute__ ((visibility("default")))
#elif __linux__
    #define LENS_EXPORT __attribute__ ((visibility("default")))
#endif
#endif

#include "LensConfigType.h"
#include <vector>
#include <map>
#include <memory>
#include <string>
#include <functional>

namespace LENS {
namespace FRAMEWORK {

typedef enum {
    LENS_DATA_FRAME_GL_TEXTURE = 0,         // 数据类型为帧, opengl texture id
    LENS_DATA_FRAME_CPU_BUFFER_INT8,        // 数据类型为帧, 8bit int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_UINT8,       // 数据类型为帧, 8bit unsigned int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_INT16,       // 数据类型为帧, 16bit int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_UINT16,      // 数据类型为帧, 16bit unsigned int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_INT32,       // 数据类型为帧, 32bit int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_UINT32,      // 数据类型为帧, 32bit unsigned int cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_FP16,        // 数据类型为帧, half cpu buffer
    LENS_DATA_FRAME_CPU_BUFFER_FP32,        // 数据类型为帧, float cpu buffer
    LENS_DATA_FRAME_CVPIXELBUFFER,          // 数据类型为帧, iOS CVPixelBuffer
    LENS_DATA_FRAME_METAL_TEXTURE,          // 数据类型为帧, iOS metal texture
    LENS_DATA_MATRIX_3x3_FLOAT,             // 数据类型为矩阵, 3x3 float类型
    LENS_DATA_MATRIX_4x4_FLOAT,             // 数据类型为矩阵, 4x4 float类型
    LENS_DATA_JSON_PATH,                    // 数据类型为Json文件路径
    LENS_DATA_JSON_STRING,                  // 数据类型为Json字符串
    LENS_DATA_VECTOR,                       // 数据类型为Vetor
    LENS_DATA_FRAME_DX_TEXTURE,             // 数据类型为帧, DirectX texture
} LensAlgorithmDataType;

typedef enum {
    LENS_CONSUMPTION = 0,                   // 消费
    LENS_TRANSTRANSMISSION,                 // 透传
} LensAlgorithmDataUsage;

typedef struct {
    int maxWidth;                           // 算法支持的最大宽，Lens RD必须确保每个算法都配置这个信息
    int maxHeight;                          // 算法支持的最大高，Lens RD必须确保每个算法都配置这个信息
} LensAlgorithmJsonInfo;

typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice，Windows可以传入D3D11Device
    const char* kernelPath;                 // Android和Windows传入可读写目录路径；iOS和mac传入xxx.metallib文件路径
    const char* jsonPath;                   // 传入lens算法配置json文件路径，设置为空则使用下面的jsonString，否则jsonString不起效
    const char* jsonString;                 // 传入lens.json的字符串内容，jsonPath为空时才起效，jsonPath不为空可以设置为NULL
    LensDataFormat pixelFmt;                // 输入输出帧数据格式
} LensAlgorithmConfig;

typedef struct {
    LensAlgorithmDataType   dataType;       // 数据类型
    LensAlgorithmDataUsage  dataUsage;      // 数据使用模式
    const char* kvString;                   // 算法配置信息key-val字符串（目前主要bach使用）
} LensAlgorithmDataInfo;

typedef struct {
    std::map<std::string, LensAlgorithmDataInfo> inputDataInfo;             // 算法输入信息map，形式为<name, info>
    std::map<std::string, LensAlgorithmDataInfo> outputDataInfo;            // 算法输出信息map，形式为<name, info>
    LensAlgorithmType algType;                                              // 算法类型
    const char* algName;                                                    // 算法名称
    const char* jsonPath;                                                   // json文件路径
    const char* jsonString;                                                 // json文件内容
    const char* kvString;                                                   // 键值对信息
} LensAlgorithmInfo;

typedef struct {
    const char* jsonPath;                   // 传入lens算法配置json文件路径，设置为空则使用下面的jsonString，否则jsonString不起效
    const char* jsonString;                 // 传入lens.json的字符串内容，jsonPath为空时才起效
} LensAlgorithmUpdateParam;

typedef struct {
    bool isFirst;                           // 是否为视频第一帧标志
    bool open;                              // 动态开启/关闭算法
    const char* execString;                 // 传入算法每帧执行所需的key-value键值对
    double timeStamp;                       // 当前帧对应的时间戳，单位为s
} LensAlgorithmExecParam;

typedef struct {
    LensAlgorithmDataType type;             // 数据类型
    void* data;                             // 数据指针
    int width;                              // 数据的宽
    int height;                             // 数据的高
    int strideW;                            // 每行存储数据的字节数
    int strideH;                            // 存储数据占用的行数
} LensAlgorithmData;

class LENS_EXPORT ILensAlgorithmInterface {
public:
    virtual ~ILensAlgorithmInterface();
    virtual LensCode SetLicenseInfo(const char *lic_file, const char *appid) = 0;
    virtual LensCode Init(LensAlgorithmConfig* config) = 0;
    virtual LensCode GetAlgorithmInfo(LensAlgorithmInfo* info) = 0;
    virtual LensCode UpdateParam(LensAlgorithmUpdateParam* updateParam) = 0;
    virtual LensCode Process(std::map<std::string,LensAlgorithmData>* input, LensAlgorithmExecParam* execParam) = 0;
    virtual LensCode GetOutput(std::map<std::string,LensAlgorithmData>* output) = 0;
    virtual LensCode Deinit() = 0;
};

class LENS_EXPORT LensAlgorithmFactory {
public:
    static ILensAlgorithmInterface *CreateLensAlgorithm();
    static void ReleaseLensAlgorithm(ILensAlgorithmInterface* instance);
};

class LENS_EXPORT LensAlgorithmUtils {
public:
    static LensCode GetInfoFromJson(const char* jsonFile, const char* jsonString, LensAlgorithmJsonInfo* jsonInfo);
};

} /* namespace FRAMEWORK */
} /* namespace LENS */

#endif // __LENS_ENGINE_EXT_H__
