//
// Created by hw on 2019-07-29.
//

#pragma once

#include <cstdlib>
#include <vector>
#include <algorithm>
#include <cassert>
#include "mammon_engine_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief Nd数组表示的音频数据
 * 可以按照stream[ch][spl]访问ch通道第spl个采样
 */
class MAMMON_EXPORT AudioStream {
public:
    using ChannelType = std::vector<float>;
    using DataType = std::vector<ChannelType>;

    AudioStream() = default;

    AudioStream(size_t num_channels, size_t num_samples_per_channel)
        : num_channels_(num_channels),
          num_samples_per_channel_(num_samples_per_channel),
          data_(num_channels, ChannelType(num_samples_per_channel)) {
    }

    /**
     * @brief 重设大小
     *
     * @param num_frame 帧数
     * @param num_chan 通道数
     */
    void resize(size_t num_frame, size_t num_chan) {
        for (auto& c : data_)
            c.resize(num_frame);

        if (num_chan < num_channels_) {
            data_.erase(data_.end() - num_channels_ + num_chan, data_.end());
        } else if (num_chan > num_channels_) {
            for (size_t i = 0; i < num_chan - num_channels_; i++)
                data_.emplace_back(num_frame);
        }

        num_channels_ = num_chan;
        num_samples_per_channel_ = num_frame;
    };

    void resize_channel(size_t num_chan) {
        if (num_chan == num_channels_)
            return;
        resize(num_samples_per_channel_, num_chan);
    }

    void resize_frame(size_t num_frame) {
        if (num_frame == num_samples_per_channel_)
            return;
        resize(num_frame, num_channels_);
    }

    /**
     * @brief 清零对象
     *
     */
    void zeros() {
        for (auto& c : data_) {
            std::fill(c.begin(), c.end(), 0.0f);
        }
    }

    /**
     * @brief 获得通道数
     *
     * @return size_t
     */
    size_t getNumChannels() const {
        return num_channels_;
    }

    /**
     * @brief 获取每个通道中音频的数量
     *
     * @return size_t
     */
    size_t getNumSamples() const {
        return num_samples_per_channel_;
    }

    const DataType& getData() const {
        return data_;
    }

    ChannelType& operator[](size_t channel) {
        return data_.at(channel);
    }

    const ChannelType& operator[](size_t channel) const {
        return data_.at(channel);
    };

    float const* getChannelPointer(size_t channel) const {
        return data_.at(channel).data();
    }

    float* getChannelPointer(size_t channel) {
        return data_.at(channel).data();
    }

    void swap(DataType& other_data) {
        if (other_data.size() < 1)
            return;

        num_channels_ = other_data.size();
        num_samples_per_channel_ = other_data[0].size();
        data_.swap(other_data);
    }

    std::vector<ChannelType>::iterator begin() {
        return data_.begin();
    }

    std::vector<ChannelType>::iterator end() {
        return data_.end();
    }

    std::vector<ChannelType>::const_iterator begin() const {
        return data_.begin();
    }

    std::vector<ChannelType>::const_iterator end() const {
        return data_.end();
    }

    void clear() {
        num_channels_ = 0;
        num_samples_per_channel_ = 0;
        data_.clear();
        data_.shrink_to_fit();
    }

private:
    size_t num_channels_;
    size_t num_samples_per_channel_;
    DataType data_;
};

MAMMON_ENGINE_NAMESPACE_END
