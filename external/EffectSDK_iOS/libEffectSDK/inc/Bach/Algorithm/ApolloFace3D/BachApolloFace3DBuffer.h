#ifdef __cplusplus
#ifndef _BACH_APOLLO_FACE3D_BUFFER_
#define _BACH_APOLLO_FACE3D_BUFFER_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ApolloFace3DInfoClass : public AmazingEngine::RefBase
{
public:
    int ID = -1;
    AmazingEngine::Vec3Vector vertexes;
    AmazingEngine::Vec3Vector normals;
    AmazingEngine::Vec4Vector tangents;
    AmazingEngine::Vec2Vector uvs;
    AmazingEngine::UInt16Vector triangles;
    AmazingEngine::Vec3Vector landmarks3d;
    AmazingEngine::FloatVector params;
    AmazingEngine::FloatVector mvp;
};

class BACH_EXPORT ApolloFace3DBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ApolloFace3DInfoClass>> m_face3DInfos;
};

NAMESPACE_BACH_END
#endif
#endif