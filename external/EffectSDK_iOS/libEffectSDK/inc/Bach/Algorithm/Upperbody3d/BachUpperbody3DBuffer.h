#ifdef __cplusplus
#ifndef BACH_UPPER_BODY_3D_BUFFER
#define BACH_UPPER_BODY_3D_BUFFER

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT Upperbody3DInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec3Vector pose3d; //Bingo_kKeyPointCount 12
};

class BACH_EXPORT Upperbody3DBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<Upperbody3DInfo>> m_infos; //AI_MAX_SKELETON_NUM 2
};

NAMESPACE_BACH_END
#endif
#endif