//
// Created by huanghao.blur on 2019/11/18.
//
#pragma once
#ifndef SAMI_ME_AUDIO_BACKEND_H
#define SAMI_ME_AUDIO_BACKEND_H

#include "audio_backend_defs.h"
#define AB_LOG_CONCATE(st) "AudioBackend: " #st

#include <functional>
#include <memory>
#include <string>
#include <vector>
#include <tuple>
#include <mutex>
#include "audio_device_setting.h"
#include "ae_audio_status.h"

namespace mammonengine {

enum class AudioBackendCallbackStatus { kOK, kUnderRun, kUnbind, kOverRun };

enum class DeviceMessage {
    DeviceDisconnected,   ///< 设备断开连接（关蓝牙耳机）
    DeviceConnected,      ///< 新设备连接（连接蓝牙耳机）
    SampleRateChanged,    ///< 设备回放采样率变化
    DeviceChanged,        ///< 设备切换了
    StreamingStarted,     ///< 设备开始输入输出
    StreamingStopped,     ///< 设备停止输入输出
    ChangeRenderContext,  ///< 修改渲染上下文
    AcquireGraph,         ///< 获取当前 AudioGraph
    DeviceStreamError,
    DeviceUnderRun,
    DeviceOverRun,
};

enum BackendPortType {
    kOutPortPlay = 0,
    kOutPortWrite,

    kInPortMic = 100,
    kInPortMusic
};

enum class DeviceStatus { kOK, kUnSupported };

class DeviceInfo {
public:
    int uuid;
    std::vector<size_t> channel;
    std::vector<size_t> samplerate;
    bool lowlatency;
};

enum {
    AudioSessionBeginInterruption  = 1,
    AudioSessionEndInterruption    = 0
};

enum class BackendType { Realtime, Offline, MultiPort };

class AudioBackend;
using AudioBackendIOCallback = std::function<AudioBackendCallbackStatus(AudioBackend*, float*, size_t, size_t)>;
using AudioBackendMultiIOCallback = std::function<AudioBackendCallbackStatus(AudioBackend*, float*, size_t, size_t, BackendPortType, uint64_t&)>;
using AudioBackendMessageCallback = std::function<AudioBackendCallbackStatus(AudioBackend*, DeviceMessage, void*)>;

struct AaudioUserdata {
    size_t underRun;
    size_t overRun;
    bool playIsMmap;
    bool playIsLowLatency;
    bool playIsExclusive;
    bool recordIsMmap;
    bool recordIsLowLatency;
    bool recordIsExclusive;
};
/**
 * @brief 音频设备的抽象接口
 *
 */
class MAMMON_EXPORT AudioBackend {
public:
    /**
     * @brief 创建一个实时回放设备 Create a Default Backend object
     * 会根据当前系统选择适合的播放后端
     * @param fs 采样率 默认44100
     * @return std::shared_ptr<AudioBackend>
     */
    static std::shared_ptr<AudioBackend> createDefaultBackend(size_t fs = 44100);

    /**
     * @brief Create a realtime Backend object
     * @param audioDeviceSettings:device settings such as sampleRate
     * @return std::tuple<std::shared_ptr<AudioBackend>,AudioCreatBackendStatus>
     */
    static std::tuple<std::shared_ptr<AudioBackend>, AudioStatus> createRealTimeBackend(
        AudioDeviceSettings);

    static void setOfflineDummyBackend(shared_ptr<AudioBackend> backend);

    explicit AudioBackend(size_t sample_rate) : sample_rate_(sample_rate) {
    }

    virtual ~AudioBackend() = default;

    virtual const char* name() = 0;

    virtual DeviceStatus setSampleRate(size_t) {
        return DeviceStatus::kUnSupported;
    }
    virtual size_t getSampleRate() const {
        return sample_rate_;
    }
    // Input Settings
    virtual void setInputCallback(AudioBackendIOCallback&&){};
    virtual void setMultiInputCallback(AudioBackendMultiIOCallback&&){};
    virtual void removeInputCallback(){};
    virtual void setInputEnabled(bool){};
    virtual bool inputEnabled() const {
        return false;
    }
    virtual size_t getInputSampleRate() const {
        return sample_rate_;
    }
    virtual size_t getInputChannelNum() const {
        return 0;
    }

    virtual DeviceStatus setInputChannelNum(size_t) {
        return DeviceStatus::kUnSupported;
    };

    // Output Settings
    virtual void setOutputCallback(AudioBackendIOCallback&&) = 0;
    virtual void setMultiOutputCallback(AudioBackendMultiIOCallback&&){};
    virtual void removeOutputCallback() = 0;
    virtual void setOutputEnabled(bool) {
    }
    virtual size_t getOutputSampleRate() const = 0;
    virtual size_t getOutputChannelNum() const = 0;
    virtual DeviceStatus setOutputChannelNum(size_t) = 0;

    virtual void setDeviceMessageCallback(AudioBackendMessageCallback&&){};
    virtual void removeDeviceMessageCallback(){};

    virtual std::vector<DeviceInfo*> queryDevice() {
        return {};
    }

    virtual DeviceStatus switchMainDevice(size_t) {
        return DeviceStatus::kUnSupported;
    }

    virtual BackendType type() const {
        return BackendType::Realtime;
    }

    /// get/set backend's buffer size in frame
    virtual size_t getBufferFrameSize() const {
        return 0;
    }
    virtual void setBufferFrameSize(const size_t) {
    }

    // return the address of the internal member variable. No need to release
    // need to check return value is null
    virtual void* getUserData() {
        return nullptr;
    }

    virtual int getXRunCount() {
        return -1;
    }

protected:
    size_t sample_rate_;

    mutex op_lock_;
};

} // namespace mammon

#endif  // SAMI_ME_AUDIO_BACKEND_H
