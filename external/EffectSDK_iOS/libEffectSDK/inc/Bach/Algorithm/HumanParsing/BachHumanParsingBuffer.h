#ifdef __cplusplus
#ifndef BACH_HUMAN_PARSING_BUFFER_H
#define BACH_HUMAN_PARSING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT HumanParsingInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int image_width = 0;
    int image_height = 0;
    std::vector<AmazingEngine::UInt8Vector> image_datas;
};

class BACH_EXPORT HumanParsingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<HumanParsingInfo> m_humanParsing;
};

NAMESPACE_BACH_END
#endif
#endif