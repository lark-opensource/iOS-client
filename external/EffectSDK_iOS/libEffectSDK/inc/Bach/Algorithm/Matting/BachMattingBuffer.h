#ifdef __cplusplus
#ifndef BACH_MATTING_BUFFER_H
#define BACH_MATTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN
#pragma mark - BachSnapShotResult
namespace Compute
{
class Texture;
};
enum class AMGSnapShotRet
{
    Disable = 0,
    FalseState = 1,
    TrueState = 2,
};

class BACH_EXPORT MattingResult : public AmazingEngine::RefBase
{
    friend class MattingBuffer;

public:
    MattingResult();
    ~MattingResult();
    int width = 0;
    int height = 0;
    AmazingEngine::UInt8Vector mask_data;
    AMGSnapShotRet take_this = AMGSnapShotRet::Disable;
    AmazingEngine::Rect resultRect;
    // gpu texture
    unsigned int textureID();
    AmazingEngine::UInt8Vector maskData();
    class Impl;
    Impl* internal_data;
    void* nativeBuffer();
};

class BACH_EXPORT MattingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<MattingResult> m_bgInfo;
    virtual BachBuffer* _clone() const override
    {
        if (m_bgInfo.isNull())
        {
            return nullptr;
        }
        MattingBuffer* buffer = new MattingBuffer();
        buffer->m_bgInfo = new MattingResult();
        MattingResult* src = static_cast<MattingResult*>(m_bgInfo.get());
        MattingResult* dst = static_cast<MattingResult*>(buffer->m_bgInfo.get());
        dst->width = src->width;
        dst->height = src->height;
        dst->mask_data = src->maskData().copy();
        dst->take_this = src->take_this;
        dst->resultRect = src->resultRect;
        return buffer;
    }
};

NAMESPACE_BACH_END
#endif

#endif