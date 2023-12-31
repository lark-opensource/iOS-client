#ifdef __cplusplus
#ifndef BACH_OBJECT_DETECTION2_BUFFER_H
#define BACH_OBJECT_DETECTION2_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ObjectDetection2Info : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect rect;
    float prob;
    int IRLabel;
    int label;
    int objId;
};

class BACH_EXPORT ObjectDetection2Buffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ObjectDetection2Info>> m_objDetInfos;
};

NAMESPACE_BACH_END

#endif // BACH_OBJECT_DETECTION2_BUFFER_H

#endif