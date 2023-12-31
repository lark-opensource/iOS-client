#ifdef __cplusplus
#ifndef BACH_GAZE_ESTIMATION_BUFFER_H
#define BACH_GAZE_ESTIMATION_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT GazeEstimationInfo : public AmazingEngine::RefBase
{
public:
    uint32_t face_id;
    bool valid;
    AmazingEngine::FloatVector head_r;      //3
    AmazingEngine::FloatVector head_t;      //3
    AmazingEngine::FloatVector leye_pos;    // 3
    AmazingEngine::FloatVector reye_pos;    // 3
    AmazingEngine::FloatVector leye_gaze;   // 3
    AmazingEngine::FloatVector reye_gaze;   // 3
    AmazingEngine::FloatVector mid_gaze;    // 3
    AmazingEngine::FloatVector leye_pos2d;  // 3
    AmazingEngine::FloatVector reye_pos2d;  // 3
    AmazingEngine::FloatVector leye_gaze2d; // 3
    AmazingEngine::FloatVector reye_gaze2d; // 2 2d point on screen of gaze end point
};

class BACH_EXPORT GazeEstimationBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<GazeEstimationInfo>> m_gazeEstimationInfos;
};

NAMESPACE_BACH_END
#endif
#endif