#ifdef __cplusplus
#ifndef BACH_HAIR_COLOR_BUFFER_H
#define BACH_HAIR_COLOR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HairResult : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect rect;
    float reflection = 0;
    int width = 0;
    int height = 0;
    AmazingEngine::UInt8Vector mask_data;
    int rotateType = 0;
    int realW = 0;
    int realH = 0;
    float mAlphal = 0.0f;
    float mAlphac = 0.0f;
    float mAlphas = 0.0f;
    AmazingEngine::Rect new_rect;
};

class BACH_EXPORT HairGerInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;                        // mask width
    int height = 0;                       // mask height
    int channelId = -1;                   // channel id: -1 is invalid, [0, 4] is valid.
    float reflector = 0;                  // reflector
    AmazingEngine::UInt8Vector mask_data; // mask data
};

class BACH_EXPORT HairColorBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<HairResult> m_hairInfo;
    std::vector<AmazingEngine::SharePtr<HairGerInfo>> hairGerInfos;
};

NAMESPACE_BACH_END
#endif
#endif