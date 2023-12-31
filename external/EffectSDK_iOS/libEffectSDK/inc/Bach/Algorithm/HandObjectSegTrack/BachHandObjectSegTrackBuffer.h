#ifdef __cplusplus
#ifndef BACH_HAND_OBJECT_SEG_TRACK_BUFFER_H
#define BACH_HAND_OBJECT_SEG_TRACK_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HandObjectSegInfo : public AmazingEngine::RefBase
{
public:
    int mask_width = 0;
    int mask_height = 0;
    AmazingEngine::UInt8Vector mask_data;
};

class BACH_EXPORT ObjectTrackInfo : public AmazingEngine::RefBase
{
public:
    // bounding box for the current frame without tracking history
    float centerX = 0.f;
    float centerY = 0.f;
    float width = 0.f;
    float height = 0.f;
    float rotateAngle = 0.f;
};

class BACH_EXPORT HandObjectSegTrackBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ObjectTrackInfo>> m_objectTrackBboxesInfos;
    AmazingEngine::SharePtr<HandObjectSegInfo> m_handObjectSegInfo;
};

NAMESPACE_BACH_END
#endif

#endif