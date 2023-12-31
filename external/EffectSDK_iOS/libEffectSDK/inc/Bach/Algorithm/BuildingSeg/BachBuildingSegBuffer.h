#ifdef __cplusplus
#ifndef BACH_BUILDING_SEG_BUFFER_H
#define BACH_BUILDING_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BuildingSegInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;                        //the width of the mask
    int height = 0;                       //the height of the mask
    float shiftX = 0.0f;                  //camera shift X
    float shiftY = 0.0f;                  //camera shift Y
    AmazingEngine::UInt8Vector mask_data; //mask
};

class BACH_EXPORT BuildingSegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<BuildingSegInfo> m_buildingSegInfo;
};

NAMESPACE_BACH_END
#endif
#endif