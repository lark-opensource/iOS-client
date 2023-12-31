//
// Created by william on 2019-03-18.
//

#pragma once
#include <stdint.h>
#include "ae_defs.h"
namespace mammon {
    /**
     * @brief 用于管理音频数据，方便对音频数据读取的基类
     *
     * 有两种音频数据，二维数组形式和交织形式，分别由 AudioBuffer2D 和 AudioBufferInterleave1D 支持
     *
     * @see AudioBuffer2D
     * @see AudioBufferInterleave1D
     */
    class MAMMON_EXPORT AudioBuffer {
    public:
        class MAMMON_EXPORT AudioBufferPointer {
        public:
            AudioBufferPointer(float* array, int step, int start_index);

            float& operator[](int i);

            const float& operator[](int i) const;
            float operator*() const;
            // post
            const AudioBufferPointer operator++(int x);
            // prefix
            AudioBufferPointer& operator++();

            AudioBufferPointer operator+(const long int add) const;
            AudioBufferPointer& operator+=(const long int add);

            bool operator==(const AudioBufferPointer& other) const;
            bool operator!=(const AudioBufferPointer& other) const;
            //        bool operator<(const AudioBufferPointer &other) const;
            //        bool operator>(const AudioBufferPointer &other) const;
            //        bool operator<=(const AudioBufferPointer &other) const;
            //        bool operator>=(const AudioBufferPointer &other) const;

        private:
            float* array_;
            int step_;
        };

        typedef const AudioBufferPointer ReadPointer;
        typedef AudioBufferPointer WritePointer;

    public:
        friend class Effect;
        /**
         * 创建一个 AudioBuffer
         *
         * 你需要告知要管理的音频数据的通道数以及采样个数
         *
         * @param num_channels 通道数
         * @param num_samples_per_channel 采样个数
         */
        AudioBuffer(int num_channels, int num_samples_per_channel);

        /**
         * 拷贝构造一个 AudioBuffer，拷贝的信息包括通道数和采样个数
         * @param buffer buffer
         */
        AudioBuffer(const AudioBuffer& buffer);

        /**
         * 赋值构造一个 AudioBuffer，拷贝的信息包括通道数和采样个数
         * @param buffer buffer
         */
        AudioBuffer& operator=(const AudioBuffer& buffer);
        virtual ~AudioBuffer() = default;

        /**
         * 返回通道数
         *
         * @return 通道数
         */
        int getNumChannels() const;
        /**
         * 返回每个通道的采样个数
         *
         * @return 采样个数
         */
        int getNumSamples() const;

        void setNumSamples(uint32_t num_samples);

        /**
         * 返回一个用于读数据的指针，它的行为和原生指针几乎一致
         *
         * 不同的声道将返回不同的指针，因此你需要指明通道的下标
         *
         * @see AudioBufferPointer
         * @see AudioBuffer2D
         * @see AudioBufferInterleave1D
         *
         * @param channel 第几个通道
         * @return AudioBufferPointer 读指针
         */
        virtual const ReadPointer getReadPointer(int channel) const = 0;

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
         * @see AudioBuffer2D
         * @see AudioBufferInterleave1D
         *
         * @param channel 指定要返回的通道
         * @return AudioBufferPointer 写指针
         */
        virtual WritePointer getWritePointer(int channel) const = 0;

        /**
         * 判断是否相等
         */
        bool operator==(const AudioBuffer& other) const;

        /**
         * 判断是否不等
         */
        bool operator!=(const AudioBuffer& other) const;

    protected:
        int num_channels_;
        int num_samples_per_channel_;
    };
}  // namespace mammon
