//
// Created by colinaudio on 2020/6/23.
//

#ifndef AUDIO_EFFECT_AE_RNNOISE_LOADMODEL_H
#define AUDIO_EFFECT_AE_RNNOISE_LOADMODEL_H
#include <string>
#include "ae_defs.h"

namespace mammon {
    class Effect;

    MAMMON_EXPORT bool loadModel(const std::string& path, Effect& ef);
}  // namespace mammon
#endif  // AUDIO_EFFECT_AE_RNNOISE_LOADMODEL_H
