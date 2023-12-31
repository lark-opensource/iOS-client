#ifdef __cplusplus
#ifndef BACH_HAED_SEG_BUFFER_H
#define BACH_HAED_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HeadSegInfo : public AmazingEngine::RefBase
{
public:
    int face_id = -1;
    AmazingEngine::UInt8Vector alpha;
    int width = 0;
    int height = 0;
    int srcWidth = 0;
    int srcHeight = 0;
    int channel = 0;
    AmazingEngine::DoubleVector matrix;
    AmazingEngine::DoubleVector cameraMatrix;
    double xScale = 1.0f;
    double yScale = 1.0f;
};

class BACH_EXPORT HeadSegBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<HeadSegInfo>> m_headSegInfos;
};

NAMESPACE_BACH_END
#endif
#endif