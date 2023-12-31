#ifdef __cplusplus
#ifndef BACH_COLOR_MAPPING_BUFFER_H
#define BACH_COLOR_MAPPING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ColorMappingInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    AmazingEngine::UInt8Vector lutData;
};

class BACH_EXPORT ColorMappingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<ColorMappingInfo> m_colorMapping;
};

NAMESPACE_BACH_END
#endif
#endif