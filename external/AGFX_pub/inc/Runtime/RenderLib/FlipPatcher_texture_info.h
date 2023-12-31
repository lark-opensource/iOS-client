#pragma once

#include <string>
#include <vector>

struct TexFuncInfo
{
    std::string name;
    std::string origName;
    std::vector<std::string> decl;
    std::vector<std::string> def;
};
std::vector<TexFuncInfo> getTexFuncInfos_300es();
std::vector<TexFuncInfo> getTexFuncInfos_100es();
