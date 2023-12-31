#ifdef __cplusplus
#ifndef BACH_GROUND_SEG_BUFFER_H
#define BACH_GROUND_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT GroundSegResult : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int srcImageWidth = 0;
    int srcImageHeight = 0;
    AmazingEngine::UInt8Vector mask_data;
};

class BACH_EXPORT GroundSegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<GroundSegResult> m_GroundSegInfo;
};

NAMESPACE_BACH_END
#endif
#endif