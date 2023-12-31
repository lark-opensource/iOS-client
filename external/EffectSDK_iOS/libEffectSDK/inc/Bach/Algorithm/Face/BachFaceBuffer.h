#ifdef __cplusplus
#ifndef BACH_FACE_BUFFER_H_
#define BACH_FACE_BUFFER_H_

#include "Gaia/AMGSharePtr.h"
#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class BACH_EXPORT AMGFaceAction
{
    EYE_BLINK = 0x00000002,       // eye blink, 眨眼
    MOUTH_AH = 0x00000004,        // mouth open, 嘴巴大张
    HEAD_YAW = 0x00000008,        // shake head, 摇头
    HEAD_PITCH = 0x00000010,      // nod, 点头
    BROW_JUMP = 0x00000020,       // wiggle eyebrow, 眉毛挑动
    MOUTH_POUT = 0x00000040,      // 嘴巴嘟嘴
    EYE_BLINK_LEFT = 0x00000080,  // 左眼眨眼
    EYE_BLINK_RIGHT = 0x00000100, // 左眼眨眼
    SIDE_NOD = 0x00000200,        // 一种特殊的表示赞同的摇头动作
};

class BACH_EXPORT FaceExtra : public AmazingEngine::RefBase
{
public:
    int eye_count = -1;     // 检测到眼睛数量
    int eyebrow_count = -1; // 检测到眉毛数量
    int lips_count = -1;    // 检测到嘴唇数量
    int iris_count = -1;    // 检测到虹膜数量

    AmazingEngine::Vec2Vector eye_left;      // 左眼关键点 22, 归一化后
    AmazingEngine::Vec2Vector eye_right;     // 右眼关键点 22, 归一化后
    AmazingEngine::Vec2Vector eyebrow_left;  // 左眉毛关键点 13, 归一化后
    AmazingEngine::Vec2Vector eyebrow_right; // 右眉毛关键点 13, 归一化后
    AmazingEngine::Vec2Vector lips;          // 嘴唇关键点 64, 归一化后
    AmazingEngine::Vec2Vector left_iris;     // 左虹膜关键点 20, 归一化后
    AmazingEngine::Vec2Vector right_iris;    // 右虹膜关键点 20, 归一化后
};

class BACH_EXPORT Face106 : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Rect rect;                    // 代表面部的矩形区域, 归一化后
    float score = 0;                             // 置信度
    AmazingEngine::Vec2Vector points_array;      // 人脸106关键点的数组, 归一化后
    AmazingEngine::FloatVector visibility_array; // 对应点的能见度，点未被遮挡1.0, 被遮挡0.0
    float yaw = 0.0;                             // 水平转角,真实度量的左负右正, 弧度
    float pitch = 0.0;                           // 俯仰角,真实度量的上负下正, 弧度
    float roll = 0.0;                            // 旋转角,真实度量的左负右正, 弧度
    float eye_dist = 0.0;                        // 两眼间距
    int ID = -1;                                 // faceID: 每个检测到的人脸拥有唯一的faceID.人脸跟踪丢失以后重新被检测到,会有一个新的faceID
    unsigned int action = 0;                     // 动作 FaceAction, 可能有多个的情况, 使用hasAction方法来判断
    unsigned int tracking_cnt = 0;               // 脸跟踪的帧数，用于判断是否是新出现的人脸，以及新人脸触发动作等；
};

class BACH_EXPORT FaceMouthMask : public AmazingEngine::RefBase
{
public:
    int face_mask_size = 0;               // face_mask_size
    AmazingEngine::UInt8Vector face_mask; // face_mask
    AmazingEngine::FloatVector warp_mat;  // warp mat data, size 2*3
    int id = -1;
};

class BACH_EXPORT FaceTeethMask : public AmazingEngine::RefBase
{
public:
    int face_mask_size = 0;               // face_mask_size
    AmazingEngine::UInt8Vector face_mask; // face_mask
    AmazingEngine::FloatVector warp_mat;  // warp mat data, size 2*3
    int id = -1;
};

class BACH_EXPORT FaceFaceMask : public AmazingEngine::RefBase
{
public:
    int face_mask_size = 0;               // face_mask_size
    AmazingEngine::UInt8Vector face_mask; // face_mask
    AmazingEngine::FloatVector warp_mat;  // warp mat data, size 2*3
    int id = -1;
};

class BACH_EXPORT FaceOcclusion : public AmazingEngine::RefBase
{
public:
    float prob = 0.f;
    int id = -1;
};

class BACH_EXPORT FaceBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<Face106>> m_faceBaseInfos;
    std::vector<AmazingEngine::SharePtr<FaceExtra>> m_faceExtraInfos;
    std::vector<AmazingEngine::SharePtr<FaceMouthMask>> m_faceMouthMask;
    std::vector<AmazingEngine::SharePtr<FaceTeethMask>> m_faceTeethMask;
    std::vector<AmazingEngine::SharePtr<FaceFaceMask>> m_faceFaceMask;
    std::vector<AmazingEngine::SharePtr<FaceOcclusion>> m_faceOcclusion;

    int m_width = 0;
    int m_height = 0;

private:
#if BEF_ALGORITHM_CONFIG_FACE && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    FaceBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END
#endif
#endif