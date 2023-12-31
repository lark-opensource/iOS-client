#ifdef __cplusplus
#ifndef BACH_VIDEO_SR_BUFFER_H
#define BACH_VIDEO_SR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class Texture2D;

class BACH_EXPORT VideoSRTexture : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int textureId = 0;
    void* texturePtr = nullptr; // Texture2D

    void clear()
    {
        width = 0;
        height = 0;
        textureId = 0;
        texturePtr = nullptr;
    }
};

class BACH_EXPORT VideoSRBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<VideoSRTexture>> m_vsrInfos;
};

NAMESPACE_BACH_END
#endif
#endif