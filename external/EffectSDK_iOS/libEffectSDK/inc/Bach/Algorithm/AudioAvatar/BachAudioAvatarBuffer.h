#ifdef __cplusplus
#ifndef BACH_AUDIO_AVATAR_BUFFER_H_
#define BACH_AUDIO_AVATAR_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT AudioAvatarInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector blendShape;
    AmazingEngine::Vector3f rotation;
    AmazingEngine::Vector3f translation;
};

class BACH_EXPORT AudioAvatarBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<AudioAvatarInfo> m_audioAvatarInfo;
};

NAMESPACE_BACH_END

#endif
#endif