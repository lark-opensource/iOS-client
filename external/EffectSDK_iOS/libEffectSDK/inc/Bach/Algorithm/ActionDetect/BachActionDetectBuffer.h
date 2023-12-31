#ifdef __cplusplus
#ifndef _BACH_ACTION_DETECT_BUFFER_H_
#define _BACH_ACTION_DETECT_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ActionDetectInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;
    int index = -1;
    int64_t staticResult;
    int64_t sequenceResult;
};

class BACH_EXPORT ActionDetectBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ActionDetectInfo>> m_actions;
};

NAMESPACE_BACH_END
#endif
#endif