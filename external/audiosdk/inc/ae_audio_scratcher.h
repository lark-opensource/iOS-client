#pragma once
#include "ae_defs.h"
#include "ae_no_effect.h"

#define MAMMON_NONREALTIME_PITCHSHIFTER_NAME "audio_scrathcer"

namespace mammon {

class AudioScratcher : public NoEffect {
public:
    virtual ~AudioScratcher() = default;

    AudioScratcher(int num_channel, int sample_rate);
    /**
         * @brief Get the name of audio scratcher
         *
         * @return const char*
         */
    virtual const char* getName() const override {
        return MAMMON_NONREALTIME_PITCHSHIFTER_NAME;
    }

    /**
         * @brief Actually process input data
         * @param bus_array Input data blocks
         * @return int If success returns 0 otherwise non zero values
         */
    virtual int process(std::vector<Bus>& input_bus, std::vector<Bus>& output_bus) override;

    /**
         * @brief Reset processing state to the initial state
         */
    virtual void reset() override;

    /**
         * @brief Update a value for single parameter
         * @param name Parameter name
         * @param value Parameter value
         */
    virtual void setParameter(const std::string& name, float value) override;

    virtual const Parameter& getParameter(const std::string& name) const override;

private:
    class Impl;
    std::shared_ptr<Impl> impl_{nullptr};
    Parameter invalid_parameter_;
};

}  // namespace mammon
