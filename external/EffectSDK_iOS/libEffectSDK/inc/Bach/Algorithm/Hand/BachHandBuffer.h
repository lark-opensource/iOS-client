#ifdef __cplusplus
#ifndef BACH_HAND_BUFFER_H
#define BACH_HAND_BUFFER_H

#include <vector>

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

#pragma mark - BachHandAction

enum class AMGHandAction
{
    // Gesture define: 定义在handsdk
    //此处或handskd里action的定义有改动，需要修改HandInfo里的actionFromInt函数
    HEART_A = 0,
    HEART_B = 1,
    HEART_C = 2,
    HEART_D = 3,
    OK = 4,
    HAND_OPEN = 5,
    THUMB_UP = 6,
    THUMB_DOWN = 7,
    ROCK = 8,
    NAMASTE = 9,
    PLAM_UP = 10,
    FIST = 11,
    INDEX_FINGER_UP = 12,
    DOUBLE_FINGER_UP = 13,
    VICTORY = 14,
    BIG_V = 15,
    PHONECALL = 16,
    BEG = 17,
    THANKS = 18,
    UNKNOWN = 19,
    CABBAGE = 20,
    THREE = 21,
    FOUR = 22,
    PISTOL = 23,
    ROCK2 = 24,
    SWEAR = 25,
    HOLDFACE = 26,
    SALUTE = 27,
    SPREAD = 28,
    PRAY = 29,
    QIGONG = 30,
    SLIDE = 31,
    PALM_DOWN = 32,
    PISTOL2 = 33,
    NARUTO1 = 34,
    NARUTO2 = 35,
    NARUTO3 = 36,
    NARUTO4 = 37,
    NARUTO5 = 38,
    NARUTO7 = 39,
    NARUTO8 = 40,
    NARUTO9 = 41,
    NARUTO10 = 42,
    NARUTO11 = 43,
    NARUTO12 = 44,
    SPIDERMAN = 45,
    AVENGERS = 46,
    MAX_COUNT = 47,
    UNDETECT = 99, //没有检测
};

#pragma mark - HandInfo

class BACH_EXPORT HandInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;                                    ///< 手的id
    AmazingEngine::Rect rect;                       ///< 手部矩形框 默认: 0
    AMGHandAction action = AMGHandAction::UNDETECT; ///< 手部动作, 默认: 99
    float rot_angle = 0;                            ///< 手部旋转角度, 默认: 0
    float score = 0;                                ///< 手部检测置信度 默认: 0
    float rot_angle_bothhand = 0;                   ///< 双手夹角 默认: 0

    AmazingEngine::Vec2Vector key_points_xy;                   ///<描述KeyPoint里的xy
    AmazingEngine::UInt8Vector key_points_is_detect;           ///<描述KeyPoint里的is_detect
    AmazingEngine::Vec2Vector key_points_extension_xy;         ///<描述KeyPoint_extension里的xy
    AmazingEngine::UInt8Vector key_points_extension_is_detect; ///<描述KeyPoint_extension里的is_detect
    AmazingEngine::Vec3Vector key_points_3d;                   ///<xyz in kpt3d
    AmazingEngine::UInt8Vector key_points_3d_is_detect;        ///<is_detect in kpt3d
    unsigned int seq_action = 0;                               ///< 0 如果没有序列动作设置为0， 其他为有效值
    //SharePtr<Image> handSegMask = nullptr;      ///< 手掌分割mask 取值范围 0～255 默认: nullptr
    AmazingEngine::UInt8Vector segment_data; ///< 手掌分割mask 取值范围 0～255 默认: nullptr
    int segment_width = 0;                   ///< 手掌分割宽 默认: 0
    int segment_height = 0;                  ///< 手掌分割高 默认: 0
    float left_prob = 0.0;                   ///< Probability of left hand, default 0
    float scale = 1.0;                       ///< Scale of current hand, default 1.0
    AmazingEngine::Matrix4x4f ring_rt_trans; /// RTS matrix
    AmazingEngine::Matrix4x4f ring_r_trans;  /// model matrix
                                             //    UInt8Vector ring_mask_data; ///< 戒指mask 取值范围 0～255 默认: nullptr
    int ring_mask_width = 0;                 ///< 戒指mask宽 默认: 0
    int ring_mask_height = 0;                ///< 戒指mask高 默认: 0
    int render_mode = 0;                     ///< 戒指渲染模式 默认: 0
    float trans[12];
    int ringv2_render_mode = 0; ///< 是否显示戒指 0:不显示，1显示 默认：0
    float ringv2_trans[5 * 12];
    int hand_count_for_ring;                         ///< 戒指2.0专用，统计当前手是否可以挂载戒指
    AmazingEngine::UInt8Vector ringv2_occluder_mode; ///< //occluder渲染模式 0: 不做遮挡 1: 做遮挡（侧手） 2: 做遮挡（手正反面)
    AmazingEngine::Matrix4x4f thumb_r_trans;         /// 戒指2.0 thumb model matrix
    AmazingEngine::Matrix4x4f forefinger_r_trans;    /// 戒指2.0 forefinger model matrix
    AmazingEngine::Matrix4x4f middle_finger_r_trans; /// 戒指2.0 middle_finger model matrix
    AmazingEngine::Matrix4x4f ring_finger_r_trans;   /// 戒指2.0 ring_finger model matrix
    AmazingEngine::Matrix4x4f little_finger_r_trans; /// 戒指2.0 little_finger model matrix

    static AMGHandAction actionFromInteger(unsigned int i)
    {
        AMGHandAction ret = AMGHandAction::UNKNOWN;

        if (i == static_cast<int>(AMGHandAction::UNDETECT) || i < static_cast<int>(AMGHandAction::MAX_COUNT))
        {
            ret = static_cast<AMGHandAction>(i);
        }
        else
        {
            AEAssert_Return(0 && "Invalid Action", ret);
        }

        return ret;
    }
};

#pragma mark - HandMaskInfo

class BACH_EXPORT HandMaskInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector handMask;
    int mask_width;
    int mask_height;
};

#pragma mark - HandBuffer

class HandBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<HandInfo>> m_handInfos;
    AmazingEngine::SharePtr<HandMaskInfo> m_handMask;

private:
#if BEF_ALGORITHM_CONFIG_HAND_DETECT
    BachBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END
#endif

#endif