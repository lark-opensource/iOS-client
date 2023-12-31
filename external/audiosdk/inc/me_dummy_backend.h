
//
// Created by huanghao.blur on 2019/11/18.
//
#pragma once
#ifndef AUDIO_EFFECT_DUMMY_BACKEND_H
#define AUDIO_EFFECT_DUMMY_BACKEND_H

#include "mammon_engine_defs.h"

#include <functional>
#include <memory>
#include <string>
#include <vector>
#include <atomic>
#include "audio_device_setting.h"
#include "ae_audio_status.h"
#include "me_audio_backend.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 伪设备后端
 * 可以用来获取图的数据
 */
class MAMMON_EXPORT DummyBackend : public AudioBackend {
public:
    DummyBackend(size_t fs);
    DummyBackend(size_t sample_rate, size_t max_block_size);
    const char* name() override;

    BackendType type() const override {
        return type_;
    }

    void setBackendType(BackendType t);

    void setBufferFrameSize(const size_t buffer_size) override;
    size_t getBufferFrameSize() const override;

    // Input Settings
    void setMultiInputCallback(AudioBackendMultiIOCallback&& callback) override;

    // Output Settings
    void setOutputCallback(AudioBackendIOCallback&& callback) override;
    void removeOutputCallback() override;
    void setMultiOutputCallback(AudioBackendMultiIOCallback&& callback) override;
    void setOutputEnabled(bool) override;
    size_t getOutputSampleRate() const override;
    size_t getOutputChannelNum() const override;
    DeviceStatus setOutputChannelNum(size_t num) override;

    void setInputCallback(AudioBackendIOCallback&& callback) override;
    void removeInputCallback() override;

    /**
     * @brief Create a Dummy Backend object
     *
     * @param fs
     * @return std::unique_ptr<DummyBackend>
     */
    static std::unique_ptr<DummyBackend> createDummyBackend(size_t fs = 44100);

    /**
     * @brief 直接从图里拉数据
     *
     * @param buf 交错格式的数组
     * @param size
     * @param ch
     * @param port
     * @param ts
     * @return AudioBackendCallbackStatus
     */
    AudioBackendCallbackStatus pullData(float* buf,
                                        size_t size,
                                        size_t ch,
                                        BackendPortType port = BackendPortType::kOutPortPlay,
                                        uint64_t* ts = nullptr);

    /**
     * @brief 向图中的设备输入源推送数据
     *
     * @param data 交错格式的数组
     * @param size
     * @param ch
     * @param port
     * @param ts
     * @return AudioBackendCallbackStatus
     */
    AudioBackendCallbackStatus pushData(float* data,
                                        size_t size,
                                        size_t ch,
                                        BackendPortType port = BackendPortType::kInPortMic,
                                        uint64_t ts = 0);

private:
    BackendType type_;

    std::vector<float> cache_data_;

    size_t block_size_;

    std::shared_ptr<AudioBackendIOCallback> input_callback_{nullptr};
    std::atomic<AudioBackendIOCallback*> p_input_callback_{nullptr};

    std::shared_ptr<AudioBackendIOCallback> output_callback_{nullptr};
    std::atomic<AudioBackendIOCallback*> p_output_callback_{nullptr};

    std::shared_ptr<AudioBackendMultiIOCallback> input_multi_callback_{nullptr};
    std::atomic<AudioBackendMultiIOCallback*> p_input_multi_callback_{nullptr};

    std::shared_ptr<AudioBackendMultiIOCallback> output_multi_callback_{nullptr};
    std::atomic<AudioBackendMultiIOCallback*> p_output_multi_callback_{nullptr};
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_DUMMY_BACKEND_H
