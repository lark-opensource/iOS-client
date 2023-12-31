//
// Created by william on 2019-03-18.
//

#pragma once
#include "ae_defs.h"
#include "ae_audio_buffer.h"

namespace mammon
{
/**
 * @brief 用于管理一维交织数组形式的音频数据
 */
class MAMMON_EXPORT AudioBufferInterleave1D : public AudioBuffer 
{
public:
    friend class Bus;
    AudioBufferInterleave1D();

    /**
     * 创建一个 AudioBufferInterleave1D
     *
     * @param interleave_array 指向交织的音频数据的指针
     * @param num_channel 通道数
     * @param num_sample_per_channel 采样个数，要求每个通道的采样个数是一致的
     */
    AudioBufferInterleave1D(float* interleave_array, int num_channel, int num_sample_per_channel);

    /**
     * 拷贝构造一个 AudioBufferInterleave1D
     */
    AudioBufferInterleave1D(const AudioBufferInterleave1D& buffer);

    /**
     * 赋值拷贝一个 AudioBuffer2D
     */
    AudioBufferInterleave1D&operator=(const AudioBufferInterleave1D& buffer);

    virtual ~AudioBufferInterleave1D() = default;

    /**
     * 返回一个用于读数据的指针，它的行为和原生指针几乎一致
     *
     * 不同的声道将返回不同的指针，因此你需要指明通道的下标
     *
     * @see AudioBufferPointer
     *
     * @param channel 通道数
     * @return AudioBufferPointer 读指针
     */
    virtual const ReadPointer getReadPointer(int channel) const override;

    /**
     * 返回一个用于写数据的指针，它的行为和原生指针几乎一致
     *
     * 不同的声道将返回不同的指针，因此你需要指明通道的下标
     *
     * @note 当给定的通道下标一致时，getWritePointer 与 getReadPointer 返回的指针指向同一片内存，
     *
     * 因此可以直接使用读指针来同时进行读和写的操作
     *
     * @see AudioBufferPointer
     *
     * @param channel 通道数
     * @return AudioBufferPointer 写指针
     */
    virtual WritePointer getWritePointer(int channel) const override;

private:
    float* interleave_array_;
};
}

