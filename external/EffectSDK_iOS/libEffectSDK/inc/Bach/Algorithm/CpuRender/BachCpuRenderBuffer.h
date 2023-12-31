#ifdef __cplusplus

#ifndef _BACH_CPU_RENDER_BUFFER_H_
#define _BACH_CPU_RENDER_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

#define CREATE_CPURENDER_INFO(outputIndex)                                                         \
    CpuRenderInfo* cpuRenderInfo_##outputIndex = nullptr;                                          \
    {                                                                                              \
        auto* cpuRenderBuffer = static_cast<CpuRenderBuffer*>(container->getOrCreateBuffer(        \
            nodeContext.resultId, getResultType(outputIndex), outputIndex));                       \
        auto& cpuRenderInfo = cpuRenderBuffer->m_cpuRender;                                        \
        if (!cpuRenderInfo.isNull() && cpuRenderInfo->m_outputIndex == outputIndex)                \
        {                                                                                          \
            cpuRenderInfo_##outputIndex = cpuRenderInfo.get();                                     \
        }                                                                                          \
        if (cpuRenderInfo_##outputIndex == nullptr)                                                \
        {                                                                                          \
            cpuRenderInfo_##outputIndex = new CpuRenderInfo;                                       \
            if (cpuRenderInfo_##outputIndex == nullptr)                                            \
            {                                                                                      \
                AELOGE(AE_ALGORITHM_TAG, "cpuRenderInfo[%d] is null", outputIndex);                \
                return BACH_FAILED;                                                                \
            }                                                                                      \
            cpuRenderInfo = cpuRenderInfo_##outputIndex;                                           \
        }                                                                                          \
        const int bufferSize = input->getWidth() * input->getHeight() * 4;                         \
        cpuRenderInfo_##outputIndex->width = input->getWidth();                                    \
        cpuRenderInfo_##outputIndex->height = input->getHeight();                                  \
        cpuRenderInfo_##outputIndex->m_outputIndex = outputIndex;                                  \
        cpuRenderInfo_##outputIndex->image_data.resize(bufferSize);                                \
        memcpy(cpuRenderInfo_##outputIndex->image_data.getBuffer(), input->getData(), bufferSize); \
    }

class AMAZING_EXPORT CpuRenderInfo : public AmazingEngine::RefBase
{

public:
    int width = 0;
    int height = 0;
    int m_outputIndex = -1;
    AmazingEngine::UInt8Vector image_data;
};

class AMAZING_SDK_EXPORT CpuRenderBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<CpuRenderInfo> m_cpuRender;
};

NAMESPACE_BACH_END

#endif //_BACH_CPU_RENDER_BUFFER_H_

#endif