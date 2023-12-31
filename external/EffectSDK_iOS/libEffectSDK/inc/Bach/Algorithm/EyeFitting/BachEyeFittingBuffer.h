#ifdef __cplusplus
#ifndef BACH_EYE_FITTING_BUFFER_H
#define BACH_EYE_FITTING_BUFFER_H

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT EyeFittingInfo : public AmazingEngine::RefBase
{
public:
    int versionCode = -1; // version of 3d face mesh algorithm
    int faceId;
    AmazingEngine::Vec3Vector leftVertexes; //not include 3D landmark
    AmazingEngine::Vec3Vector leftLandmarks;
    AmazingEngine::Vec3Vector leftNormals;   // normals of 3d face mesh
    AmazingEngine::Vec3Vector leftTangents;  // tangents of 3d face mesh
    AmazingEngine::Vec3Vector leftBinormals; // bitangents of 3d face mesh
    AmazingEngine::Vector3f leftRvec;        // rotation vec of 3d face mesh
    AmazingEngine::Vector3f leftTvec;        // translation vec of 3d face mesh
    AmazingEngine::Matrix4x4f leftMVP;
    AmazingEngine::Matrix4x4f leftModel;

    AmazingEngine::Vec3Vector rightVertexes; //not include 3D landmark
    AmazingEngine::Vec3Vector rightLandmarks;
    AmazingEngine::Vec3Vector rightNormals;   // normals of 3d face mesh
    AmazingEngine::Vec3Vector rightTangents;  // tangents of 3d face mesh
    AmazingEngine::Vec3Vector rightBinormals; // bitangents of 3d face mesh
    AmazingEngine::Vector3f rightRvec;        // rotation vec of 3d face mesh
    AmazingEngine::Vector3f rightTvec;        // translation vec of 3d face mesh
    AmazingEngine::Matrix4x4f rightMVP;
    AmazingEngine::Matrix4x4f rightModel;

    AmazingEngine::Vec2Vector uvs;
    AmazingEngine::UInt16Vector triangles;
    AmazingEngine::FloatVector cameraParam;
    int numVertex = 0;      // = uv_count/2 = vertex_count/3
    int numTriangle = 0;    // = flist_count / 3
    int numLandmark = 0;    // = landmark_count / 3
    int numCameraParam = 0; // = param_count
    float fovy = 60.f;
};

NAMESPACE_BACH_END
#endif
#endif