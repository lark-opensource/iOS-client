#ifdef __cplusplus
#ifndef BACH_SCENE_LIGHT_BUFFER_H
#define BACH_SCENE_LIGHT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SceneLightInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector SH_LIGHT_RGB;
};

class BACH_EXPORT SceneLightBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<SceneLightInfo> m_sceneLightInfo;
};

NAMESPACE_BACH_END
#endif
#endif