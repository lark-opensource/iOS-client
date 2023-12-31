#ifdef __cplusplus
#ifndef BACH_EAR_SEG_BUFFER_H
#define BACH_EAR_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT EarSegInfo : public AmazingEngine::RefBase
{
public:
    int faceID;
    int maskWidth;
    int maskHeight;
    int maskChannel;
    float yaw;

    AmazingEngine::UInt8Vector alpha0;
    AmazingEngine::UInt8Vector alpha1;
    AmazingEngine::DoubleVector matrix0;
    AmazingEngine::DoubleVector matrix1;

    AmazingEngine::Int32Vector cls;
    AmazingEngine::FloatVector centerX;
    AmazingEngine::FloatVector centerY;
    AmazingEngine::Int8Vector earWidth;
    AmazingEngine::Int8Vector earHeight;
};

class BACH_EXPORT EarSegBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<EarSegInfo>> m_earSegInfos;
};

NAMESPACE_BACH_END
#endif
#endif