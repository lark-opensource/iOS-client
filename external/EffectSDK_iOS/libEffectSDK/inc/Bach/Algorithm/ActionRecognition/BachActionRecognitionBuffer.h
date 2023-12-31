#ifdef __cplusplus
#ifndef BACH_ACTION_RECOGNITION_BUFFER_H_
#define BACH_ACTION_RECOGNITION_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ActionRecognitionInfo : public AmazingEngine::RefBase
{
public:
    bool isValid = false;
    int actionLabel = -1;
    float actionScore = 0;
};

class BACH_EXPORT ActionRecognitionBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ActionRecognitionInfo>> m_actionRecognitonInfos;
    bool m_isExecuted = false;
};

NAMESPACE_BACH_END

#endif

#endif