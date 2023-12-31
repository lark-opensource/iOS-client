#ifdef __cplusplus
#ifndef BACH_PICTURE_AR_BUFFER_H
#define BACH_PICTURE_AR_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT PictureArInfo : public AmazingEngine::RefBase
{
public:
    void reset();

    AmazingEngine::Vec2Vector sourcePoints;
    AmazingEngine::Vec2Vector targetPoints;

    AmazingEngine::Vec2Vector mapMatch;
    bool mapMatchIsValid = false;

    AmazingEngine::Vec2Vector anchorMatch;
    bool anchorMatchIsValid = false;

    int frameScore = 0;
    bool frameScoreIsValid = false;

    float rotation = 0;
    bool rotationIsValid = false;

    float scale = 0.f;
    bool scaleIsValid = false;

    AmazingEngine::Matrix3x3f affineMat;
    bool affineMatIsValid = false;

    bool isDetcting = false;
};

class BACH_EXPORT PictureArBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<PictureArInfo> m_LuaResult = nullptr;
};

NAMESPACE_BACH_END
#endif
#endif