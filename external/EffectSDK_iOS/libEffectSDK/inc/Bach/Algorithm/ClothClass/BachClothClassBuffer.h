#ifdef __cplusplus
#ifndef BACH_CLOTH_CLASS_BUFFER_H
#define BACH_CLOTH_CLASS_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

#define MaxClothVerticesCount 128
#define MaxClothPiecesPerFrame 16

class BACH_EXPORT ClothClassInfo : public AmazingEngine::RefBase
{
public:
    int trackID;
    int type;
    float score;
    float x0;
    float y0;
    float x1;
    float y1;
    AmazingEngine::Vec2Vector vertices;
    AmazingEngine::FloatVector probs;
};

class BACH_EXPORT ClothClassBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ClothClassInfo>> m_clothInfos;
};

NAMESPACE_BACH_END
#endif
#endif