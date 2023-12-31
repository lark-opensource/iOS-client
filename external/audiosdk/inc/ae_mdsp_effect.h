//
// Created by admin on 2020/7/15.
//

#pragma once
#include "ae_effect.h"

namespace mammon {

    class MDSPEffect : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "music_dsp_effect";

        MDSPEffect();
        ~MDSPEffect() override = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void reset() override;

        int process(std::vector<Bus>& bus_array) override;

        void prepare(double sample_rate, int max_block_size);

        int loadJsonFile(const std::string& json_path);

        int loadJsonString(const std::string& json_str);

        /**
         * returns the ground json string.
         *
         * this string can be used as a plan B if resource download failed.
         *
         */
        static std::string getGroundJsonString();

        /**
         * Load preset from directory.
         *
         * this function will try to load "dir/mdsp_preset.json", it's more friendly for VE and Client to use.
         *
         * @param dir, director path string
         * @return 0 successfully, others failed
         */
        int loadFromDir(const std::string& dir);

    protected:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

    class MDSPEffectForVE : public MDSPEffect {
    public:
        static constexpr const char* EFFECT_NAME = "music_dsp_effect_ve";

        MDSPEffectForVE();
        ~MDSPEffectForVE() override = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        int loadJsonFile(const std::string& json_path, const std::vector<std::string>& path_list = {});

        int loadJsonString(const std::string& json_str, const std::vector<std::string>& path_list = {});

        std::string toJson();

        bool seek(double newPosInSec, int mode) override;
        bool seek(int64_t newPosInSamples, int mode) override;
        void seekDefinitely(int64_t newPosInSamples) override;

        int loadDDSPModel(const std::string& model_path);
    protected:
        class Impl;
        std::shared_ptr<Impl> impl_ve_;
    };

}  // namespace mammon
