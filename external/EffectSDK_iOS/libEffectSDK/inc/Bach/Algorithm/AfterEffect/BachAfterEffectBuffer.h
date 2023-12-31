#ifdef __cplusplus
#ifndef _BACH_AFTER_EFFECT_BUFFER_H_
#define _BACH_AFTER_EFFECT_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT AEScoreInfo : public AmazingEngine::RefBase
{
public:
    int time;
    float score = 0;
    float face_score = 0;
    float quality_score = 0;
    float sharepness_score = 0;
    float meaningless_score = 0;
    float portrait_score = 0;
};

class BACH_EXPORT AfterEffectBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<AEScoreInfo>> m_scores; // kAfterEffectFuncCalcScore
};

NAMESPACE_BACH_END
#endif
#endif