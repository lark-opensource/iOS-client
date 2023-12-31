#ifdef __cplusplus
#ifndef _BACH_ENIGMA_BUFFER_H_
#define _BACH_ENIGMA_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT EngimaInfo : public AmazingEngine::RefBase
{
public:
    int type = -1;
    std::string text = "";
    AmazingEngine::Vec2Vector points;
};

class BACH_EXPORT EngimaBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<EngimaInfo>> m_EngimaInfo;
    float m_zoon_in_factor = 0;
    EngimaBuffer* _clone() const override
    {
        return nullptr;
    }
};

NAMESPACE_BACH_END

#endif //_BACH_ENIGMA_BUFFER_H_

#endif