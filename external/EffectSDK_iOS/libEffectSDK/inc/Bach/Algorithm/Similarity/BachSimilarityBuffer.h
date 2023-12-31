#ifdef __cplusplus
#ifndef BACH_SIMILARITY_BUFFER_H
#define BACH_SIMILARITY_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class SimilarityBuffer : public BachBuffer
{
public:
    float score = 0.0f;
    AmazingEngine::UInt8Vector feature;
    AmazingEngine::Int32Vector clusterIds;
};
NAMESPACE_BACH_END

#endif //BACH_SIMILARITY_BUFFER_H

#endif