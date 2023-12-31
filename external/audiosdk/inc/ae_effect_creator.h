//
// Created by william on 2019-05-21.
//

#pragma once
#include <map>
#include "ae_defs.h"
#include "ae_effect_factory.h"

namespace mammon {

    class MAMMON_EXPORT EffectCreator {
    public:
        std::unique_ptr<mammon::Effect> create(const std::string& effect_name, int sample_rate = 44100,
                                               int num_channel = 2);
        std::unique_ptr<mammon::Effect> create(const std::string& effect_name, int sample_rate, int num_channel,
                                               const std::vector<Parameter>& parameters);
        std::unique_ptr<mammon::Effect> createRNNoise48k(int sample_rate, int num_channel);

        static EffectCreator& getInstance();

        const std::map<std::string, size_t>& getUsedEffect() const {
            return used_effect_name_set_;
        };

        void clearUsedEffect() {
            used_effect_name_set_.clear();
        };

    private:
        std::map<std::string, size_t> used_effect_name_set_ = {};
        EffectCreator() = default;
        void logging(const std::string& effect_name);
        static int checkValid(int sample_rate, int num_channel);
    };

    /**
     * @brief Factory creator for creating non-realtime effect
     *
     */
    class MAMMON_EXPORT NonRealtimeEffectCreator {
    public:
        /**
         * @brief Get the singleton Instance object
         *
         * @return NonRealtimeEffectCreator&
         */
        static NonRealtimeEffectCreator& getInstance();

        /**
         * @brief Create a Factory object
         * @tparam TF The type of non-realtime effect factory
         * @return std::unique_ptr<TF>
         */
        template <typename TF>
        std::unique_ptr<TF> createFactory();

        /**
         * @brief Get the Used Effect object
         *
         * @return const std::map<std::string, size_t>&
         */
        const std::map<std::string, size_t>& getUsedEffect() const {
            return used_effect_name_set_;
        };

    private:
        NonRealtimeEffectCreator() = default;
        std::map<std::string, size_t> used_effect_name_set_;
    };

}  // namespace mammon
