//
// Created by william on 2019-03-17.
//

#pragma once
#include "ae_audio_buffer.h"
#include "ae_defs.h"

namespace mammon {
    /**
     * @brief 用于管理二维数组形式的音频数据
     *
     */
    class MAMMON_EXPORT AudioBuffer2D : public AudioBuffer {
    public:
        friend class Bus;
        AudioBuffer2D();

        /**
         * 创建一个 AudioBuffer2D
         *
         *
         * @param data_to_refer_to 指向音频数据的指针数组
         * @param num_channels 通道数
         * @param num_samples_per_channel 采样个数，要求每个通道的采样个数是一致的
         *
         * @note AudioBuffer2D 只管理内存，不会做任何的拷贝和复制，并且不会做内存越界的检查，
         * 因此当 num_channels 或者 num_samples_per_channel 设置错误时，程序发生越界访问
         *
         */
        AudioBuffer2D(float** data_to_refer_to, int num_channels, int num_samples_per_channel);

        /**
         * 拷贝构造一个 AudioBuffer2D
         */
        AudioBuffer2D(const AudioBuffer2D& buffer);

        /**
         * 赋值拷贝一个 AudioBuffer2D
         */
        AudioBuffer2D& operator=(const AudioBuffer2D& buffer);
        virtual ~AudioBuffer2D() = default;

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
        const ReadPointer getReadPointer(int channel) const override;

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
        WritePointer getWritePointer(int channel) const override;

    private:
        float** channels_;
        float* prealloc_channles_[32] = {nullptr};
    };
}  // namespace mammon
