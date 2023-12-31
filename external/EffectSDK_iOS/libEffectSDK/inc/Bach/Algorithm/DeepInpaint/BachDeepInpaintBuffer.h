#ifdef __cplusplus
#pragma once

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT DeepInpaintInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int image_width = 0;
    int image_height = 0;
    AmazingEngine::UInt8Vector image_data;
};

class BACH_EXPORT DeepInpaintBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<DeepInpaintInfo> m_deepInpaint;
};

NAMESPACE_BACH_END

#endif