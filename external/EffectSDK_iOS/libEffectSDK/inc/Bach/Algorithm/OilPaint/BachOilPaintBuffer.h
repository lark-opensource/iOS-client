#ifdef __cplusplus
#ifndef BACH_OIL_PAINT_BUFFER_H
#define BACH_OIL_PAINT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT OilPaintInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector data;
    int width;
    int height;
};

class BACH_EXPORT OilPaintBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<OilPaintInfo> m_oilPaintInfo;
};

NAMESPACE_BACH_END
#endif
#endif