#pragma once

#include <memory>
#include <atomic>
#include <map>
#include <mutex>
#include "me_rendercontext.h"
#include "mammon_engine_defs.h"
#include "me_audio_backend.h"
#include "me_stream_handle.h"
#include "me_dummy_backend.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class AudioGraph;
class AudioBackend;

using IoManagerMessageCallback = bool (*)(DeviceMessage, void*);
/**
 * @brief IO策略对象
 * 用来绑定图计算和后端
 * 整体播放控制也是由它负责
 */
class MAMMON_EXPORT IOManager final {
public:
    /**
     * @brief Construct a new IOManager object
     *
     * @param engine AudioEngine 父对象
     * @param max_queue_size 预先计算的block queue数量
     */
    IOManager(std::shared_ptr<AudioGraph> graph, std::shared_ptr<AudioBackend> backend, size_t max_queue_size = 8);
    ~IOManager();

    /**
     * @brief 开始硬件设备工作
     * Warm-up and start device
     * 开始之后会不断循环，保证CPU一直处于运转状态
     */
    void start_ioloop();
    /**
     * @brief 停止设备工作
     * Stop device
     * 停止硬件循环
     */
    void stop_ioloop();

    /**
     * @brief 进入输入输出状态
     *
     * @param rc
     */
    void play(RenderContext& rc);

    void play();

    /**
     * @brief 停止
     *
     */
    void stop();

    /**
     * @brief 暂停
     *
     */
    void pause();

    /**
     * @brief Enable
     *
     */
    void setRecordingState(bool state);

    void setReferState(bool state);

    /**
     * @brief Set a new AudioGraph for pulling data.
     * 设置一个新的Audio拉数据
     * @param sink
     */
    void switchGraph(const std::shared_ptr<AudioGraph>& g);

    AudioGraph* getGraph();

    /**
     * @brief Current transport state
     *
     * @return TransportState
     */
    TransportState state();

    /**
     * @brief Switch to a new backend and return the old one
     *
     * @param backend
     * @return std::unique_ptr<AudioBackend>
     */
    std::shared_ptr<AudioBackend> switchBackend(std::shared_ptr<AudioBackend> backend);

    /**
     * @brief Get a pointer to current running backend
     *
     * @return AudioBackend*
     */
    AudioBackend* getCurrentBackend() {
        return backend_.get();
    }

    /**
     * @brief Wait for a transition from expected state to desired state
     * 等待一个从源状态到目标状态的转移
     * @param expected Source state of this transition 源状态
     * @param desired Desired destination state of transition 目标状态
     * @param timeout_ms Timeout time in millisecond 超时时间（毫秒）
     * @return Whether finished desired trasition 是否成功的转移了
     */
    bool waitForStateChange(TransportState& expected, TransportState desired, size_t timeout_ms);

    /**
     * @brief Get RC object by now
     * 获取现在的RC
     * @return RenderContext
     */
    RenderContext getCurrentRC();

    enum class PerformanceType {
        kUnderRunCount = 0,
        kOutputCallbackCostTime,
        kPullFrameCostTime,
        kOverRunCount,
        kInputCallbackCostTime,
        kCount
    };
    std::map<PerformanceType, uint32_t> getPerformanceCount();

    void setMessageCallback(IoManagerMessageCallback message_callback, void* userdata);

    enum class StreamHandleType {
        kDeviceIn = 0,
        kDeviceRef,
        kMusic
    };
    shared_ptr<StreamHandle> getStreamHandle(StreamHandleType type);

    /**
     * @brief set the port to mute
     *
     * @return void
     */
    void setMute(BackendPortType port, bool muted);

    /**
     * @brief get the port to muted state
     *
     * @return void
     */
    bool getMute(BackendPortType port);

private:
    class IOManagerInternals;

    std::shared_ptr<AudioGraph> graph_;

    const size_t max_queue_size_;
    size_t max_output_fifo_size_;

    size_t channel_num_;

    std::shared_ptr<IOManagerInternals> internals_;

    std::atomic<TransportState> state_;
    std::shared_ptr<AudioBackend> backend_;
};

MAMMON_ENGINE_NAMESPACE_END
