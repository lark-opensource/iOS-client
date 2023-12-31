#ifdef __cplusplus
#ifndef BACH_FACE_SMOOTH_CPU_BUFFER_H
#define BACH_FACE_SMOOTH_CPU_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceSmoothCPUInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    AmazingEngine::UInt8Vector image;
};

class BACH_EXPORT FaceSmoothCPUBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<FaceSmoothCPUInfo> m_faceSmoothCPUInfo;
};

NAMESPACE_BACH_END

#endif

#endif