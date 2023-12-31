//
//  FaceBeautifySDK_API.h
//  Created by heqian on 2019/1/24.
//

#ifndef FaceBeautifySDK_API_HPP
#define FaceBeautifySDK_API_HPP

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif
    
//// 返回值
#define FACE_BEAUTIFY_RET_OK 0                      // 正常运行
#define FACE_BEAUTIFY_RET_SKIP_INVARG_IMAGE 1       // 未执行: 输入图像参数无效
#define FACE_BEAUTIFY_RET_SKIP_INVARG_FACE 2        // 未执行: 输入人脸参数无效
#define FACE_BEAUTIFY_RET_SKIP_INVARG_ALGOTYPE 3    // 未执行: 输入算法参数无效
#define FACE_BEAUTIFY_RET_SKIP_INVARG_PERCENT 4     // 未执行: 输入算法参数无效
#define FACE_BEAUTIFY_RET_SKIP_INVARG_OTHER 5       // 未执行: 其他参数无效
#define FACE_BEAUTIFY_RET_ERROR_MODEL 6             // 模型加载失败
#define FACE_BEAUTIFY_RET_NONE_DESPECKLE 7          // 执行:LOCAL模式未检测到斑痘
#define FACE_BEAUTIFY_RET_ERROR_UNKNOWN -1          // 未知错误

//// 模型类型
#define FACE_BEAUTIFY_MODEL_DESPECKLE   0x00000001  // 斑痘模型: 用于支持 祛斑 和 特殊痣保留 算法
#define FACE_BEAUTIFY_MODEL_DESPECKLE_NEW   0x00000010  // 新斑痘模型
    
//// 算法类型
typedef enum {
    FACE_BEAUTIFY_ALGO_DEBUG = -1,              // 打开调试开关: 显示关键点位置和序号, 同时打印log信息.
    FACE_BEAUTIFY_ALGO_DESPECKLE = 0,           // 祛斑算法
    FACE_BEAUTIFY_ALGO_DESPECKLE_RESERVE = 1,    // 祛斑/特殊痣保留算法
    FACE_BEAUTIFY_ALGO_LOCAL = 2,               //祛斑/特殊痣保留算法返回局部图
    FACE_BEAUTIFY_ALGO_DESPECKLE_NEW = 3                //祛斑/特殊痣新算法
} FaceBeautifyAlgoType;

//// 图像格式
typedef enum {
    FACE_BEAUTIFY_FORMAT_RGBA = 0,
    FACE_BEAUTIFY_FORMAT_RGB = 1,
    FACE_BEAUTIFY_FORMAT_BGRA = 2,
    FACE_BEAUTIFY_FORMAT_BGR = 3
} FaceBeautifyImageFormat;
    
typedef void *FaceBeautifyHandle;

////封装预测接口的返回值
typedef struct FaceBeautifyRet {
  // 下面只做举例，不同的算法需要单独设置
    unsigned char* rgb;        ///< RGB pixels
    unsigned char* mask;       ///despeckleMask pixels
    int width;                   ///< 指定alpha的宽度
    int height;                  ///< 指定alpha的高度
    int rate;                  ///upsample rate
    int posx;                  ///rect: x
    int posy;                  ///rect: y
    int rectw;                 ///rect: w
    int recth;                 ///rect: h
} FaceBeautifyRet;


// 功能: 创建handle
// 返回: 返回0代表成功, 详见返回值说明
AILAB_EXPORT
int FaceBeautify_CreateHandler(FaceBeautifyHandle *handle);     // 输出handle

// 功能: 模型初始化
// 返回: 返回0代表成功, 详见返回值说明
// 说明: 对于将使用的算法, 务必加载对应的模型, 否则会导致错误
AILAB_EXPORT
int FaceBeautify_InitModel(FaceBeautifyHandle handle,
                           const int type,                      // 详见 模型类型 宏说明
                           const char *model_path);             // 模型路径

    
// 功能: 模型初始化
// 返回: 返回0代表成功, 详见返回值说明
// 说明: 对于将使用的算法, 务必加载对应的模型, 否则会导致错误
// 主要android端调用
AILAB_EXPORT
int FaceBeautify_InitModelFromBuff(FaceBeautifyHandle handle,
                            const int type,                      // 详见 模型类型 宏说明
                            const unsigned char* mem_model,
                            int model_size);
    
// 功能: 对图像进行美化操作
// 返回: 返回0代表成功, 详见返回值说明
// 说明: 输出图像将直接保存到输入地址中, 即输出图像与输入图像的格式/大小完全相同, 如需保存原图请先复制一份再传入
//      人脸关键点数组存放顺序: face1.point1.x, f1.p1.y, f1.p2.x, f1.p2.y, ... f2.p1.x, ...
//      输入图像务必与输入关键点保持一致, 输入图像可以接受旋转与翻转, 但要对输入关键点进行对应处理以保证一致.
//      集成算法时, 请增加 FACE_BEAUTIFY_ALGO_DEBUG 算法步骤并检查如下内容:
//      1. 关键点是否和原图人脸对齐.
//      2. 原图颜色正常显示时, 关键点显示应为红色, 否则图像格式输入有误.
//      3. 关键点顺序是否正确: 第一个点会放大显示, 检查脸外轮廓点从第1个点到第33个点是否为逆时针旋转, 否则关键点顺序输入有误.
AILAB_EXPORT
int FaceBeautify_Process(FaceBeautifyHandle handle,             // FaceBeautifyHandle
                         unsigned char *image_data,             // 图像地址
                         const int height,                      // 图像宽度
                         const int width,                       // 图像高度
                         const int stride,                      // 图像行字节数
                         const FaceBeautifyImageFormat format,  // 详见 图像格式 宏说明
                         const float* faces_data,               // 人脸关键点数组 (长度:nfaces*106*2)
                         const int nfaces,                      // 人脸个数
                         const FaceBeautifyAlgoType* types,     // 算法类型数组 (大小为nsteps)
                         const int* percents,                   // 算法程度数组 (大小为nsteps, 0-100)
                         const int nsteps);                     // 算法步数 (>0)

// 功能: 释放handle
// 返回: 返回0代表成功, 详见返回值说明
AILAB_EXPORT
int FaceBeautify_ReleaseHandle(FaceBeautifyHandle handle);


// 功能: 申请结果内存
// 返回:
AILAB_EXPORT
void* FaceBeautify_DO_ME_MallocResultMemory(FaceBeautifyHandle handle);


// 功能: 复制结果
// 返回: 返回0代表成功, 详见返回值说明
AILAB_EXPORT
int FaceBeautify_DO_ME_CopyResult(FaceBeautifyHandle handle,
                                  FaceBeautifyRet* ret);

// 功能: 释放结果内存
// 返回: 返回0代表成功, 详见返回值说明
AILAB_EXPORT
int FaceBeautify_DO_ME_FreeResultMemory(FaceBeautifyRet* ret);

// 功能: 释放sdk多余内存
// 返回: 返回0代表成功, 详见返回值说明
AILAB_EXPORT
int FaceBeautify_DO_ME_FreeSDKMemory(FaceBeautifyHandle handle);
    

#if defined __cplusplus
};
#endif

#endif //FaceBeautifySDK_API_HPP

