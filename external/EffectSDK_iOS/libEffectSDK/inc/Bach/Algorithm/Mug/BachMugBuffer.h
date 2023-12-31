#ifdef __cplusplus
#ifndef BACH_MUG_BUFFER_H
#define BACH_MUG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT MugResult : public AmazingEngine::RefBase
{
public:
    int ID = -1;                      //杯子跟踪的ID
    AmazingEngine::Rect mug_region;   //杯子的框
    AmazingEngine::Vec2Vector points; //杯子的四个顶点，当图片旋转时，可用来定位region 的方向
    float prob = 0;                   //检测到的杯子的概率；
};

class BACH_EXPORT MugBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<MugResult>> m_mugInfos;
};

NAMESPACE_BACH_END
#endif
#endif