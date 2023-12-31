#ifdef __cplusplus
#ifndef BACH_SALIENCY_SEG_BUFFER_H
#define BACH_SALIENCY_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SaliencySegInfo : public AmazingEngine::RefBase
{
public:
    bool valid = false;
    float realW = 0;
    float realH = 0;
    float img_w = 0;
    float img_H = 0;
    float bboxcenterX = 0;
    float bboxcenterY = 0;
    float bboxwidth = 0;
    float bboxheight = 0;
    float bboxrotateAngle = 0;
    int modelIndex = -1;
    AmazingEngine::UInt8Vector alpha;
    AmazingEngine::UInt8Vector input;
};

NAMESPACE_BACH_END
#endif
#endif