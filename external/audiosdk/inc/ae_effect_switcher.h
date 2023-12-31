//
// Created by shidephen on 2020/7/13.
//

#ifndef AUDIO_EFFECT_AE_EFFECT_SWITCHER_H
#define AUDIO_EFFECT_AE_EFFECT_SWITCHER_H

#include <memory>
#include <vector>
#include "ae_bus.h"

namespace mammon {

    class Effect;

    class EffectSwitcher {
    public:
        /**
         * @brief Create an effect switcher
         * 创建函数
         * @param sample_rate 采样率
         * @param fading_dur_ms 淡入淡出时间
         * @return std::unique_ptr<EffectSwitcher>
         */
        static std::unique_ptr<EffectSwitcher> create(size_t sample_rate, float fading_dur_ms = 20);
        /**
         * @brief Initializing function 初始化函数
         * Need be called before running. 每次创建完对象后，或者改了blocksize必须调用
         * @param block_size 每次调用传入的数据帧数
         * @param num_chan 每帧内有多少个通道
         */
        virtual void init(size_t block_size, size_t num_chan) = 0;
        /**
         * @brief 实际的处理函数
         *
         * @param bus Data bus
         * @return int 正常返回值
         */
        virtual int process(std::vector<Bus>& bus) = 0;
        /**
         * @brief Switch an effect in realtime 实时切换一个下一个音效
         *
         * @param afx Effect pointer
         */
        virtual void switchEffect(std::shared_ptr<Effect> afx) = 0;
        /**
         * @brief Set a new duration time 设置一个新的淡出时间(ms)
         *
         * @param fading_len Duration of fading(ms) 淡入淡出时间，单位ms
         */
        virtual void setFadingDuration(float fading_len_ms) = 0;

        virtual ~EffectSwitcher() = default;
    };
}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_EFFECT_SWITCHER_H
