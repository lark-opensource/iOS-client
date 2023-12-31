#ifdef __cplusplus
#ifndef BACH_FACE_GAN_BUFFER_H
#define BACH_FACE_GAN_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class AMGFaceGanObjectType
{
    UNDEFINED,
    LEFT_DOUBLE,
    LEFT_PLUMP,
    LEFT_DOUBLE_PLUMP,
    RIGHT_DOUBLE,
    RIGHT_PLUMP,
    RIGHT_DOUBLE_PLUMP,
    LEFT_CLASS_ONLY,
    RIGHT_CLASS_ONLY
};

class BACH_EXPORT FaceGanInfo : public AmazingEngine::RefBase
{
public:
    int faceID = -1;
    AmazingEngine::UInt8Vector data;
    float doubleRate = 0; // 单眼为双眼皮的概率 (0.0 - 1.0, 未执行时为0.0)
    float plumpRate = 0;  // 单眼为双眼皮的概率 (0.0 - 1.0, 未执行时为0.0)
    AMGFaceGanObjectType objectType = AMGFaceGanObjectType::UNDEFINED;
    int outWidth = 0;
    int outHeight = 0;
    int outChannel = 0;
    AmazingEngine::FloatVector matrix;
    AmazingEngine::Matrix4x4f affineMatrix;
    AmazingEngine::Rect rect;
    int image_width = 0;
    int image_height = 0;
};

class BACH_EXPORT FaceGanBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceGanInfo>> m_faceGanInfos;
};

NAMESPACE_BACH_END
#endif
#endif