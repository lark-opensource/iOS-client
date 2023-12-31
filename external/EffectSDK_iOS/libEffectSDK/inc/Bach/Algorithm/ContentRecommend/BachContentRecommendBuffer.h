#ifdef __cplusplus
#ifndef BACH_CONTENT_RECOMMEND_BUFFER_H
#define BACH_CONTENT_RECOMMEND_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ContentRecommendInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector m_resultData;
};

class BACH_EXPORT ContentRecommendBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ContentRecommendInfo>> m_infos;
};

NAMESPACE_BACH_END
#endif
#endif