
#pragma once
#ifndef AUDIO_EFFECT_AE_WAVEFORM_VISUALIZER_H
#define AUDIO_EFFECT_AE_WAVEFORM_VISUALIZER_H
#include <cstdint>
#include <cstddef>
#include <memory>
#include <vector>
#include <tuple>
#include "ae_defs.h"

#if !defined(ssize_t)
#define ssize_t signed long long
#endif

namespace mammon {

/*!
 * @brief 波形显示选项
 */
enum WaveformVisualizerOption {
    SampleMean = 0x01u,        ///< 显示的是波形的平均值
    SampleMax = 0x00u,         ///< 显示的是波形的最大值
    MultiChannelMean = 0x02u,  ///< 通道之间取平均值绘制
    MultiChannelMax = 0x04u,   ///< 通道之间取最大值绘制
    kNormalizeMinMax = 0x08u,  ///< 对结果做MinMax标准化
    Default = MultiChannelMean | SampleMax
};

enum WaveformVisualizerError {
    kSuccess = 0,   ///< 调用成功
    kErrChannelNum = -1,    ///< 传入了错误的通道数（<=0?)
    kNullBuffer = -2,   ///< 传入的buffer是null
    kInvalidInterleavedSize = -3,   ///< 交错数组的大小不能被通道数整除
    kUnsupported = -4   ///< 不支持的功能
};

using WaveformVisualizerOptions = uint8_t;

/*!
 * @brief 波形可视化
 * 将传入的波形数据转换成适合显示的绘图点
 *
 * Example:
 * @code
 * WaveformVisualizer v {2};
 * unique_ptr<float[]> points;
 * WaveformVisualizerError err;
 * 
 * tie(points, err) = v.getPoints(buffer, 44100, 200);
 * unique_ptr<float[]> points = v.getPoints(buffer, 44100, 200);
 *
 * float* temp_buf[1];
 * WaveformVisualizer v1 {1};
 * temp_buf[0] = points.get();
 * unique_ptr<float[]> less_points;
 * 
 * tie(less_points, err) = v1.getPoints(temp_buf, 200, 50);
 * 
 * @endcode
 */
class MAMMON_EXPORT WaveformVisualizer final {
public:
    /*!
     * 波形可视化类
     * @param num_channel 通道数
     * @param options 图形选项
     */
    explicit WaveformVisualizer(size_t num_channel,
                                WaveformVisualizerOptions options = WaveformVisualizerOption::Default)
            : m_num_channel(num_channel), m_options(options) {
    }

    ~WaveformVisualizer() = default;

    /*!
     * @brief 计算波形绘制点
     * 多通道二维数组
     *
     * @tparam SType 采样类型：支持float，int32
     * @param buffer 原始波形采样数据
     * @param num_frame 帧数 = buffer第二维长度
     * @param num_points 预计显示的点数
     * @return 大小为num_points的数组
     */
    template <typename SType>
    std::tuple<std::unique_ptr<SType[]>, WaveformVisualizerError>
    getPoints(const SType* const* buffer, size_t num_frame, size_t num_points);

    /*!
     * @brief 计算波形绘制点
     * 多通道交错数组
     * 会进行交错数组转换，进行一次数据拷贝
     *
     * @tparam SType 采样类型：支持float，int32
     * @param buffer 原始波形采样数据（交错）
     * @param num_samples 采样数 = buffer长度
     * @param num_points 预计显示的点数
     * @return 大小为num_points的数组
     */
    template <typename SType>
    std::tuple<std::unique_ptr<SType[]>, WaveformVisualizerError>
    getPointsInterleaved(const SType* buffer, size_t num_samples, size_t num_points);

    /**
     * @brief 获取通道数
     * 
     * @return size_t 
     */
    size_t getChannelNum() const { return m_num_channel; }

    /**
     * @brief 设置通道数
     * 
     * @param chan_num 新的通道数
     */
    void setChannelNum(size_t chan_num) { m_num_channel = chan_num; }

    /**
     * @brief 获取目前的选项
     * 
     * @return WaveformVisualizerOptions 
     */
    WaveformVisualizerOptions getOptions() const { return m_options; }

    /**
     * @brief 设置新的选项
     * 
     * @param option 新的选项
     */
    void setOptions(WaveformVisualizerOptions option) { m_options = option; }

private:
    size_t m_num_channel;
    WaveformVisualizerOptions m_options;
};

/*!
 * @brief 实时版波形可视化
 *
 * Example:
 * @code
 * WaveformVisualizerRT visualizer {1, 44100, 100};
 * visualizer.reset();
 * for(auto &blk : blocks) {
 *   visualizer.process(blk, size_of_blk);
 *   written += visualizer.getRemainedPoints(out_buf + written, size_can_write);
 * }
 * size_t remained = visualizer.finish();
 * written += visualizer.getRemainedPoints(out_buf + written, size_can_write);
 * @endcode
 *
 * 输出out_buf经验大小：ceil(block_size / sampleRate * pointRate)
 */
class MAMMON_EXPORT WaveformVisualizerRT final {
public:
    /*!
     *
     * @param num_channel 通道数
     * @param sampleRate 采样率
     * @param pointRate 每秒输出的点数
     * @param options 可视化选项
     */
    WaveformVisualizerRT(size_t num_channel, size_t sampleRate, float pointRate,
                         WaveformVisualizerOptions options = WaveformVisualizerOption::Default);
    WaveformVisualizerRT(const WaveformVisualizerRT& other) = delete;
    ~WaveformVisualizerRT() = default;

    /*!
     * @brief 重置对象状态
     * 每次从头到尾跑一遍时都需要调用一次reset
     */
    void reset();

    /*!
     * @brief 设置对象完成状态
     *
     * 整个绘制过程的数据都送完之后调用一次，
     * 来取剩余的绘制点数
     * @return 还剩多少绘制点没取
     */
    size_t finish();


    /*!
     * 传入音频数据来生成绘制点
     * @param buffer 音频采样buffer
     * @param num_frame buffer内的帧长
     * @return 生成点数
     */
    ssize_t process(const float* const* buffer, size_t num_frame);

    /*!
     * 取出已经生成的绘制点
     * @param out_buffer 输出
     * @param buffer_size buffer可写入大小
     * @return 已写入长度
     */
    size_t getRemainedPoints(float* out_buffer, size_t buffer_size);


    /**
     * @brief 获取通道数
     * 
     * @return size_t 
     */
    size_t getChannelNum() const { return num_channel_; }

    /**
     * @brief 设置通道数
     * 
     * @param chan_num 新的通道数
     */
    void setChannelNum(size_t chan_num) { num_channel_ = chan_num; }

    /**
     * @brief 获取目前的选项
     * 
     * @return WaveformVisualizerOptions 
     */
    WaveformVisualizerOptions getOptions() const { return options_; }

    /**
     * @brief 设置新的选项
     * 
     * @param option 新的选项
     */
    void setOptions(WaveformVisualizerOptions option) { options_ = option; }

private:
    std::vector<float> points_;
    WaveformVisualizerOptions options_;

    size_t num_channel_;
    size_t sample_rate_;

    float read_idx_;
    size_t processed_num_;
    float stride_;
    float last_state_;
};

}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_WAVEFORM_VISUALIZER_H
