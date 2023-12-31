#ifdef __cplusplus
#ifndef _BACH_AUTOREFRAME_BUFFER_H_
#define _BACH_AUTOREFRAME_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT AutoReframeInfo : public AmazingEngine::RefBase
{
public:
    float score = 0;
    AmazingEngine::FloatVector boundingBox;
};

class AutoReframeBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<AutoReframeInfo>> m_autoReframeInfos;
};

NAMESPACE_BACH_END
#endif //_BACH_AUTOREFRAME_BUFFER_H_

#endif