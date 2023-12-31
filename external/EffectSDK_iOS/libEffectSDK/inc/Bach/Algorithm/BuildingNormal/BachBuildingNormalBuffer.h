#ifdef __cplusplus
#ifndef BACH_BUILDING_NORMAL_BUFFER_H
#define BACH_BUILDING_NORMAL_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BuildingNormalInfo : public AmazingEngine::RefBase
{
public:
    int numBoxes = 0; // num of hang boxes
    float hangBoxesCenterX;
    float hangBoxesCenterY;
    float hangBoxesSizeWidth;
    float hangBoxesSizeHeight;
    float hangBoxesAngle;
    AmazingEngine::FloatVector hangBoxesNormal;
    int objectCls = -1;   // -1 is errorness, 0 is building, 1 is lantern
    float polygonCenterX; // 2D center point
    float polygonCenterY;

    // P1 x0y0          P2 x1y1
    // P4 x3y3          P3 x2y2
    AmazingEngine::Vec2Vector polygon;
};

NAMESPACE_BACH_END
#endif
#endif