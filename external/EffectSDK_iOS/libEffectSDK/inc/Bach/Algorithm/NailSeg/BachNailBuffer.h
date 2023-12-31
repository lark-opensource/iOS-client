#ifdef __cplusplus
#ifndef BACH_NAIL_BUFFER_H
#define BACH_NAIL_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT NailInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;  // the width of the mask
    int height = 0; // the height of the mask
    int nailRtNum = 0;
    AmazingEngine::UInt8Vector alpha; // nail mask
};

class BACH_EXPORT NailKeyPointInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect nailRect; // The boundingbox of nail
    AmazingEngine::Vec2Vector kpts;
    uint8_t cls = 0; // range: [0-5], default 0, 0 means unknown, 1 means thumb, 2 means index finger, 3 means middle finger, 4 means no name, 5 means little finger
};

class BACH_EXPORT NailBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<NailInfo> m_nailInfo;
    std::vector<AmazingEngine::SharePtr<NailKeyPointInfo>> m_nailKeyPointInfos;
};

NAMESPACE_BACH_END
#endif
#endif