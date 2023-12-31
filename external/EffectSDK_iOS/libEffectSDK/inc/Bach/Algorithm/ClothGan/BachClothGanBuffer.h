#ifdef __cplusplus
#ifndef BACH_CLOTH_GAN_BUFFER_H
#define BACH_CLOTH_GAN_BUFFER_H

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ClothGanInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;                                 // affine img width
    int height = 0;                                // affine img height
    int image_width = 0;                           // origin img widht
    int image_height = 0;                          // origin img heihgt
    AmazingEngine::UInt8Vector image_data;         // affine img data, RGBA order, [0~255]
    AmazingEngine::Matrix4x4f affineMatrix;              // affine matrix: 4*4
};

NAMESPACE_BACH_END
#endif

#endif