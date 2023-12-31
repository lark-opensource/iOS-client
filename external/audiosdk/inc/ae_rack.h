//
// Created by Feng Suiyu on 2019-05-15.
//

#pragma once

#include "ae_cascade_effect.h"

namespace mammon {
    class Rack : public CascadeEffect {
    public:
        Rack(int sample_rate, int num_channels): CascadeEffect(sample_rate, num_channels) {
        }
        virtual ~Rack(){};
    };

}  // namespace mammon
