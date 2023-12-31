/**
 * @file ae_vocoder.h
 * @author HUANG Hao (huanghao.blur@bytedance.com)
 * @brief 声码器效果
 * @version 0.1
 * @date 2019-10-25
 */

#pragma once

#ifndef MAMMON_VOCODER_HEADER
#define MAMMON_VOCODER_HEADER

#include "ae_effect.h"

namespace mammon {

    /**
     * @brief Vocoder错误码
     */
    enum struct VocoderError {
        kBusNumErr = -1,             ///< 通道数不是2
        kCarriorChannelNumErr = -2,  ///< 载波不是立体声
        kModularChannelNumErr = -3,  ///< 调制的人声不是单声道
        kCarriorCannotRead = -4      ///< 读不到载波
    };

    class Vocoder final : public Effect {
    public:
        explicit Vocoder(size_t sample_rate);
        ~Vocoder() final = default;

        static constexpr const char* EFFECT_NAME = "vocoder";

        const char* getName() const override {
            return EFFECT_NAME;
        }

        /**
         * @brief 处理一个Block数据
         * 只处理单声道数据，所以会只取左边声道
         * @param bus_array inout audio data to process
         * @return int 正确处理时等于0，小于0时返回的是VocoderError错误码
         */
        int process(std::vector<Bus>& bus_array) override;
        /**
         * @brief 重置Vocoder状态
         */
        void reset() override;

        void setParameter(const std::string& name, float value) override;
        bool seek(double newPosInSec, int mode = SEEK_SET) override;
        bool seek(int64_t newPosInSamples, int mode = SEEK_SET) override;
        void seekDefinitely(int64_t newPosInSamples) override;

    private:
        size_t sample_rate_;

        float silent_threshold_;
        class Impl;

        /**
         * @var Parameter num_band
         * @brief band数
         * 越高越自然，越低越机械
         * 整形，范围[10, 80]
         */
        DEF_PARAMETER(num_band_, "num_band", 64, 10, 80)
        /**
         * @var Parameter format_shift
         * @brief 共振峰（音高）移动
         * 大于1升高，小于1降低，1不变
         * 浮点，范围[0.01, 2.0]
         */
        DEF_PARAMETER(formant_shift_, "format_shift", 1.0, 0.01, 2.0)
        /**
         * @var Parameter reaction_time
         * @brief 反应时间
         * 单位s，小于0.02会让声音听起来很粗糙和不舒服
         * 大于0.2会让声音听起来难懂
         */
        DEF_PARAMETER(reaction_time_, "reaction_time", 0.02f, 0.002, 2.0)

        /**
         * @var Parameter carrior_id
         * @brief 载波ID
         * 用来选择使用哪一个载波
         */
        DEF_PARAMETER(carrior_id_, "carrior_id", 0, 0, 100)

        DEF_PARAMETER(gain_, "vocoder_gain", 1.0, 0.0001, 20)

        std::shared_ptr<Impl> internals_;
    };

}  // namespace mammon

#endif
