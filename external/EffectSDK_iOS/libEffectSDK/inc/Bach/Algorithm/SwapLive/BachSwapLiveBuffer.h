#ifdef __cplusplus
#ifndef BACH_SWAP_LIVE_BUFFER_H
#define BACH_SWAP_LIVE_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SwapLiveInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;                    // output image
    int height = 0;                   // output image
    int image_height = 0;             // input image
    int image_width = 0;              // input image
    AmazingEngine::Matrix4x4f matrix; // affine transform
    AmazingEngine::UInt8Vector alpha; // output image data, RGBA
    int valid = 0;                    // status
};

class AMAZING_SDK_EXPORT SwapLiveBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SwapLiveInfo>> m_swapLiveInfos;
};

NAMESPACE_BACH_END
#endif
#endif