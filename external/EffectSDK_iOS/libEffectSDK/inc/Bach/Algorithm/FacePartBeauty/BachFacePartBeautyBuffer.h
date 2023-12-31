#ifdef __cplusplus
#ifndef BACH_FACE_PART_BEAUTY_BUFFER_H
#define BACH_FACE_PART_BEAUTY_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN
class FaceBuffer;
class BlitConfig
{
public:
    unsigned char* m_imageData;
    int m_format;
    int m_imageWidth;
    int m_imageHeight;
};

class BACH_EXPORT FacePartBeautyInfo : public AmazingEngine::RefBase
{
public:
    int beautyId = -1;
    AmazingEngine::FloatVector features;
    AmazingEngine::Int32Vector beautyScore;
};

class BACH_EXPORT FacePartBeautyConfig : public AmazingEngine::RefBase
{
public:
    float distance = 0;
    int faceChange = -1;
    int together = -1;
    int faceNum0 = -1;
    int faceNum1 = -1;
    int faceNum = 0;
    bool sendEvent = false;
    int m_resultIndex = -1;
    int m_executeIndex = -1;
};

class BACH_EXPORT FacePartBeautyBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FacePartBeautyInfo>> m_facePartBeautyInfos;
    AmazingEngine::SharePtr<FacePartBeautyConfig> m_facePartBeautyConfig;

    FaceBuffer* m_faceBuffer = nullptr;
};

NAMESPACE_BACH_END
#endif
#endif