#ifdef __cplusplus
#ifndef _BACH_HDR_NET_BUFFER_H_
#define _BACH_HDR_NET_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HdrNetInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector ccm;                // size 9
    AmazingEngine::FloatVector ccm_bias;           // size 3
    AmazingEngine::FloatVector shifts;             // size 48
    AmazingEngine::FloatVector slopes;             // size 48
    AmazingEngine::FloatVector channel_mix_weight; // size 3
    float channel_mix_bias;
    AmazingEngine::FloatVector grid; // size [grid_width(16) * grid_height(16) * grid_depth(8) * 4] * 3;
};

class BACH_EXPORT HdrNetBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<HdrNetInfo> m_hdrNetInfo;
};

NAMESPACE_BACH_END
#endif
#endif