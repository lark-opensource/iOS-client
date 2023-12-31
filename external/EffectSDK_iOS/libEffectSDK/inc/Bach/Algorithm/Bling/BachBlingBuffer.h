#ifdef __cplusplus
#ifndef _BACH_BLING_BUFFER_H_
#define _BACH_BLING_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BlingResult : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec3Vector points; //max: 50
};

class BACH_EXPORT BlingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<BlingResult> m_blingInfo;

private:
#if BEF_ALGORITHM_CONFIG_BLING && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    BlingBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END
#endif
#endif