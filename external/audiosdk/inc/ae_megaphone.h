#pragma once

#include "ae_effect.h"

namespace mammon {

    enum {
        Bessel1Lp,
        Bessel1Hp,
        Bessel2Lp,
        Bessel2Hp,
        Bessel3Lp,
        Bessel3Hp,
        Bessel4Lp,
        Bessel4Hp,
        Bessel5Lp,
        Bessel5Hp,
        Bessel6Lp,
        Bessel6Hp,
        Bessel7Lp,
        Bessel7Hp,
        Bessel8Lp,
        Bessel8Hp,

        ButterWorth1Lp,
        ButterWorth1Hp,
        ButterWorth2Lp,
        ButterWorth2Hp,
        ButterWorth3Lp,
        ButterWorth3Hp,
        ButterWorth4Lp,
        ButterWorth4Hp,
        ButterWorth5Lp,
        ButterWorth5Hp,
        ButterWorth6Lp,
        ButterWorth6Hp,
        ButterWorth7Lp,
        ButterWorth7Hp,
        ButterWorth8Lp,
        ButterWorth8Hp,

        LinkWitzRiley2Lp,
        LinkWitzRiley2Hp,
        LinkWitzRiley4Lp,
        LinkWitzRiley4Hp,
        LinkWitzRiley6Lp,
        LinkWitzRiley6Hp,
        LinkWitzRiley8Lp,
        LinkWitzRiley8Hp,
    };

    class MegaphoneProcessor : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "megaphone";

        MegaphoneProcessor(int sample_rate, int num_channels);
        virtual ~MegaphoneProcessor() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        virtual int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(lpf_fc_, "lpf_fc", 4000, 20, 20000)
        DEF_PARAMETER(hpf_fc_, "hpf_fc", 500, 20, 20000)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
