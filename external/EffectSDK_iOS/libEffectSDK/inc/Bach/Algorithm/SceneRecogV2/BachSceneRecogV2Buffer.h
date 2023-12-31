#ifdef __cplusplus
#ifndef BACH_SCENE_RECOG_V2_BUFFER_H
#define BACH_SCENE_RECOG_V2_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SceneRecogV2Info : public AmazingEngine::RefBase
{
public:
    int id;
    float confidence = 0;
    float thres = 0;
    bool satisfied = false;
    std::string name;
};

class BACH_EXPORT SceneRecogV2Buffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SceneRecogV2Info>> m_SceneRecogInfo;
};

NAMESPACE_BACH_END
#endif
#endif