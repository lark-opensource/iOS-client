#ifdef __cplusplus
#ifndef BACH_FACE_REENACT_BUFFER_H_
#define BACH_FACE_REENACT_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceReenactKeypointInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec2Vector keypoint;
};

class BACH_EXPORT FaceReenactKeypointBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceReenactKeypointInfo>> m_faceReenactKeypointInfos;
};

class BACH_EXPORT FaceReenactInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector rawData;
    int imageWidth = 0;
    int imageHeight = 0;
    int imageChannel = 0;
    int dataType = 0;
    AmazingEngine::Matrix4x4f mvp = AmazingEngine::Matrix4x4f::identity();
};

class BACH_EXPORT FaceReenactBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceReenactInfo>> m_faceReenactInfos;
};

NAMESPACE_BACH_END

#endif

#endif