//
// Created by william on 2019-05-22.
//

#pragma once
#include <string>
#include <vector>
#include "ae_effect.h"
#include "ae_parameter.h"

namespace mammon {

    class EffectInfo {
    public:
        std::string effect_name;
        std::vector<mammon::Parameter> parameter_array;
    };

    class CmdParameters {
    public:
        std::string effect_name;
        std::map<std::string, float> effect_parameters;
        std::map<std::string, std::vector<float>> effect_parameters_array;
        std::map<std::string, std::map<std::string, float>> effect_parameters_group;
        std::map<std::string, std::string> effect_chunks;
        std::map<std::string, std::string> effect_misc;
        std::vector<std::string> input_files;
        std::vector<std::string> output_files;

        bool isMiscExists(const std::string& key) const {
            return effect_misc.find(key) != effect_misc.end();
        }

        const std::string getMisc(const std::string& key, const char* def = "") const {
            if(isMiscExists(key)) { return effect_misc.at(key); }

            return def;
        }
    };

    class YamlCaseInfo {
    public:
        std::string case_name;
        std::vector<std::string> input_files;
        std::vector<std::string> output_files;
        std::map<std::string, std::string> metadata;
        std::string effect_yaml_txt;
        AudioEffectType effect_type;
        int version;

        std::string generateOutputfileName() const {
            if(output_files[0] == "none") {
                std::vector<std::string> splits;
                splitString(input_files[0], splits, "/");

                return case_name + "_" + splits.back();
            } else
                return output_files[0];
        }

    private:
        void splitString(const std::string& s, std::vector<std::string>& v, const std::string& c) const {
            std::string::size_type pos1, pos2;
            pos2 = s.find(c);
            pos1 = 0;
            while(std::string::npos != pos2) {
                v.push_back(s.substr(pos1, pos2 - pos1));

                pos1 = pos2 + c.size();
                pos2 = s.find(c, pos1);
            }
            if(pos1 != s.length()) v.push_back(s.substr(pos1));
        }
    };

}  // namespace mammon
