#ifdef __cplusplus
#ifndef BACH_HAND_TV_BUFFER_H
#define BACH_HAND_TV_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

#define AE_HAND_TV_KEY_POINT_NUM 22
#define AE_HAND_TV_KEY_POINT_NUM_EXTENSION 2

#pragma mark - BachHandTVAction

enum class AMGHandTVAction
{
    // Gesture define in file HandTV_API.h from smash-sdk
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
    UNDETECT = 99, //没有检测
};

#pragma mark - HandTVInfo

class BACH_EXPORT HandTVInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;                                        ///< hand id
    int person_id = -1;                                 ///< person id(legal id: >=0，otherwise: -1)
    int hand_side;                                      ///< left or right hand
    AmazingEngine::Rect rect;                           ///< hand bbx default: 0
    AMGHandTVAction action = AMGHandTVAction::UNDETECT; ///< hand action, default: 99
    float rot_angle = 0;                                ///< hand rotation angle, default: 0
    float score = 0;                                    ///< hand detect confidence, default: 0
    float action_score;                                 ///< gesture detect confidence, default: 0
    float rot_angle_bothhand = 0;                       ///< angle between two hand, default: 0

    AmazingEngine::Vec2Vector key_points_xy;                   ///< KeyPoint: xy
    AmazingEngine::UInt8Vector key_points_is_detect;           ///< KeyPoint: is_detect
    AmazingEngine::Vec2Vector key_points_extension_xy;         ///< KeyPoint_extension: xy
    AmazingEngine::UInt8Vector key_points_extension_is_detect; ///< KeyPoint_extension: is_detect
    AmazingEngine::UInt8Vector segment_data;                   ///< hand segmentation mask 0~255,  default: nullptr
    int segment_width = 0;                                     ///< hand segmentation mask width,  default: 0
    int segment_height = 0;                                    ///< hand segmentation mask height, default: 0

    static AMGHandTVAction actionFromInteger(unsigned int i)
    {
        AMGHandTVAction ret = AMGHandTVAction::UNKNOWN;

        if (i == 99 || i <= 19)
        {
            ret = static_cast<AMGHandTVAction>(i);
        }
        else
        {
            AEAssert_Return(0 && "Invalid Action", ret);
        }

        return ret;
    }
};

#pragma mark - HandTVBuffer

class BACH_EXPORT HandTVBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<HandTVInfo>> m_handInfos;
};

NAMESPACE_BACH_END
#endif
#endif