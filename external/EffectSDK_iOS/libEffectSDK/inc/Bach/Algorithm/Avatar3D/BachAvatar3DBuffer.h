#ifdef __cplusplus
#ifndef _BACH_AVATAR_3D_BUFFER_H_
#define _BACH_AVATAR_3D_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT Avatar3DInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::QuatVector quaternion; //quaternion of 24 joints
    AmazingEngine::Vector3f root;         //root coord
    AmazingEngine::FloatVector betas;     //shape coefficient
    AmazingEngine::Int8Vector valid;      //1 presents a joint is detected
    bool is_detected = false;             //true presents a man is detected
    float focal_length = 0.0f;            //camera param
    AmazingEngine::Vec3Vector joints;     //3D position of 24 joints in world coordinate
    float imageWidth = 720.f;             //image width when run the algorithm
    float imageHeight = 1280.f;           //image height when run the algorithm
    int tracking_id = -1;                 // tracking id
};

class BACH_EXPORT Avatar3DBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<Avatar3DInfo>> m_infos;
    bool m_tracking = false;
    bool m_isExecuted = false;
};

NAMESPACE_BACH_END
#endif

#endif