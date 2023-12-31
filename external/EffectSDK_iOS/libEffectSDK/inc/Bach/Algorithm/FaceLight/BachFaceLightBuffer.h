#ifdef __cplusplus
#ifndef BACH_FACE_LIGHT_BUFFER_H
#define BACH_FACE_LIGHT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceLightInfo : public AmazingEngine::RefBase
{
public:
    int face_id = 0;
    bool has_lighting = false;
    AmazingEngine::FloatVector SH_Light_RGB;
};

class BACH_EXPORT FaceLightBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceLightInfo>> m_faceLightInfos;
};

NAMESPACE_BACH_END
#endif
#endif