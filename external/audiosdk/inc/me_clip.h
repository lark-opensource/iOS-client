#pragma once
#include "mammon_engine_type_defs.h"
#include "me_audiostream.h"
#include <memory>
#include <tuple>

MAMMON_ENGINE_NAMESPACE_BEGIN

class Track;

/**
 * @brief 音频Clip对象
 * 表示声音片段的逻辑对象
 */
class MAMMON_EXPORT Clip {
public:
    Clip(Track& parent);
    Clip(const std::shared_ptr<AudioStream>& data, Second position, Track& parent);

    ~Clip();

    size_t id() const {
        return id_;
    };
    size_t nodeId() const {
        return source_node_id_;
    }

    Track& track() {
        return track_;
    };

    /**
     * @brief 获取clip在Transport时间线上开始播放的位置
     *
     * @return Second
     */
    Second getPosition() const {
        return start_pos_;
    };

    void setPosition(Second sec);

    /**
     * @brief 获取clip内的buffer中开始播放的位置
     *
     * @return size_t
     */
    size_t getInPoint() const {
        return in_point_;
    };
    void setInPoint(size_t pos);

    /**
     * @brief 获取clip内的buffer停止播放的位置
     *
     * @return size_t
     */
    size_t getOutPoint() const {
        return out_point_;
    };
    void setOutPoint(size_t pos);

    /**
     * @brief 绑定一个buffer用来播放
     *
     * @param buf buffer
     * @param size buffer大小
     */
    void bindBuffer(std::shared_ptr<float[]>& buf, size_t size);
    void bindBuffer(const std::shared_ptr<AudioStream>& buf);

    /**
     * @brief 设置Clip采样率
     *
     * @param sr 采样率
     */
    void setSampleRate(size_t sr);
    /**
     * @brief 获取当前Clip的采样率
     *
     * @return size_t
     */
    size_t getSampleRate() const {
        return sr_;
    }
    /**
     * @brief 获取原始的采样率
     *
     * @return size_t
     */
    size_t getOriginSR() const;

private:
    Track& track_;

    Second start_pos_;
    size_t in_point_;
    size_t out_point_;

    size_t sr_;

    std::shared_ptr<AudioStream> stream_;

    int source_node_id_;
    size_t id_;

    // pimp
};
}
