#ifdef __cplusplus
#ifndef BACH_SWAPPER_MEBUFFER_H
#define BACH_SWAPPER_MEBUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include <map>

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SwapperMeBaseInfo : public AmazingEngine::RefBase
{
public:
    int faceCount = 0;
    bool checkMode = false;
    int validCount = 0;
    AmazingEngine::Int32Vector checkResult;
    int width = 0;
    int height = 0;
    int channel = 0;
    int imageStride = 0;
    AmazingEngine::UInt8Vector imageData;
};

class BACH_EXPORT SwapperMeFaceInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec2Vector points_array;
};

class BACH_EXPORT SwapperMeBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<SwapperMeBaseInfo> m_baseInfo;
    std::map<int, AmazingEngine::SharePtr<SwapperMeFaceInfo>> m_faceInfo;
};

NAMESPACE_BACH_END
#endif // BACH_SWAPPER_MEBUFFER_H

#endif