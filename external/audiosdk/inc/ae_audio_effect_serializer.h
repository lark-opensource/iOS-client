//
// Created by william on 2019-06-19.
//

#pragma once
#include "ae_effect.h"
#include <memory>
#include <string>
namespace mammon
{
class AudioEffectSerializer
{
public:
    virtual ~AudioEffectSerializer() = default;

    virtual std::string serialize(const std::unique_ptr<Effect>& effect) = 0;
    virtual std::string serialize(Effect* effect) = 0;
};

}
