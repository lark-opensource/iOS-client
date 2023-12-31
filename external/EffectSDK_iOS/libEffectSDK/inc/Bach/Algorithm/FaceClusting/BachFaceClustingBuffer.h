#ifdef __cplusplus
#ifndef BACH_FACE_CLUSTING_BUFFER_H
#define BACH_FACE_CLUSTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceClustingInfo : public AmazingEngine::RefBase
{
public:
    bool is_valid;
};

class BACH_EXPORT FaceClustingBuffer : public BachBuffer
{
public:
    std::vector<int> m_results;
    std::vector<std::vector<int>> m_clusters;
    AmazingEngine::SharePtr<FaceClustingInfo> m_faceClustingInfo;
};

NAMESPACE_BACH_END
#endif
#endif