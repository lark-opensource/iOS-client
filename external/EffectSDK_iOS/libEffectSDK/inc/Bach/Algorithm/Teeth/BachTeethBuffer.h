#ifdef __cplusplus
#ifndef BACH_TEETH_BUFFER_H
#define BACH_TEETH_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT TeethInfo : public AmazingEngine::RefBase
{
public:
    int faceId;
    AmazingEngine::Vec2Vector teethPts;
    int faceCount;
    int imageWidth;
    int imageHeight;
};

class BACH_EXPORT TeethBuffer : public BachBuffer
{

public:
    std::vector<AmazingEngine::SharePtr<TeethInfo>> m_teethInfos;
};

NAMESPACE_BACH_END

#endif

#endif