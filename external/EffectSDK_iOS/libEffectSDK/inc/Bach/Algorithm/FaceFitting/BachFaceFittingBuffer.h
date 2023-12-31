#ifdef __cplusplus
#ifndef BACH_FACE_FITTING_BUFFER_H
#define BACH_FACE_FITTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceMeshInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;                           // face id returned by smash face detect algorithm
    AmazingEngine::Vec3Vector vertexes;    // vertexes of 3d face mesh
    AmazingEngine::Vec3Vector landmarks;   // landmarks of 3d face mesh
    AmazingEngine::FloatVector param;      // paramters of 3d face algorithm
    AmazingEngine::Vec3Vector normals;     // normals of 3d face mesh
    AmazingEngine::Vec3Vector tangents;    // tangents of 3d face mesh
    AmazingEngine::Vec3Vector bitangents;  // bitangents of 3d face mesh
    AmazingEngine::Matrix4x4f mvp;         // mvp of 3d face mesh
    AmazingEngine::Matrix4x4f modelMatrix; // model of 3d face mesh
    AmazingEngine::Vector3f rvec;          // rotation vec of 3d face mesh
    AmazingEngine::Vector3f tvec;          // translation vec of 3d face mesh
    float scale = 1.0f;                    // small image mode
};

class BACH_EXPORT FaceMeshConfig : public AmazingEngine::RefBase
{
public:
    int version_code = -1;                          // version of 3d face mesh algorithm
    AmazingEngine::Vec2Vector uvs;                  // std uvs of 3d face mesh algorithm
    AmazingEngine::UInt16Vector flist;              // std triangles of 3d face mesh algorithm
    AmazingEngine::UInt16Vector landmark_triangles; // std landmark triangles of 3d face mesh algorithm

    int num_vertex = 0;            // = uv_count/2 = vertex_count/3
    int num_flist = 0;             // = flist_count / 3
    int num_landmark_triangle = 0; // = landmark_triangle_count / 2
    int mum_landmark = 0;          // = landmark_count / 3
    int num_param = 0;             // = param_count
};

class BACH_EXPORT FaceFittingBuffer : public BachBuffer
{
public:
    bool m_useNormal = false;
    std::vector<AmazingEngine::SharePtr<FaceMeshInfo>> m_faceMeshInfos;
    AmazingEngine::SharePtr<FaceMeshConfig> m_faceMeshConfig;
    std::vector<AmazingEngine::SharePtr<FaceMeshInfo>> m_faceMeshInfos1256;
    AmazingEngine::SharePtr<FaceMeshConfig> m_faceMeshConfig1256;

private:
#if BEF_ALGORITHM_CONFIG_FACE_FITTING && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    FaceFittingBuffer* _clone() const override;
#endif
};
NAMESPACE_BACH_END
#endif
#endif