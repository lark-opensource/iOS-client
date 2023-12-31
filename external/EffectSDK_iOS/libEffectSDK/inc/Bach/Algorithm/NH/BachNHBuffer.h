#ifdef __cplusplus
#ifndef _BACH_NH_BUFFER_H_
#define _BACH_NH_BUFFER_H_

#include "Bach/Algorithm/NH/BachNHType.h"
#include "Bach/Algorithm/NH/NHConstant.h"
#include "Bach/Base/BachAlgorithmBuffer.h"

NAMESPACE_BACH_BEGIN

/// @brief Nodehub image buffer
class BACH_EXPORT NHImageBuffer : public BachBuffer
{
public:
    NHImageBuffer()
        : BachBuffer(AlgorithmResultType::NH_IMAGE_BUFFER){};
    ~NHImageBuffer() override = default;
    /// clear data in the buffer
    void clear()
    {
        m_bufferSize = 0;
    }
    /// Actual size of current buffer
    size_t m_bufferSize = 0;
    /// buffer to store all nodehub images
    AmazingEngine::SharePtr<NHImage> m_images[NH::kNHMaxBufferSize];
};

/// @brief Nodehub image buffer
class BACH_EXPORT NHMulImageBuffer : public BachBuffer
{
public:
    NHMulImageBuffer()
        : BachBuffer(AlgorithmResultType::NH_MUL_IMAGE_BUFFER){};
    ~NHMulImageBuffer() override = default;
    /// clear data in the buffer
    void clear()
    {
        m_bufferSize = 0;
    }
    /// Actual size of current buffer
    size_t m_bufferSize = 0;
    /// buffer to store all nodehub images
    AmazingEngine::SharePtr<NHImageBuffer> m_imageBuffers[NH::kNHMaxBufferSize];
};

/// @brief Nodehub image transform buffer
class BACH_EXPORT NHImageTransformBuffer : public BachBuffer
{
public:
    NHImageTransformBuffer()
        : BachBuffer(AlgorithmResultType::NH_IMAGE_TFM_BUFFER){};
    ~NHImageTransformBuffer() override = default;
    /// clear data in the buffer
    void clear()
    {
        m_bufferSize = 0;
    }
    /// Actual size of current buffer
    size_t m_bufferSize = 0;
    /// buffer to store all image transforms
    AmazingEngine::SharePtr<NHImageTransform> m_tfms[NH::kNHMaxBufferSize];
};

/// @brief Nodehub image with transform buffer
class BACH_EXPORT NHImageWithTfmBuffer : public BachBuffer
{
public:
    NHImageWithTfmBuffer()
        : BachBuffer(AlgorithmResultType::NH_IMAGE_WITH_TFM_BUFFER){};
    ~NHImageWithTfmBuffer() override = default;
    /// clear data in the buffer
    void clear()
    {
        m_bufferSize = 0;
    }
    /// Actual size of current buffer
    size_t m_bufferSize = 0;
    /// buffer to store all nodehub images
    AmazingEngine::SharePtr<NHImage> m_images[NH::kNHMaxBufferSize];
    /// buffer to store all image transforms
    AmazingEngine::SharePtr<NHImageTransform> m_tfms[NH::kNHMaxBufferSize];
};

/// @brief Nodehub tensor info buffer
class BACH_EXPORT NHModelInfoBuffer : public BachBuffer
{
public:
    NHModelInfoBuffer()
        : BachBuffer(AlgorithmResultType::NH_MODEL_INFO){};
    ~NHModelInfoBuffer() override = default;
    /// actual size of current input tensor
    size_t m_inputTensorSize = 0;
    /// actual size of current output tensor
    size_t m_outputTensorSize = 0;
    /// clear data in the buffer
    void clear()
    {
        m_inputTensorSize = 0;
        m_outputTensorSize = 0;
    }
    /// buffer to store input tensor infos
    AmazingEngine::SharePtr<NHTensorInfo> m_inputTensorInfos[NH::kNHMaxBufferSize];
    /// buffer to store output tensor infos
    AmazingEngine::SharePtr<NHTensorInfo> m_outputTensorInfos[NH::kNHMaxBufferSize];
};

/// @brief nodehub tensor mid buffer, this buffer will be only used as intermediate result and will not be exposed to rtti API
class NHTensorBuffer : public BachBuffer
{
public:
    NHTensorBuffer()
        : BachBuffer(AlgorithmResultType::NH_TENSOR_BUFFER){};
    ~NHTensorBuffer() override = default;
    /// clear data in the buffer
    void clear()
    {
        for (size_t i = 0; i < m_bufferSize; ++i)
        {
            m_tensors[i].clear();
        }
        m_bufferSize = 0;
    }
    /// Actual size of current buffer
    size_t m_bufferSize = 0;
    /// buffer to store tensors
    NHTensorMap m_tensors[NH::kNHMaxBufferSize];
};

/// @brief nodehub classification buffer used for classfication output
class BACH_EXPORT NHClassificationBuffer : public BachBuffer
{
public:
    NHClassificationBuffer()
        : BachBuffer(AlgorithmResultType::NH_CLASSIFICATION_BUFFER){};
    ~NHClassificationBuffer() override = default;
    void clear()
    {
        for (size_t i = 0; i < m_bufferSize; ++i)
        {
            m_classificationInfos[i] = nullptr;
            m_classificationFeatures[i] = nullptr;
        }
        m_bufferSize = 0;
    }
    size_t m_bufferSize = 0;
    /// all classification results
    AmazingEngine::SharePtr<NHClassificationInfo> m_classificationInfos[NH::kNHMaxBufferSize];
    AmazingEngine::SharePtr<NHClassificationFeature> m_classificationFeatures[NH::kNHMaxBufferSize];
    /// label map
    AmazingEngine::StringVector m_labels;
    /// threshold
    AmazingEngine::FloatVector m_thresh;
};

NAMESPACE_BACH_END

#endif

#endif