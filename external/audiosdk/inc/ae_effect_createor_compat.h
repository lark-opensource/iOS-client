//
// Created by william on 2019-06-18.
//

#pragma once

#include "ae_effect.h"
#include <string>
#include <memory>

namespace mammon
{

class EffectCreatorCompat
{
public:
    std::unique_ptr<mammon::Effect> createFromYamlText(const std::string& yaml_txt,
                                                       int sample_rate, int num_channels);

    std::unique_ptr<mammon::Effect> createFromFile(const std::string& filename,
                                           int sample_rate, int num_channels);

    static EffectCreatorCompat& getInstance()
    {
        static EffectCreatorCompat instance;
        return instance;
    }

private:
    EffectCreatorCompat();

private:
    class Impl;
    std::shared_ptr<Impl> impl_;

};

}

