#ifdef __cplusplus
#ifndef BACH_FEMALE_GAN_BUFFER_H
#define BACH_FEMALE_GAN_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FemaleGanInfo : public AmazingEngine::RefBase
{
public:
    /// Cropped image in the original resolution
    unsigned char* cropImgData = nullptr;
    unsigned int cropImgWidth = 0;
    unsigned int cropImgHeight = 0;
    unsigned int cropImgChannels = 0;
    unsigned int cropImgStride = 0;
    unsigned int cropImgAlignment = 0;

    /// Output image of the algorithm
    unsigned char* outputImgData = nullptr;
    unsigned int outputImgWidth = 0;
    unsigned int outputImgHeight = 0;
    unsigned int outputImgChannels = 0;
    unsigned int outputImgStride = 0;
    unsigned int outputImgAlignment = 0;

    AmazingEngine::FloatVector affineMatrix; /// Affine matrix vector to crop the origCropImage from the input image
    AmazingEngine::Matrix4x4f affine;        /// Affine matrix
    bool shouldDraw = false;
    int imageWidth = 0;
    int imageHeight = 0;
    int faceId = -1;
};

class BACH_EXPORT FemaleGanBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<FemaleGanInfo> m_femaleGanInfo;
};

NAMESPACE_BACH_END
#endif
#endif