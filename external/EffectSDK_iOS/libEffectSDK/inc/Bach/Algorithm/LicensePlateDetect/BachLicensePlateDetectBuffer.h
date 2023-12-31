#ifdef __cplusplus
#ifndef BACH_LICENSE_PLATE_DETECT_BUFFER_H
#define BACH_LICENSE_PLATE_DETECT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT LicensePlateInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec2Vector points_array;
    int brand_id = -1;
};

class BACH_EXPORT LicensePlateDetectBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<LicensePlateInfo>> m_licensePlateInfo;
};

NAMESPACE_BACH_END
#endif
#endif