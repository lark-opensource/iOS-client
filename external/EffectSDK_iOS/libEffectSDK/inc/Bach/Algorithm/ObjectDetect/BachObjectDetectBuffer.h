#ifdef __cplusplus
#ifndef BACH_OBJECT_DETECT_BUFFER_H
#define BACH_OBJECT_DETECT_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class AMGObjectType
{
    DET_UNKNOW = 0x00000000, /// < 未知类型
    DET_RED = 0x00000001,
    DET_DUMPLINGS = 0x00000002, /// < 开启饺子检测
    DET_FEAST = 0x00000004,
};

class BACH_EXPORT ObjectDetectInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect rect; //bbox
    int Id = 1;
    float score;
    int objectType = 0;
};

class BACH_EXPORT ObjectDetectBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ObjectDetectInfo>> m_objectDetectInfos;
};

NAMESPACE_BACH_END
#endif
#endif