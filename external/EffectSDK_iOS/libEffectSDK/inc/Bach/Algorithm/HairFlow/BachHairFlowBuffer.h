#ifdef __cplusplus
#ifndef BACH_HAIR_FLOW_BUFFER_H
#define BACH_HAIR_FLOW_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HairFlowInfo : public AmazingEngine::RefBase
{
public:
    int width;
    int height;
    AmazingEngine::UInt8Vector mask;
    AmazingEngine::UInt8Vector motion;
    bool do_inpaint;
    float minX;
    float maxX;
    float minY;
    float maxY;
};

class BACH_EXPORT HairFlowBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<HairFlowInfo> m_hairFlowInfo = nullptr;
};

NAMESPACE_BACH_END
#endif
#endif