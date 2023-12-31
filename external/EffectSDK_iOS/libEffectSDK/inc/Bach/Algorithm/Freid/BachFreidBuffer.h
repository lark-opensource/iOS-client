#ifdef __cplusplus
#ifndef BACH_FREID_BUFFER_H
#define BACH_FREID_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FreidInfo : public AmazingEngine::RefBase
{
public:
    int faceid = -1;
    int trackid = -1;
};

class BACH_EXPORT FreidBuffer : public BachBuffer
{
    // TODO fixme when get result by name
public:
    std::vector<AmazingEngine::SharePtr<FreidInfo>> m_infos;
};

NAMESPACE_BACH_END
#endif

#endif