#ifdef __cplusplus
#ifndef BACH_IDREAM_BUFFER_H
#define BACH_IDREAM_BUFFER_H

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT IDreamInfo : public AmazingEngine::RefBase
{
public:
    int width;                        // 算法返回图像的宽
    int height;                       // 算法返回图像的高
    int image_height;                 // 检测图像的高
    int image_width;                  // 检测图像的宽
    AmazingEngine::Matrix4x4f matrix; // 仿射变换矩阵
    AmazingEngine::UInt8Vector alpha; // 算法返回图像数据,RGBA
};

NAMESPACE_BACH_END
#endif
#endif