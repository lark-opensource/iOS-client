#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_INPUT_H_
#define _BACH_ALGORITHM_INPUT_H_

#include <unordered_map>
#include "Bach/BachCommon.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BachAlgorithmInput
{
public:
    BachInputType type() const
    {
        return mType;
    }

protected:
    BachAlgorithmInput(BachInputType type)
        : mType(type)
    {
    }

public:
    virtual ~BachAlgorithmInput() {}

private:
    const BachInputType mType;
};

class BACH_EXPORT BachImageBuffer : public BachAlgorithmInput
{
public:
    BachImageBuffer()
        : BachAlgorithmInput(BachInputType::IMAGE_BUFFER)
    {
    }
    int width = 0;                                       // 输入图片的宽度
    int height = 0;                                      // 输入图片的高度
    unsigned char* data = nullptr;                       // 输入图片的内存地址
    AEPixelFormat format;                                // 输入图片的格式，支持RGBA,BRGA, RGB, BGR格式
    AERotateMode rotateMode = AERotateMode::ROTATE_CW_0; // 旋转方向
    AEFlipMode flipMode = AEFlipMode::FLIP_NONE;         // 镜像方向
    double timestamp = 0.0;                              // 当前帧的时间戳，单位秒
};

class BACH_EXPORT BachImageBufferWithData : public BachAlgorithmInput
{
public:
    BachImageBufferWithData()
        : BachAlgorithmInput(BachInputType::IMAGE_DATA_BUFFER)
    {
    }
    BachImageBuffer* imageBuffer = nullptr;
    void* data = nullptr;
    uint32_t length = 0;
};

class BACH_EXPORT BachInputArrayBuffer : public BachAlgorithmInput
{
public:
    BachInputArrayBuffer()
        : BachAlgorithmInput(BachInputType::ARRAY_BUFFER)
    {
    }
    void* data = nullptr;
    int length = 0; //length of array
    int stride = 1; // size of item in array
};

class BACH_EXPORT BachFeatureData
{
public:
    char* featureData; //特征的二进制数据
    int featureLen;    //特征的长度
};

using BachMultiInputMap = std::unordered_map<std::string, const BachAlgorithmInput&>;

class BACH_EXPORT BachMultiInput : public BachAlgorithmInput
{
public:
    BachMultiInput()
        : BachAlgorithmInput(BachInputType::MULTI_INPUT)
    {
    }
    BachMultiInput(const BachMultiInputMap& inputs)
        : BachAlgorithmInput(BachInputType::MULTI_INPUT)
        , inputs(inputs)
    {
    }
    BachMultiInputMap inputs;
};

NAMESPACE_BACH_END

#endif

#endif