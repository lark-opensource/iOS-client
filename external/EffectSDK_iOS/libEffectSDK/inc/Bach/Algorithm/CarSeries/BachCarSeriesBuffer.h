#ifdef __cplusplus
//
// Created by 毛永波 on 2021/4/9.
//

#ifndef _BACH_CAR_SERIES_BUFFER_H_
#define _BACH_CAR_SERIES_BUFFER_H_
#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_BACH_BEGIN


class BACH_EXPORT CarSeriesInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector box;   //bounding box
    int carId = -1;                   //object ID
    bool isNew = false;               //if new car
    float carProb = 0.0f;             //car score 0-1

    int seriesId = -1;                //car series ID
    float carSeriesProb = 0.0f;      //car series score
    std::string seriesName = "";      //car series name
    int age = 3;                      //age
};

class BACH_EXPORT CarSeriesBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<CarSeriesInfo>> m_carSeries;
};

NAMESPACE_BACH_END

#endif


#endif