#ifdef __cplusplus
#ifndef BACH_FOOD_COMICS_BUFFER_H
#define BACH_FOOD_COMICS_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FoodComicsInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector data;
    int width;
    int height;
    //    Matrix4x4f matrix;
    AmazingEngine::FloatVector matrix;
    int faceCount;
};

class BACH_EXPORT FoodComicsBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<FoodComicsInfo> m_foodComicsInfo;
};

NAMESPACE_BACH_END
#endif
#endif