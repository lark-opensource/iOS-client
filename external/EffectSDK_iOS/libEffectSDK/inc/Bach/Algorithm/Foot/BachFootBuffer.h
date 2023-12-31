#ifdef __cplusplus
#ifndef BACH_FOOT_BUFFER_H
#define BACH_FOOT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FootInfo : public AmazingEngine::RefBase
{
public:
    int footId = -1;
    AmazingEngine::Rect box; //foot box
    float left_prob = 0;     //prob of left foot
    float foot_prob = 0;     //prob of foot
    bool is_left;
    AmazingEngine::Vec2Vector key_points_xy;         //keypoints,66
    AmazingEngine::UInt8Vector key_points_is_detect; //keypoints is detect
    AmazingEngine::Vector3f shankOrient;             //leg orient
    bool shankVisible;
    AmazingEngine::UInt8Vector segment; //segment mask
    AmazingEngine::UInt8Vector segmentBro;
    AmazingEngine::Rect segment_box;    //segment box
    AmazingEngine::Matrix4x4f transMat; // RTS matrix
    AmazingEngine::Matrix4x4f u_Model;  // model matrix
};

class BACH_EXPORT FootMaskInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector firstFootMask;
    AmazingEngine::UInt8Vector secondFootMask;
    int mask_width;
    int mask_height;
    AmazingEngine::UInt8Vector trousersMask;
    AmazingEngine::UInt8Vector legMask;
    AmazingEngine::UInt8Vector footMask;
};

class BACH_EXPORT FootBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FootInfo>> m_footInfos;
    AmazingEngine::SharePtr<FootMaskInfo> m_footMask;
};

NAMESPACE_BACH_END
#endif
#endif