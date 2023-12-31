
#pragma once
#ifndef AUDIO_EFFECT_AE_REVERSE_WAV_H
#define AUDIO_EFFECT_AE_REVERSE_WAV_H
#include <cstddef>
#include <cstdint>
#include <memory>
#include "ae_defs.h"

namespace mammon {

    /**
     *
     * @param in_filename 输入文件名，只能是RIFF PCM Wave格式
     * @param out_filename 输出文件名
     * @param block_size 扎堆处理的采样数（每通道），设置成0请自行承担效率后果
     * @return 成功与否
     */
    MAMMON_EXPORT bool reverseWav(const char* in_filename, const char* out_filename, uint32_t block_size = 4096);
}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_WAVEFORM_VISUALIZER_H
