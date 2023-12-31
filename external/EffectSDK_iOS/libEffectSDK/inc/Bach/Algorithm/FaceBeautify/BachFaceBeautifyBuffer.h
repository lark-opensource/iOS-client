#ifdef __cplusplus
#ifndef BACH_FACE_BEAUTIFY_BUFFER_H
#define BACH_FACE_BEAUTIFY_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceBeautifyInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int faceID = -1;
    AmazingEngine::Rect region;
    AmazingEngine::UInt8Vector image;
};

class BACH_EXPORT FaceBeautifyBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceBeautifyInfo>> m_faceBeautifyInfos;

private:
#if BEF_ALGORITHM_CONFIG_FACE_BEAUTIFY && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    FaceBeautifyBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END

#endif
#endif