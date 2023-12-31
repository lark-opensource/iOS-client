//
// Created by william on 2019-06-10.
//

#pragma once
#include <string>
#include "ae_yaml_tools.h"
namespace mammon {
    class AEYAMLParse {
    public:
        AEYAMLParse();

        bool load(std::istream& input);

        bool load(const std::string& yaml_text);

        bool loadFile(const std::string& in_file);

        const std::vector<YamlCaseInfo>& getCaseInfoArray() const;

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

    class YAMLParse4Cmd {
    public:
        YAMLParse4Cmd();
        ~YAMLParse4Cmd() = default;

        int load(std::istream& input);

        int load(const std::string& input);

        int loadFile(const std::string& in_file);

        const std::string getPresetRoot() const;

        int loadFileWithCheck(const std::string& in_file);

        const std::vector<CmdParameters>& getCmdParamtersArray() const;

        int getNumberOfCmds() const;

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
