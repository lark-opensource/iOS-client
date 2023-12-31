#ifdef __cplusplus
#ifndef BACH_CAT_FACE_BUFFER_H
#define BACH_CAT_FACE_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

//deprecated，lab已经废弃，建议已使用的模块迁移到petface模块
class BACH_EXPORT CatFace : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect rect;               // 代表面部的矩形区域, 归一化后
    float score = 0;                        // 猫脸检测的置信度
    AmazingEngine::Vec2Vector points_array; // 猫脸82关键点的数组, 归一化后
    float yaw = 0;                          // 水平转角,真实度量的左负右正, 弧度
    float pitch = 0;                        // 俯仰角,真实度量的上负下正, 弧度
    float roll = 0;                         // 旋转角,真实度量的左负右正, 弧度
    int ID = -1;                            // faceID: 每个检测到的人脸拥有唯一的faceID.人脸跟踪丢失以后重新被检测到,会有一个新的faceID
    unsigned int action = 0;                // 脸部动作，目前只包括：左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，
                                            // action 的第1，2，3位分别编码：
                                            // 左眼睛睁闭，右眼睛睁闭，嘴巴睁闭，其余位数预留
};

class BACH_EXPORT CatFaceBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<CatFace>> m_catFaceInfos;
    CatFaceBuffer* _clone() const override
    {
        return nullptr;
    }
};

NAMESPACE_BACH_END
#endif
#endif