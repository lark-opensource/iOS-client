//
// Created by william on 2019-06-19.
//

#pragma once

#include <memory>
#include <string>
#include "ae_audio_effect_serializer.h"
namespace mammon {

    class YamlCaseInfo;

    class YAMLSerializer : public AudioEffectSerializer {
    public:
        YAMLSerializer(int version);
        virtual ~YAMLSerializer() = default;
        std::string serialize(const std::unique_ptr<Effect>& effect) override;
        std::string serialize(Effect* effect) override;
        std::string serialize(Effect* effect, const std::map<std::string, std::string>& metadata);
        std::string serialize(const YamlCaseInfo& case_info);
        std::string serialize(const std::vector<YamlCaseInfo>& case_info_array);

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
