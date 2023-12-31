#ifdef __cplusplus
#ifndef _BACH_BLOCK_GAN_BUFFER_H_
#define _BACH_BLOCK_GAN_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BlockGanInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector data;
    int width;
    int height;
    AmazingEngine::FloatVector matrix;
    int channel = 0;
    int type = 0;
    int faceCount;
    int count = 0;
    int64_t uid = 0;
};

class BACH_EXPORT BlockGanBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<BlockGanInfo>> m_blockGanInfos;
    int asyncTaskRet = 0;
    int algoRetCount = 0;
    int count = 0;
};

NAMESPACE_BACH_END
#endif
#endif