#ifdef __cplusplus
#ifndef BACH_DEPTH_ESTIMATION_BUFFER_H
#define BACH_DEPTH_ESTIMATION_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT DepthEstimationInfo : public AmazingEngine::RefBase
{
public:
    int width;
    int height;
    AmazingEngine::UInt8Vector depthMask;
};

class BACH_EXPORT DepthEstimationBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<DepthEstimationInfo> m_depthEstimation;
};

NAMESPACE_BACH_END
#endif
#endif