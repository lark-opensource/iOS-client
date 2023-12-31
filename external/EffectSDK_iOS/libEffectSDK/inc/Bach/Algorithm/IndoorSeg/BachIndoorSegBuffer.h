#ifdef __cplusplus
#ifndef BACH_INDOOR_SEG_BUFFER_H_
#define BACH_INDOOR_SEG_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class AMAZING_SDK_EXPORT IndoorSegInfo : public AmazingEngine::RefBase
{
public:
    std::vector<AmazingEngine::UInt8Vector> mask; // ceiling, wall, floor
    int width = 0;
    int height = 0;
};

class AMAZING_SDK_EXPORT IndoorSegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<IndoorSegInfo> m_indoorSegInfo;
};

NAMESPACE_BACH_END
#endif

#endif