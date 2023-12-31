#ifdef __cplusplus
#ifndef BACH_INTERACIVE_MATTING_BUFFER_H
#define BACH_INTERACIVE_MATTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class AMAZING_SDK_EXPORT InteractiveMattingInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector alphaMask;
    int width;
    int height;
    float left;
    float right;
    float bottom;
    float top;
    int curPen;
    int curStep;
    int maxStep;
};

class AMAZING_SDK_EXPORT InteractiveMattingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<InteractiveMattingInfo> m_interactiveMattingInfo;
};

NAMESPACE_BACH_END
#endif

#endif