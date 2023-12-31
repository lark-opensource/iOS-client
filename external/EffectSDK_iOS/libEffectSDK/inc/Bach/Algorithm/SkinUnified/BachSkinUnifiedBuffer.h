#ifdef __cplusplus
#ifndef BACH_SKIN_UNIFIED_BUFFER_H
#define BACH_SKIN_UNIFIED_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class AMAZING_SDK_EXPORT SkinUnifiedInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int image_width = 0;
    int image_height = 0;
    AmazingEngine::UInt8Vector image;
    AmazingEngine::FloatVector matrix;
};

class AMAZING_SDK_EXPORT SkinUnifiedBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SkinUnifiedInfo>> m_skinUnifiedInfos;

private:
#if BEF_ALGORITHM_CONFIG_SKIN_UNIFIED && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    SkinUnifiedBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END

#endif
#endif