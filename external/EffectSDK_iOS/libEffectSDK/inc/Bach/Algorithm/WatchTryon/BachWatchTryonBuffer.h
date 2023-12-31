#ifdef __cplusplus
#ifndef BACH_WATCH_TRYON_BUFFER_H
#define BACH_WATCH_TRYON_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT WatchTryonInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Matrix4x4f modelViewMatrix; // OpenGL Model View Matrix
    bool isLeft = false;
    AmazingEngine::Vec3Vector vertices;
    AmazingEngine::UInt16Vector triangles;
};

class BACH_EXPORT WatchTryonBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<WatchTryonInfo>> m_watchTryonInfos;
};

NAMESPACE_BACH_END
#endif

#endif