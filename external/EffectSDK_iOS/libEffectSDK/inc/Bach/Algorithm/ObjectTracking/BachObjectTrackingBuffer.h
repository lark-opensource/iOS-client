#ifdef __cplusplus
#ifndef BACH_OBJECT_TRACKING_BUFFER_H
#define BACH_OBJECT_TRACKING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ObjectTrackingInfo : public AmazingEngine::RefBase
{
public:
    float centerX = 0.f;     /// Center X of bounding box
    float centerY = 0.f;     /// Center Y of bounding box
    float width = 0.f;       /// Width of bounding box
    float height = 0.f;      /// Height of bounding box
    float rotateAngle = 0.f; /// Clockwise rotate angle, in range [0, 360)
    float timestamp = 0.f;   /// Timestamp of tracked frame
    int trackingStatus = 0;  /// tracking status: 0->unavailable,1->tracked, 3->lost
};

#if BEF_ALGORITHM_CONFIG_OBJECT_TRACKING
uint32_t Interpolate(
    const ObjectTrackingInfo& infoEarlier,
    const ObjectTrackingInfo& infoLater,
    float targetStamp,
    ObjectTrackingInfo* outputInfo,
    bool enbaleExtrapolate);
#endif

class AMAZING_SDK_EXPORT ObjectTrackingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<ObjectTrackingInfo> m_objectTrackingInfo;
};

NAMESPACE_BACH_END

#endif

#endif