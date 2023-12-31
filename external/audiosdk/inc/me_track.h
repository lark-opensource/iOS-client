#pragma once
#include "me_clip.h"
#include <cstddef>
#include <memory>
#include <vector>

MAMMON_ENGINE_NAMESPACE_BEGIN

class AudioEngine;

/**
 * @brief 轨道类型
 * 目前只支持AudioTrack
 */
enum class TrackType {
    AudioTrack,  ///< 音频轨
    MidiTrack    ///< MIDI轨
};

/**
 * @brief 音频轨道
 * 作为用来编组Clip的逻辑容器
 */
class MAMMON_EXPORT Track {
public:
    /**
     * @brief Construct a new Track object
     *
     * @param type 轨道类型
     * @param engine 全局的AudioEngine对象
     */
    explicit Track(TrackType type, AudioEngine& engine);

    /**
     * @brief Track的全局唯一ID
     * 暂未实现ID生成
     * @return size_t
     */
    size_t id() const {
        return id_;
    };
    size_t nodeId() const {
        return mixer_node_id_;
    }
    /**
     * @brief 获取轨道类型
     *
     * @return TrackType
     */
    TrackType type() const {
        return type_;
    };

    /**
     * @brief 创建属于这个轨道的clip
     *
     * @return Clip& 轨道对象
     */
    Clip& createClip();
    /**
     * @brief 创建Clip
     *
     * @param data 创建Clip的音频数据
     * @param pos Clip 起始位置
     * @return Clip&
     */
    Clip& createClip(const std::shared_ptr<AudioStream>& data, Second pos);
    /**
     * @brief 删除clip对象
     * 只能删除在当前轨道中的clip对象
     * @return true
     * @return false
     */
    bool deleteClip(Clip*);

    /**
     * @brief 是否轨道静音
     *
     * @return true
     * @return false
     */
    bool isMute() const {
        return mute_;
    };
    /**
     * @brief 设置轨道静音状态
     *
     */
    void setMute(bool);
    /**
     * @brief 开关轨道静音状态
     *
     */
    void toggleMute();

    /**
     * @brief 轨道是否独奏的（solo）
     *
     * @return true
     * @return false
     */
    bool isSolo() const {
        return solo_;
    };
    /**
     * @brief 设置轨道solo状态
     *
     */
    void setSolo(bool);
    /**
     * @brief 开关轨道solo状态
     *
     */
    void toggleSolo();

    AudioEngine& engine_;

private:
    void connect_clip_node(Clip* c);
    size_t id_;
    TrackType type_;

    bool mute_;  // TODO: Can be atomic?
    bool solo_;  // TODO: Can be atomic?

    size_t mixer_node_id_;

    std::vector<std::unique_ptr<Clip>> clips_;
};

MAMMON_ENGINE_NAMESPACE_END
