#pragma once
#include "mammon_engine_type_defs.h"
#include <tuple>

MAMMON_ENGINE_NAMESPACE_BEGIN

using RenderRange = std::tuple<TransportTime, TransportTime>;

/**
 * @brief 播放状态
 *
 */
enum TransportState {
    Preparing,  ///< 准备开始播放
    Playing,    ///< 播放中
    Stopping,   ///< 停止中
    Stopped,    ///< 已经停止播放
    Pausing,
    Paused,     ///< 暂停
    Recording   ///< 录音中
};
/**
 * @brief 记录AudioNode计算节点值时的上下文记录
 * 这个类可能在传递过程中修改，来满足node自定义stream数据的要求
 */
struct RenderContext {
    /**
     * @brief 系统采样率
     */
    size_t samplerate;
    /**
     * @brief 系统block size
     */
    size_t block_size;

    /**
     * @brief 播放光标位置
     * 一定是从0开始的全局时间，单位是TransportTime
     */
    TransportTime transport_position;

    /**
     * @brief 渲染区间
     * 表示从transport_position开始偏移的范围，第一个代表向前的偏移，第二个代表向后的偏移
     */
    RenderRange range;
    /**
     * @brief 是否循环播放
     */
    bool loop;
    /**
     * @brief 目前的走带状态
     */
    TransportState state;
    /**
     * @brief audio backend record state
     */
    bool recording;
};

static inline size_t getFrameNumFromRC(const RenderContext& rc) {
    return static_cast<size_t>(std::get<1>(rc.range) + std::get<0>(rc.range));
}
}
