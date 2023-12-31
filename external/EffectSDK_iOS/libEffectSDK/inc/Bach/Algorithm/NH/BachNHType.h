#ifdef __cplusplus
#ifndef _BACH_NH_TYPE_H_
#define _BACH_NH_TYPE_H_

#include "Bach/Base/BachBaseDefine.h"
#if BEF_ALGORITHM_CONFIG_COMPUTE_ENGINE
#endif

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

namespace BYTENN
{
class Tensor;
}
NAMESPACE_BACH_BEGIN

/// @brief Nodehub image with RTTI
class BACH_EXPORT NHImage : public AmazingEngine::RefBase
{
public:
    /// raw data buffer
    AmazingEngine::UInt8Vector rawData;
    /// width of image [pixel]
    int imageWidth = 0;
    /// height of image [pixel]
    int imageHeight = 0;
    /// number of image channels
    int imageChannel = 0;
    /// type of data, see "mobilecv2/core/hal/interface.h: #define CV_8U" for detailed definition
    int dataType = 0;
    /// step of image
    int step = 0;
};

/// @brief Nodehub image with transform
class BACH_EXPORT NHImageTransform : public AmazingEngine::RefBase
{
public:
    /// 2d Affine transform(homogeneous) point from target frame to source frame
    AmazingEngine::Matrix3x3f tfmTgtFromSrc = AmazingEngine::Matrix3x3f::identity();
    /// source image width [pixel]
    int srcImageWidth = 0;
    /// source image height [pixel]
    int srcImageHeight = 0;
    /// target image width [pixel]
    int tgtImageWidth = 0;
    /// target image height [pixel]
    int tgtImageHeight = 0;
    /// return opengl mvp matrix from target frame to source frame
    AmazingEngine::Matrix4x4f getTfmTgtFromSrcNDC() const;
};

/// #brief Wrapper of std::vector<BYTENN::Tensor> but support tensor raw data memory management
class NHTensorMap
{
public:
    NHTensorMap();
    /**
     * Constructor
     * @param tensors tensor to copy
     * @param clone whether deep clone the tensor raw data
     */
    NHTensorMap(const std::vector<BYTENN::Tensor>& tensors, bool clone);
    ~NHTensorMap();
    /**
     * Clone tensors (raw data will be deep copied)
     * @param tensors tensor to clone
     */
    void clone(const std::vector<BYTENN::Tensor>& tensors);
    /**
     * Copy tensors (raw data will be shallow copied)
     * @param tensors tensor to copy
     */
    void update(const std::vector<BYTENN::Tensor>& tensors);
    /**
     * Clear tensors
     */
    void clear();
    /**
     * Resize tensor buffer
     * @param size resize size
     */
    void resize(size_t size);
    /**
     * @return Raw std::vector tensor
     */
    const std::vector<BYTENN::Tensor>& tensors() const { return m_tensors; }
    /**
     * @return Raw std::vector tensor
     */
    std::vector<BYTENN::Tensor>& tensors() { return m_tensors; }
    /**
     * If true, tensor map will release buffer.
     */
    void setOwn(bool flag) { m_isClone = flag; }
    bool isOwn() { return m_isClone; }

private:
    /// whether raw data is deep copied
    bool m_isClone = false;
    /// raw BYTENN::tensor
    std::vector<BYTENN::Tensor> m_tensors;
};

/// @brief Nodehub inference model info with RTTI
class BACH_EXPORT NHTensorInfo : public AmazingEngine::RefBase
{
public:
    /// layer name
    std::string name = "";
    /// same as ByteNNBasicType.h DataFormat
    int dataFormat = 0;
    /// same as ByteNNBasicType.h DataType
    int dataType;
    /// batch size
    int batch = 1;
    /// tensor height
    int height = 1;
    /// tensor width
    int width = 1;
    /// tensor channel
    int channel = 1;
    /// bits to shift for quantized model
    int fraction = 0;
};

/// @brief This is a raw buffer class with memory management(allocation / release)
class NHRawBuffer
{
public:
    NHRawBuffer() {}

    /**
     * @brief Copy constructor
     * @param buffer Buffer to copy
     */
    NHRawBuffer(const NHRawBuffer& buffer)
    {
        copyFrom(buffer.data(), buffer.size());
    }

    /**
     * @brief Move constructor
     * @param buffer buffer to move
     */
    NHRawBuffer(NHRawBuffer&& buffer)
    {
        m_data = buffer.m_data;
        m_dataSize = buffer.m_dataSize;
        m_bufferSize = buffer.m_bufferSize;
        buffer.m_data = nullptr;
        buffer.m_dataSize = 0;
        buffer.m_bufferSize = 0;
    }

    /**
     * @brief Construct a new Nodehub Raw Buffer object
     * @param size Byte size of this buffer
     */
    NHRawBuffer(size_t size)
    {
        m_data = malloc(size);
        m_bufferSize = size;
        m_dataSize = 0;
    }
    /**
     * @brief Construct a new Nodehub Raw Buffer object with specified size and data to store
     * @param dataToStore Pointer to data to copy
     * @param size Byte size of this piece of data
     */
    NHRawBuffer(const void* dataToStore, size_t size)
    {
        m_data = malloc(size);
        memcpy(m_data, dataToStore, size);
        m_bufferSize = size;
        m_dataSize = size;
    }

    /**
     * @brief Update the data buffer with new data, if size of new piece of data is larger than original one, it will trigger memory reallocation, otherwise memory keep as is and will not be released until this object gets destructed.
     * 
     * @param dataToUpdate Pointer of data to update
     * @param size 
     */
    void copyFrom(const void* dataToUpdate, size_t size)
    {
        if (dataToUpdate == nullptr || size == 0)
        {
            return;
        }

        if (m_bufferSize < size)
        {
            free(m_data);
            m_data = malloc(size);
            m_bufferSize = size;
        }
        memcpy(m_data, dataToUpdate, size);
        m_dataSize = size;
    }

    /**
     * @brief Destroy the Nodehub Raw Buffer object
     */
    ~NHRawBuffer()
    {
        if (m_data != nullptr)
        {
            free(m_data);
            m_data = nullptr;
        }
    }

    /**
     * @return void* Pointer of data
     */
    void* data() { return m_data; }
    /**
     * @return void* Pointer of data
     */
    const void* data() const { return m_data; }

    /**
     * @return size_t Size of data in bytes
     */
    size_t size() const { return m_dataSize; }

    /**
     * @return size_t Capacity of buffer in bytes
     */
    size_t capacity() const { return m_bufferSize; }

private:
    /// Actual data size in byte
    size_t m_dataSize = 0;
    /// Buffer size in byte
    size_t m_bufferSize = 0;
    /// Pointer of data
    void* m_data = nullptr;
};
/// Nodehub classification output
class BACH_EXPORT NHClassificationInfo : public AmazingEngine::RefBase
{
public:
    /// class id, starts from 0, -1 is invalid
    AmazingEngine::Int32Vector id;
    /// confidence, range is [0.0f, 1.0f], -1.0f is invalid confidence
    AmazingEngine::FloatVector confidence;
    /// whether confidence exceeds threshold
    AmazingEngine::Int8Vector exceedThresh;
    /// number of classes
    int numClasses = 0;
};

/// Nodehub classification output
class BACH_EXPORT NHClassificationFeature : public AmazingEngine::RefBase
{
public:
    /// features, the output feature of basemodel (BACKBONE)
    AmazingEngine::FloatVector features;
};

NAMESPACE_BACH_END

#endif

#endif