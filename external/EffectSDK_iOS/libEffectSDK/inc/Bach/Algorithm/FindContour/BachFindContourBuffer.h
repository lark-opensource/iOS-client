#ifdef __cplusplus
#ifndef BACH_FIND_CONTOUR_BUFFER_H
#define BACH_FIND_CONTOUR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FindContourInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec2Vector contours;
    AmazingEngine::Int32Vector hierarchy;
    int width;
    int height;
};

class BACH_EXPORT FindContourBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FindContourInfo>> m_findContourInfos;
};

NAMESPACE_BACH_END
#endif
#endif