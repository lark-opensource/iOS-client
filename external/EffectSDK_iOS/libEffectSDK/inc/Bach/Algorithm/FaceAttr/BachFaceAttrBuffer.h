#ifdef __cplusplus
#ifndef BACH_FACE_ATTR_BUFFER_H
#define BACH_FACE_ATTR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class AMGFaceAttrGender
{
    UNKNOWN = -1,
    MALE = 0x00000001,
    FEMALE = 0x00000002,
};

enum class AMGFaceAttrExpression
{
    UNKNOWN = -1,
    ANGRY = 0,
    DISGUST = 1,
    FEAR = 2,
    HAPPY = 3,
    SAD = 4,
    SURPRISE = 5,
    NEUTRAL = 6,
    NUM_EXPRESSION = 7
};

class BACH_EXPORT FaceAttribute : public AmazingEngine::RefBase
{
public:
    int id = -1;
    //{AGE, GENDER}
    float age = 0;
    float boy_prob = 0;
    AMGFaceAttrGender gender = AMGFaceAttrGender::UNKNOWN;
    //{EXPRESSION, ATTRACTIVE, HAPPINESS}
    float attractive = 0;
    float happy_score = 0;
    AMGFaceAttrExpression exp_type = AMGFaceAttrExpression::UNKNOWN;
    AmazingEngine::FloatVector exp_probs;

    float real_face_prob = 0;
    float quality = 0;
};

class BACH_EXPORT FaceAttributeBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceAttribute>> m_faceAttributeInfos;
};

NAMESPACE_BACH_END
#endif
#endif