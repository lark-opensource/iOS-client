#ifdef __cplusplus
#ifndef BACH_TRACKING_AR_H
#define BACH_TRACKING_AR_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT TrackingArInfo : public AmazingEngine::RefBase
{
public:
    int status = 0;
    int accuracy = 0;
    int32_t objectId = 0;
    bool isMirrored = false;
    AmazingEngine::Matrix4x4f pose;
    AmazingEngine::Matrix4x4f projection;
    int planeImgWidth = 0;
    int planeImgHeight = 0;
    AmazingEngine::UInt8Vector planeImgData;
};

class BACH_EXPORT TrackingArBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<TrackingArInfo> m_trackingArInfo;
};

NAMESPACE_BACH_END

#endif

#endif