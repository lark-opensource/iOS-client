#pragma once
#include "ae_defs.h"
#include "me_rendercontext.h"
#include <memory>
#include <atomic>

MAMMON_ENGINE_NAMESPACE_BEGIN

class AudioEngine;

/**
 * @brief 播放控制器
 * 用来控制引擎的播放暂停录音等操作
 * 还能用来设置引擎的播放时间，循环状态
 */
class MAMMON_EXPORT Transport final {
public:
    explicit Transport(AudioEngine& engine);
    Transport(const Transport&) = delete;

    /**
     * @brief 开始播放
     * 播放操作可能都要等待一定时间后才开始播放，因为做了延迟补偿
     * @return TransportState 前一播放状态
     */
    TransportState play();
    /**
     * @brief 从指定位置开始播放一段声音
     * 暂未实现
     * @param pos 开始播放位置
     * @param dur 播放的时长
     * @return TransportState 前一播放状态
     */
    TransportState play(Second pos, Second dur);
    /**
     * @brief 停止播放
     * 停止操作会继续一段时间后才停止，因为要补完延迟
     * @return TransportState
     */
    TransportState stop();
    /**
     * @brief 暂停播放
     * 行为同停止
     * @return TransportState
     */
    TransportState pause();
    /**
     * @brief 获得当前播放状态
     *
     * @return TransportState
     */
    TransportState state();

    /**
     * @brief 获取现在的播放时间
     * 单位秒
     * @return Second
     */
    Second getSec() const;
    void setSec(Second sec);

    /**
     * @brief 获取当前走带时间
     * 单位TransportTime
     * @return TransportTime
     */
    TransportTime getTransportTime() const {
        return t_time_;
    }
    void setTransportTime(TransportTime time);

    /**
     * @brief 获取当前tick时间
     * 单位是tick，用来跟MIDI协议同步的单位
     * @return Tick
     */
    Tick getTick() const;
    void setTick(Tick tick);

    /**
     * @brief 获取当前播放BPM
     * 这个选项只与MIDI协议产生关系
     * @return BPM
     */
    BPM getBPM() const {
        return bpm_;
    };
    void setBPM(BPM bpm);

    /**
     * @brief 是否在循环播放
     *
     * @return true
     * @return false
     */
    bool isLooping() const {
        return looping_;
    };
    void setLooping(bool b);
    void toggleLooping();
    const RenderContext& getRenderContext() const {
        return rc_;
    }

private:
    AudioEngine& engine_;
    TransportTime t_time_;

    BPM bpm_;
    bool looping_;

    RenderContext rc_;
};

MAMMON_ENGINE_NAMESPACE_END