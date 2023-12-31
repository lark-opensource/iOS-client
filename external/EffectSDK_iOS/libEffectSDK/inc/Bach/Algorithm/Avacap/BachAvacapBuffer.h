#ifdef __cplusplus
#ifndef _BACH_AVACAP_BUFFER_h
#define _BACH_AVACAP_BUFFER_h

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT AvacapInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector alpha;
    AmazingEngine::FloatVector beta;
    AmazingEngine::Matrix4x4f mv;
    AmazingEngine::Matrix4x4f mvp;
    AmazingEngine::Matrix3x3f rot;
    AmazingEngine::Vector3f trans;
    AmazingEngine::Vec3Vector meshv;
    AmazingEngine::Vector3f meshTriFace;
    AmazingEngine::Matrix4x4f proj;
    int idLen;
    int expLen;
    int vertexLen;
    int faceLen;
    int faceCount;
    int faceID;
};

class BACH_EXPORT AvacapBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<AvacapInfo>> m_avacapInfos;
};

NAMESPACE_BACH_END

#endif /* BachAvacapBuffer_h */

#endif