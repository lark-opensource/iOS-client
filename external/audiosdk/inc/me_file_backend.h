//
// Created by huanghao.blur on 2019/11/18.
//
#pragma once
#ifndef AUDIO_EFFECT_FILE_BACKEND_H
#define AUDIO_EFFECT_FILE_BACKEND_H

#include "mammon_engine_defs.h"

#include <functional>
#include <memory>
#include <string>
#include <vector>
#include "audio_device_setting.h"
#include "ae_audio_status.h"
#include "me_audio_backend.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 离线文件导出后端
 * 虚拟设备用于离线渲染效果
 */
class MAMMON_EXPORT FileBackend : public AudioBackend {
public:
  /**
   * @brief 创建离线使用的的文件设备 Create a File Backend object
   * 用作文件导出
   * @param fs
   * @param nc
   * @return std::unique_ptr<FileBackend>
   */
    static std::unique_ptr<FileBackend> createFileBackend(size_t fs = 44100, size_t nc = 2);

    // Inherited from AudioBackend
    /**
     * @brief 创建文件后端
     * 用于离线文件渲染
     * @param samplerate 采样率
     * @param num_channels 通道数
     */
    explicit FileBackend(size_t samplerate, size_t num_channels = 2)
        : AudioBackend(samplerate),
          output_ch_(num_channels),
          num_frames_(0),
          block_size_(512),
          has_meta_(false),
          should_produce_audio_(false) {
    }

    const char* name() override {
        return "FileBackend";
    }

    DeviceStatus setSampleRate(size_t fs) override;

    // Output Settings
    void setOutputCallback(AudioBackendIOCallback&& callback) override;

    void removeOutputCallback() override;

    size_t getOutputSampleRate() const override;

    size_t getOutputChannelNum() const override;

    DeviceStatus setOutputChannelNum(size_t num) override;

    void setDeviceMessageCallback(AudioBackendMessageCallback&& callback) override;
    void removeDeviceMessageCallback() override;

    BackendType type() const override {
        return BackendType::Offline;
    }

    /**
     * @brief 设置输入文件
     * 有占位用的FileSource时有用
     * @param file
     */
    void setInputFile(std::string file);

    /**
     * @brief 设置输出文件
     * 写入文件的路径（相对workspace路径）
     * 目前只支持wav
     * @param file
     */
    void setOutputFile(const std::string& file);
    /**
     * @brief 设置工作目录
     * input/output都是以workspace为根，默认是当前目录
     * @param ws
     */
    void setWorkSpace(const std::string& ws);
    /**
     * @brief 设置要提取的音频特征
     *
     * @param meta 特征名称
     */
    void addOutputMeta(const std::string& meta);

    /**
     * @brief 开始执行导出
     * 会按照outputfile来导出音频，如果有特征的话，会开始写入特征文件
     * @param duration_ms 设置导出的时长，默认按照最长的文件
     * @return int
     */
    int exportFile(double duration_ms = 0);

private:
    std::string input_file_;
    std::string output_file_;
    std::string workspace_;
    std::vector<std::string> output_meta_;

    size_t output_ch_;
    size_t num_frames_;
    size_t block_size_;

    bool has_meta_;
    bool should_produce_audio_;

    AudioBackendIOCallback output_callback_;
    AudioBackendMessageCallback msg_callback_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_FILE_BACKEND_H
