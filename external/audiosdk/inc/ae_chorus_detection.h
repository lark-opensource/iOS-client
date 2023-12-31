//
// Created by william on 2019/10/22.
//

#pragma once
#include <memory>
namespace mammon {
    class ChorusDetection {
    public:
        constexpr static float kChorusDuration = {30.0};

        explicit ChorusDetection(int sample_rate);

        int process(const float* data, int num_frame);

        int calcChorusStartingIndex();

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon