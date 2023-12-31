#ifdef __cplusplus
#ifndef BACH_CAR_SEG_BUFFER_H
#define BACH_CAR_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT CarSegInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector bounding_box;
    AmazingEngine::FloatVector brand_bounding_box;

    bool is_new = false;
    bool valid_landmarks = false;
    bool valid_segmentation = false;

    int direction = -1;
    int car_Id = -1;
    int color = 0;
    int seg_width = 0;
    int seg_height = 0;
    int left_seg_border = 0;
    int up_seg_border = 0;

    float car_prob = 0.0f;
    AmazingEngine::Vec2Vector landmarks;

    AmazingEngine::UInt8Vector seg_data;
};

class BACH_EXPORT CarSegConfig : public AmazingEngine::RefBase
{
public:
    unsigned int alphaTextureId = -1;
    int rotateType = 0;
    int realW = 0;
    int realH = 0;
};

class BACH_EXPORT CarSegBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<CarSegInfo>> m_carSegInfo;
    AmazingEngine::SharePtr<CarSegConfig> m_carSegConfig;
};

NAMESPACE_BACH_END
#endif
#endif