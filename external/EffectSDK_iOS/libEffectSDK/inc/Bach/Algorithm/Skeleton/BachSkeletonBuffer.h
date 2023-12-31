#ifdef __cplusplus
#ifndef BACH_SKELETON_BUFFER_H
#define BACH_SKELETON_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SkeletonInfo : public AmazingEngine::RefBase
{
public:
    int ID = -1;
    AmazingEngine::Rect rect;
    AmazingEngine::Vec2Vector key_points_xy;
    AmazingEngine::UInt8Vector key_points_detected;
    AmazingEngine::FloatVector key_points_score;
    int orientation = 0;
};

class BACH_EXPORT SkeletonBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<SkeletonInfo>> m_skeletonInfos;
    bool m_isExecuted = false;
    int m_sourceWidth;
    int m_sourceHeight;
    std::vector<float> m_backboneFeats;
    int m_backbonFeatDim = 0;
    std::vector<float> m_heatmaps;
    int m_heatmapDim = 0;
    bool m_isBackboneFeatsValid = false;

private:
#if BEF_ALGORITHM_CONFIG_SKELETON && BEF_FEATURE_CONFIG_ALGORITHM_CACHE
    SkeletonBuffer* _clone() const override;
#endif
};

NAMESPACE_BACH_END
#endif
#endif