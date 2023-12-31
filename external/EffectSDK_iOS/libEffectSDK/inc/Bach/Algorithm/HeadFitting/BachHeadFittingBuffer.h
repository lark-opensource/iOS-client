#ifdef __cplusplus
#ifndef BACH_HEAD_FITTING_BUFFER_H
#define BACH_HEAD_FITTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HeadFittingInfo : public AmazingEngine::RefBase
{
public:
    bool valid = false;
    int ID = -1; ///< 同一个人头的标志与facesdk中的id是一致的
    float pupil_dist = 0.0f;

    AmazingEngine::Vec3Vector vertexes;   ///< 顶点位置
    AmazingEngine::Vec3Vector normals;    ///< 模型空间下的法线
    AmazingEngine::Vec3Vector tangents;   ///< 模型空间下的切线
    AmazingEngine::Vec3Vector bitangents; ///< 模型空间下的副切线
    AmazingEngine::Vec2Vector uv;         ///< uv数组
    AmazingEngine::UInt16Vector triangle; ///< 组成mesh的的三角形索引

    AmazingEngine::Matrix4x4f mvp; ///< mvp = project * model * view， 4x4行的矩阵
    AmazingEngine::Matrix4x4f modelMatrix;
    AmazingEngine::Matrix4x4f viewMatrix;
    AmazingEngine::Matrix4x4f projectMatrix;
    AmazingEngine::Vec2Vector landmarks2D; ///< 输入的2d关键点
    AmazingEngine::Vec2Vector project2D;   ///< 3d关键点的2d投影点
};

class BACH_EXPORT HeadFittingBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<HeadFittingInfo>> m_headFittingInfos;
};

NAMESPACE_BACH_END
#endif // _BACHHEADFITTINGBUFFER_H_

#endif