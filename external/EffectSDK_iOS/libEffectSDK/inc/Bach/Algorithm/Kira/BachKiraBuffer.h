#ifdef __cplusplus
#ifndef BACH_KIRA_BUFFER_H
#define BACH_KIRA_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

struct KiraPoint;
NAMESPACE_BACH_BEGIN

class BACH_EXPORT KiraResult : public AmazingEngine::RefBase
{
public:
    AmazingEngine::Vec3Vector points; //max: 4096
    int width = 128;
    int height = 64;
    int channels = 4;
    AmazingEngine::UInt8Vector mask;
    int pointNum = 0;
};

class BACH_EXPORT KiraBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<KiraResult> m_kiraInfo;
};

NAMESPACE_BACH_END
#endif
#endif