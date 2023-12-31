#ifdef __cplusplus
#ifndef BACH_SCENE_RECOG_V3_BUFFER_H
#define BACH_SCENE_RECOG_V3_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SceneRecogV3Info : public AmazingEngine::RefBase
{
public:
    int id = 0;             //class id
    float confidence = 0.0; //class confidence
    float thres = 0.0;      //class thres
    bool satisfied = false;
    std::string name;
};

class BACH_EXPORT SceneRecogV3Buffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SceneRecogV3Info>> m_sceneRecogV3Info;
    AmazingEngine::FloatVector c3_feature;
};

NAMESPACE_BACH_END
#endif
#endif