#ifdef __cplusplus
#ifndef BACH_RGBD2MESH_BUFFER_H
#define BACH_RGBD2MESH_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN
class BACH_EXPORT Rgbd2MeshInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector texture; //rgba
    int width;                          // texture width
    int height;                         // texture height

    AmazingEngine::FloatVector vertex; // 3d x y z u v ...
    int v_len;                         // vertex array size
    AmazingEngine::UInt16Vector indices;
    int i_len;        // indices array size
    float mesh_score; // 3d quality score
};

class BACH_EXPORT Rgbd2MeshBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<Rgbd2MeshInfo> m_rgbd2MeshInfo;
};

NAMESPACE_BACH_END
#endif
#endif