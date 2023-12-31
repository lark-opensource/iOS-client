
//
// Created by William.Hua on 2020/10/29.
//

#pragma once
#include <string>
#include <memory>
#include <tuple>

namespace mammon {

/**
 * Audio encoder format
 *
 * You can pass different build option to select implementations.
 *
 * - USE_FFMPEG, ffmpeg implementation
 * - USE_TTFFMPEG, ttffmpeg implementation(only available on Android)
 * - USE_CORE_AUDIO, CoreAudio implementation(only available on macos/iOS)
 * - USE_3RDPARTY, lame implementation for mp3, fkd-aac for aac, dr_wav for wav
 *
 * By default, cmake/mammon_audio_io_options.cmake will selects the most appropriate implementation on different
 * platform:
 *
 * +----------------------------------------------------------------------+
 * |             Default Implementation on Different Platforms            |
 * +---------------+----------------+-------------------------------------+
 * |               |                |              Platforms              |
 * |               |                +---------+---------+-------+---------+
 * |               |                | Mac/iOS | Android | Linux | Windows |
 * +---------------+----------------+---------+---------+-------+---------+
 * |               | USE_FFMPEG     |         |         | ▲     |         |
 * |               +----------------+---------+---------+-------+---------+
 * |               | USE_TTFFMPEG   |         | ▲       |       |         |
 * | Build Options +----------------+---------+---------+-------+---------+
 * |               | USE_CORE_AUDIO | ▲       |         |       |         |
 * |               +----------------+---------+---------+-------+---------+
 * |               | USE_3RDPARTY   |         |         |       | ▲       |
 * +---------------+----------------+---------+---------+-------+---------+
 *
 *
 * Different implementation supports different encoding format, the following tables summarizes the available
 * implementation:
 *
 * +------------------------------+------------------------------------------------------------------------------------+
 * |                              |                                   Encoder Formats                                  |
 * |                              +-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                              | mp3 | aiff_s16 | aiff_s24 | wav_s16 | wav_s24 | wav_f32 | aac_lc | aac_ld | aac_he |
 * +-----------------+------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                 | core audio | ✖   | √        | √        | √       | √       | √       | √      | √      | √      |
 * |                 +------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                 | ffmpeg     | √   | √        | √        | √       | √       | √       | √      | √      | √      |
 * | Implementations +------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                 | ttffmpeg   | √   | ✖        | ✖        | √       | √       | √       | √      | ✖      | ✖      |
 * |                 +------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                 | 3rd party  | √   | ✖        | ✖        | √       | √       | √       | √      | ✖      | ✖      |
 * +-----------------+------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 *
 *
 */
enum class AudioEncoderFormat {
    kNone = 0,
    kMp3,       // not supported in ttffmpeg(D android)
    kAiff_S16,  // not supported in ttffmpeg(D android)
    kAiff_S24,  // not supported in ttffmpeg(D android)
    kWav_S16,
    kWav_S24,  // not supported in ttffmpeg(D android)
    kWav_F32,  // not supported in ttffmpeg(D android)
    kFLAC_F32,
    kAAC_LC,
    kAAC_LD,
    kAAC_HE,
};

/**
 * Encoder acceleration option.
 *
 * kHardware_Acceleration, hardware encoding acceleration is currently only available on Android
 *
 */
enum class AudioEncoderAcceleration {
    kSoftware,
    kHardware_Acceleration,
};

/**
 * Encoder thread option.
 *
 * kMultiThreaded is currently only available on aac format
 *
 * +-----------------+------------------------------------------------------------------------------------+
 * |                 |                                   Encoder Formats                                  |
 * |                 +-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * |                 | mp3 | aiff_s16 | aiff_s24 | wav_s16 | wav_s24 | wav_f32 | aac_lc | aac_ld | aac_he |
 * +-----------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * | kSingleThreaded | √   | √        | √        | √       | √       | √       | √      | √      | √      |
 * +-----------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 * | kMultiThreaded  |     |          |          |         |         |         | √      | √      | √      |
 * +-----------------+-----+----------+----------+---------+---------+---------+--------+--------+--------+
 *
 *
 */
enum class AudioEncoderThreading { kSingleThreaded, kMultiThreaded };

/**
 * Settings for creating audio encoder
 * @see AudioEncoderFormat
 * @see AudioEncoderAcceleration
 * @see AudioEncoderThreading
 *
 * if num_threads <= 0, it will use std::hardware_concurrency() as default.
 *
 */
struct AudioEncoderSettings {
    AudioEncoderFormat format{AudioEncoderFormat::kNone};
    AudioEncoderAcceleration acc{AudioEncoderAcceleration::kSoftware};
    AudioEncoderThreading threading{AudioEncoderThreading::kSingleThreaded};
    int num_threads{0};
};

enum class AudioEncoderStatus { kOK, kCodecNotSupported };

class AudioEncoder;
class ByteStream;

using AudioEncoderResult = std::tuple<std::unique_ptr<AudioEncoder>, AudioEncoderStatus>;

class AudioEncoder {
public:
    /**
     * @deprecated EncoderType will be removed in the new version, please use AudioEncoderSettings to create encoders.
     */
    enum EncoderType {
        None = 0,
        kMp3,
        kAiff_S16,
        kAiff_S24,
        kWav_S16,
        kWav_S24,
        kWav_F32,
        kFLAC_F32,
        KAAC_CBR_320kbps,
        kAAC_CBR_256kbps,
        kAAC_Hi_res_680kbps,
        kAAC_Low_Latency_CBR_320kbps,
        KAAC_Low_Latency_CBR_192kbps,
        kAAC_Android_Hardware_Acceleration
    };

    /**
     * create audio encoder according to the input type
     *
     * returns nullptr if unsupported
     *
     * @deprecated please use AudioEncoderSetting to create audio encoder, this function will removed in the new
     * version.
     */
    static std::unique_ptr<AudioEncoder> create(EncoderType type);

    /**
     * create audio encoder according to the setting
     *
     * returns nullptr if unsupported
     *
     * @see AudioEncoderSettings
     */
    static AudioEncoderResult create(const AudioEncoderSettings& settings);

    virtual ~AudioEncoder() = default;
    /**
     * open file to write
     * @param output_path, the save path
     * @param sample_rate, sample rate of the output file
     * @param num_channels, number of channels of the output file
     * @param bit_rate, bit rate of the output file
     * @return 0 if successfully, -1 if failed
     */
    virtual int open(const std::string& output_path, int sample_rate, int num_channels, int64_t bit_rate) noexcept = 0;

    /**
     * open file with byte stream
     * @return 0 if successfully, -1 if failed
     */
    virtual int open(std::shared_ptr<ByteStream> byte_stream, int sample_rate, int num_channels, int64_t bit_rate) noexcept = 0;

    /**
     * write planar audio data to file
     * @return 1. number of frames actually written if you use kSingleThreaded
     *         2. number of bytes written to output if you use kMultiThreaded,
     *            maybe 0 because the worker which in other thread not finished encoding.
     */
    virtual int64_t writePlanarData(const float* const* planar_data, int num_channels,
                                    int64_t num_sample_per_channel) noexcept = 0;

    /**
     * write interleave audio data to file
     * @return 1. number of frames actually written if use kSingleThreaded
     *         2. number of bytes written to output if use kMultiThreaded,
     *            maybe 0 because the worker which in other thread not finished encoding.
     */
    virtual int64_t writeInterleaveData(const float* interleave_data, int num_channels,
                                        int64_t num_sample_per_channel) noexcept = 0;

    /**
     * close file to end the write process.
     *
     * flush will be called in this function.
     */
    virtual void close() noexcept = 0;

    /**
     * flush the remaining data to file
     */
    virtual void flush() noexcept = 0;

    /**
     * returns sample rate of output file, if open failed will return 0
     */
    virtual int getSampleRate() const noexcept = 0;

    /**
     * returns number of channels of output file, if open failed will return 0
     */
    virtual int getNumChannels() const noexcept = 0;

    /**
     * returns true if opened, others returns false
     */
    virtual bool isOpen() const noexcept = 0;
};
}  // namespace mammon
