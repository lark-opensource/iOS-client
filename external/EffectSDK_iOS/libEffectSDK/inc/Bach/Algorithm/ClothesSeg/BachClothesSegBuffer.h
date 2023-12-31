#ifdef __cplusplus
#ifndef BACH_CLOTHES_SEG_BUFFER_H
#define BACH_CLOTHES_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ClothesSegInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int left = 0;
    int top = 0;
    int right = 0;
    int bottom = 0;
    float shiftX = 0.0;
    float shiftY = 0.0;
    AmazingEngine::UInt8Vector mask_data;
};

class BACH_EXPORT ClothesSegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<ClothesSegInfo> m_clothesSegInfo;
};

NAMESPACE_BACH_END
#endif
#endif