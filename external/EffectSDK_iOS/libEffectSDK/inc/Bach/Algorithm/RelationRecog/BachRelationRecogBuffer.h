#ifdef __cplusplus
#ifndef BACH_RELATION_RECOG_BUFFER_H
#define BACH_RELATION_RECOG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT RelationRecogInfo : public AmazingEngine::RefBase
{
public:

};

class BACH_EXPORT RelationRecogBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<RelationRecogInfo>> m_infos;
};

NAMESPACE_BACH_END
#endif
#endif