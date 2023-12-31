#ifdef __cplusplus
#ifndef BACH_HAVATAR_BUFFER_H
#define BACH_HAVATAR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Bach/Algorithm/Hand/BachHandBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HAvatarInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;                                    ///< 手的id
    AmazingEngine::Rect rect;                       ///< 手部矩形框 默认: 0
    AMGHandAction action = AMGHandAction::UNDETECT; ///< 手部动作 默认: 99
    float leftProb = 0.0;                           ///< 左手概率 默认: 0
    float handProb = 0.0;                           ///< 为手概率 默认： 0
    AmazingEngine::Vector3f root;                   ///< 3D手根节点位置 默认: 0
    AmazingEngine::Vec2Vector kpt2d;                ///< 2D关键点归一化后的像素坐标 默认: 0
    AmazingEngine::Vec3Vector kpt3d;                ///< 3D关键点位置 默认: 0
    AmazingEngine::QuatVector quaternion;           ///< 3D手各关节的旋转四元数 默认: 单位四元数
};

class BACH_EXPORT HAvatarBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<HAvatarInfo>> m_havatarInfos;
};

NAMESPACE_BACH_END
#endif

#endif