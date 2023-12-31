#ifdef __cplusplus

#ifndef _BACH_FACE_PET_DETECT_BUFFER_H_
#define _BACH_FACE_PET_DETECT_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class AMGFacePetType
{
    CAT = 1,     ///< 猫
    DOG = 2,     ///< 狗
    HUMAN = 3,   ///< 人（目前不支持）
    OTHERS = 99, ///< 其它宠物类型（目前不支持）
};

class BACH_EXPORT FacePetInfo : public AmazingEngine::RefBase
{
public:
    AMGFacePetType face_pet_type = AMGFacePetType::CAT;
    AmazingEngine::Rect rect;
    float score = 0;
    AmazingEngine::Vec2Vector points_array;
    float yaw = 0;
    float pitch = 0;
    float roll = 0;
    int Id = -1;
    unsigned int action = 0; //脸部动作，目前只包括：左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，< action 的第1，2，3位分别编码： 左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，其余位数预留
    int ear_type = 0;        //0表示耳朵是竖的，1表示耳朵是垂着的
};

class BACH_EXPORT FacePetDetectBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FacePetInfo>> m_facePetInfos;
};

NAMESPACE_BACH_END
#endif

#endif