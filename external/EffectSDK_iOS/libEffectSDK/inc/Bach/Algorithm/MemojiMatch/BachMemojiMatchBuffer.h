#ifdef __cplusplus
#ifndef BACH_MEMOJI_MATCH_BUFFER_H
#define BACH_MEMOJI_MATCH_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

//memoji scan status
typedef enum
{
    MemojiScanBegin = 0x01,
    MemojiScanNormal = 0x02,
    MemojiScanNoFace = 0x04,
    MemojiScanTooManyFace = 0x08,
    MemojiScanFaceNeedCorrect = 0x10,
    MemojiScanFaceChange = 0x20,
    MemojiScanComplete = 0x40,
    MemojiScanFaceUnknownError = 0x80,
    MemojiScanMergeEnd = 0x100,
} MemojiScanMessage;

class BACH_EXPORT MemojiMatchResourceInfo : public AmazingEngine::RefBase
{
public:
    std::string gender;
    std::string faceshape;
    std::string nose;
    std::string bang;

    std::string skinColor;

    std::string hair;
    std::string brow;
    std::string eye;
    std::string mouth;
    std::string glasses;
    std::string beard;

    AmazingEngine::Vector3f hairColor;
    AmazingEngine::Vector3f mouthColor;
};

class BACH_EXPORT MemojiMatchEmbeddingInfo : public AmazingEngine::RefBase
{
public:
    int lenthHair;
    int lenthGlasses;
    int lenthBeard;

    int lenthBrow;
    int lenthEye;
    int lenthMouth;
    int lenthColorSkin;
    int lenthColorMouth;
    int lenthColorHair;

    AmazingEngine::Vector3f hairColor;  //rgb
    AmazingEngine::Vector3f skinColor;  //hsv
    AmazingEngine::Vector3f mouthColor; //hsv

    bool hasGlasses;
    bool hasBeard;
    bool hasBang;

    AmazingEngine::Vector3f glasses;
    AmazingEngine::Vector3f beard;
    AmazingEngine::Vector3f hair;
    AmazingEngine::Vector3f mouth;
    AmazingEngine::Vector3f brow;
    AmazingEngine::Vector3f eye;

    int nose;
    int faceshape;

    float confidenceHair = 0.f;
    float confidenceEye = 0.f;
    float confidenceBrow = 0.f;
    float confidenceMouth = 0.f;
    float confidenceNose = 0.f;
    float confidenceFaceshape = 0.f;
};

class BACH_EXPORT MemojiMatchMessage : public AmazingEngine::RefBase
{
public:
    int status = 0;
    float percent;

    std::string gender;
    std::string faceshape;
    std::string nose;
    std::string bang;
    std::string skinColor;
    std::string hair;
    std::string brow;
    std::string eye;
    std::string mouth;
    std::string glasses;
    std::string beard;
    AmazingEngine::Vector3f hairColor;
    AmazingEngine::Vector3f mouthColor;
};

class BACH_EXPORT MemojiMatchBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<MemojiMatchResourceInfo> m_resource;
    AmazingEngine::SharePtr<MemojiMatchEmbeddingInfo> m_embedding;
    float m_boyProb;

    AmazingEngine::SharePtr<MemojiMatchBuffer> m_postResult;
    AmazingEngine::SharePtr<MemojiMatchMessage> m_message;
};

NAMESPACE_BACH_END
#endif
#endif