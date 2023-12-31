#ifdef __cplusplus
#ifndef _BACHMEGABUFFER_H_
#define _BACHMEGABUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT MegaClassicGanInfo : public AmazingEngine::RefBase
{
public:
    int valid = 1;
    int faceID = -1;
    int faceCount = 0;
    int width = 0;
    int height = 0;
    int chn = 3;
    int imageWidth = 0;
    int imageHeight = 0;
    int invalidDegree = 0;
    AmazingEngine::FloatVector matrix;
    AmazingEngine::Matrix4x4f affineMatrix;
    AmazingEngine::Matrix4x4f gpuMatrix;
    // BeautyGan 8UC4
    // LaughGan 8UC3
    // OldGan 8UC3
    // GenderGan 8UC4
    // BigGan 8UC3
    AmazingEngine::UInt8Vector imageData;
};

class BACH_EXPORT MegaClassicGanBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<MegaClassicGanInfo>> m_megaInfos;
};

NAMESPACE_BACH_END
#endif // _BACHMEGABUFFER_H_

#endif