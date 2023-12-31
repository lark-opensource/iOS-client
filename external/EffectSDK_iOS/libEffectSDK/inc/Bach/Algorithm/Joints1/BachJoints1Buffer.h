#ifdef __cplusplus
#ifndef BACH_JOINTS1_BUFFER_H
#define BACH_JOINTS1_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT JointInfo : public AmazingEngine::RefBase
{
public:
    int jointNum = 0;
    AmazingEngine::Vec2Vector key_points_xy;
    AmazingEngine::FloatVector key_points_r;
    AmazingEngine::UInt32Vector key_points_type;
};

class BACH_EXPORT Joints1Buffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<JointInfo> m_jointInfo;
};

NAMESPACE_BACH_END
#endif
#endif