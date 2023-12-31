//
// Created by huanghao.blur on 2020/1/10.
//

#pragma once

#ifndef AUDIO_EFFECT_AE_EXTRACTOR_CREATOR_H
#define AUDIO_EFFECT_AE_EXTRACTOR_CREATOR_H

#include <memory>
#include "ae_defs.h"
#include "ae_extractor.h"

namespace mammon {

class MAMMON_EXPORT ExtractorCreator {
public:
    static std::unique_ptr<Extractor> create(ExtractorType type, size_t samplerate = 44100, size_t ch = 2);
    static std::unique_ptr<Extractor> create(const std::string&, size_t samplerate=44100, size_t ch=2);
};

} // namespace mammon

#endif  // AUDIO_EFFECT_AE_EXTRACTOR_CREATOR_H
