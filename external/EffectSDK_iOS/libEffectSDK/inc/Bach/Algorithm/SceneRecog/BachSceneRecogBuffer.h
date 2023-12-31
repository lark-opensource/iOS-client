#ifdef __cplusplus
#ifndef BACH_SCENE_RECOG_BUFFER_H
#define BACH_SCENE_RECOG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SceneRecogInfo : public AmazingEngine::RefBase
{
public:
    float prob = 0;
    bool satisfied = false;
    std::string name;
};

class BACH_EXPORT SceneRecogBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SceneRecogInfo>> m_SceneRecogInfo;
    int m_choose = 0;

    void toMapBuffer(BachBuffer& buffer);
    void fromMapBuffer(const BachBuffer& buffer);
};

NAMESPACE_BACH_END

#endif

#endif