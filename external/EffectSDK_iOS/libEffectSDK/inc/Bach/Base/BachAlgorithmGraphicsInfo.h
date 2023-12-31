#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_GRAPHICES_INFO_H_
#define _BACH_ALGORITHM_GRAPHICES_INFO_H_

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT GraphicsInfo : public AmazingEngine::RefBase
{
public:
    int imageHeight;                  // 检测图像的高
    int imageWidth;                   // 检测图像的宽
    int width;                        // 算法返回图像的宽
    int height;                       // 算法返回图像的高
    AmazingEngine::Matrix4x4f matrix; // 仿射变换矩阵
    AmazingEngine::UInt8Vector data;  // 算法返回图像数据
    AEPixelFormat format;             // 图像的格式
    int id;                           // 标示结果使用，可选参数
    int32_t textureID = 0;            // GL Texture ID
    void* nativeBuffer = nullptr;     // Will be consumed in RTTI Gen and cast to AmazingEngine::texture2D
};

NAMESPACE_BACH_END

#endif
#endif