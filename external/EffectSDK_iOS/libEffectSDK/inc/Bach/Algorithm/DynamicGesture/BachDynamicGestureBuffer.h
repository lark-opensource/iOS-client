#ifdef __cplusplus
#ifndef BACH_DYNAMIC_GESTURE_BUFFER_H
#define BACH_DYNAMIC_GESTURE_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT DynGestInfo : public AmazingEngine::RefBase
{
public:
    int action = -1;
    float action_score;
};

class BACH_EXPORT DynamicGestureBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<DynGestInfo>> m_gestures;
};

NAMESPACE_BACH_END
#endif
#endif