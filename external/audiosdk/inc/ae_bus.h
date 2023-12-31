//
// Created by william on 2019-04-14.
//

#pragma once
#include <memory>
#include <string>
#include "ae_audio_buffer.h"
#include "ae_audio_buffer2D.h"
#include "ae_audio_buffer_interleave1D.h"

namespace mammon {
    class MAMMON_EXPORT Bus {
    public:
        Bus();
        Bus(const Bus& bus);
        Bus& operator=(const Bus& bus);

        Bus(const std::string& name, float** data_refer_to, int num_channels, int num_samples);
        Bus(const std::string& name, const AudioBuffer2D& buffer);
        Bus(const std::string& name, float* interleave_data, int num_channels, int num_samples);
        Bus(const std::string& name, const AudioBufferInterleave1D& buffer);

        ~Bus();

        std::string getName() const;

        int getNumChannels() const;
        bool isInterLeaveData() const;

    private:
        void CopyBuffer(AudioBuffer* buffer);

    public:
        AudioBuffer* buffer;

    private:
        bool is_interleave_;
        std::string name_;
    };

}  // namespace mammon