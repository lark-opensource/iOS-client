#ifdef __cplusplus
#ifndef BACH_SKELETON_POSE_3D_BUFER_H
#define BACH_SKELETON_POSE_3D_BUFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SkeletonPose3DInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec3Vector pose3d;               //[Bingo_kKeyPointCount] 21
    AmazingEngine::Vec3Vector fused3d;              //[Bingo_kKeyPointCount] 21
    AmazingEngine::Vec2Vector skeleton2d_points;    //[KeyPointNUM]; 18
    AmazingEngine::Int8Vector skeleton2d_detecteds; //[KeyPointNUM]; 18
    bool detected = false;
};

class BACH_EXPORT SkeletonPose3DBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SkeletonPose3DInfo>> m_infos;
};

NAMESPACE_BACH_END
#endif

#endif