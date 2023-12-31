#ifdef __cplusplus
#ifndef BACH_JOINTS2_BUFFER_H
#define BACH_JOINTS2_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT JointV2Info : public AmazingEngine::RefBase
{
public:
    int number = 0;
    AmazingEngine::Vec2Vector key_points_xy;
    AmazingEngine::UInt8Vector key_points_detected;
};

class BACH_EXPORT Joints2Buffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<JointV2Info> m_jointV2Info;
};

NAMESPACE_BACH_END
#endif
#endif