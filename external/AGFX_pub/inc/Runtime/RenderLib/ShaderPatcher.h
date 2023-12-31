#ifndef SHADERPATCHER_H
#define SHADERPATCHER_H

#include <string>
#include <functional>

#include "FlipPatcher_texture_info.h"

#include "Gaia/AMGPrerequisites.h"
#include "Runtime/RenderLib/RendererDeviceTypes.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class ShaderPatcher
{
public:
    struct TexFlipUniformInfo
    {
        SymbolType type;
        std::string name;
        int index;
    };
    AMAZING_EXPORT static std::string patch(AMGShaderType shaderType, std::string source, std::unordered_map<std::string, size_t>& samplerNames, int maxUniformVector);
    static TexFlipUniformInfo getFlipTexUniformInfo(size_t index);
    static std::string getFlipTextureSwitchVariableName(std::string const& name);
    static std::string getFlipTextureSwitchUniformName(size_t index);
    AMAZING_EXPORT static void useOldPatcher(bool v);

protected:
    static bool isWordChar(char c)
    {
        return std::isalnum(c) || c == '_';
    }
    static bool iswhitespace(char c)
    {
        return std::isspace(c) != 0;
    }
    static size_t forward_if(std::string const& src, size_t pos, bool (*pred)(char));
    static size_t backward_if(std::string const& src, size_t pos, bool (*pred)(char));
    static size_t nextToken(std::string const& src, size_t pos, std::string& token);
    static size_t prevToken(std::string const& src, size_t pos, std::string& token);
    static size_t findToken(std::string token, std::string const& src, size_t pos = 0);
    static size_t findClosingBrace(std::string const& src, size_t pos);
    static size_t find_token_and_process_new(std::string& src, std::string const& token, std::function<long(std::string&, size_t&)> process, size_t begin = 0ul, size_t end = std::string::npos);
    static std::string getTokenBeforeParam(std::string const& src, size_t pos);
    static size_t getTokenBeforeParam(std::string const& src, size_t pos, std::string& token);
    static bool isFunctionParam(std::string const& src, size_t pos);
    static size_t functionBegin(std::string const& src, size_t pos);
    static bool isFunctionCall(std::string const& src, size_t pos);
    static bool isFunctionDef(std::string const& src, size_t pos);
    static void removeComment(std::string& src);
    static std::unordered_map<std::string, TexFlipUniformInfo> const& flipTexUniformMap();

    static void updateSamplerNames(std::string& source, std::vector<std::string> const& samplerTokens, std::unordered_map<std::string, size_t>& samplerNames);
    static std::unordered_map<std::string, size_t> buildSamplerAliasMap(std::string& source, std::unordered_map<std::string, size_t> const& samplerNames);
    static void addFlipUniformDef(std::string& source, std::unordered_map<std::string, size_t> const& samplerNames);
    static void addDefaultPrecisionQualifier(std::string& source, int version, AMGShaderType shaderType);
    static size_t findPosForUniformDef(std::string const& source);
    static void patchUsageOfSamplers(std::string& source, std::unordered_map<std::string, size_t> const& samplerAliasMap, std::vector<TexFuncInfo> const& texFuncInfos, std::set<std::string>& patchedFunctions);
    static void patchSampler2DParam(std::string& source, std::unordered_map<std::string, size_t> const& samplerAliasMap, std::vector<std::string> const& samplerTokens, std::vector<TexFuncInfo> const& texFuncInfos, std::set<std::string>& patchedFunctions);
    static void addTexture2DFlipFuncDecl(std::string& source, std::set<std::string> const& funcs, std::vector<TexFuncInfo> const& texFuncInfos, int version, AMGShaderType shaderType);
    static void addTexture2DFlipFuncDef(std::string& source, std::set<std::string> const& funcs, std::vector<TexFuncInfo> const& texFuncInfos, AMGShaderType shaderType);
#if AGFX_USE_GPUINFO_COLLECTION
public:
    static int getVersion(std::string const& source);

protected:
#else
    static int getVersion(std::string const& source);
#endif
    static void patchInputTextures(int version, AMGShaderType shaderType, std::string& source, std::unordered_map<std::string, size_t>& samplerNames);
    static void patchOutputRt(std::string& source);
    static bool patchFragCoord(std::string& source);
    static void addScreenHeightUniform(std::string& source);
    static void addFragCoordFuncDecl(std::string& source);
    static void addFragCoordFuncDef(std::string& source);
    static void patchLargeMat4Array(std::string& source);
};

class ShaderPatcherV2
{
protected:
    int _version = 200;

public:
    static auto getFlipTexUniformInfo(size_t index) -> ShaderPatcher::TexFlipUniformInfo
    {
        return {SymbolType::FLOAT_VEC4, "u_is_texture_" + std::to_string(index / 4u) + "_flip_", static_cast<int>(index % 4u)};
    }
    std::string patch(AMGShaderType shaderType, std::string source, std::unordered_map<std::string, size_t>& samplerNames, int maxUniformVector);

protected:
    void patchInputTextures(AMGShaderType shaderType, std::string& source, std::unordered_map<std::string, size_t>& samplerNames);
    void addDefaultPrecisionQualifier(std::string& source, AMGShaderType shaderType);
    size_t patchTextureCall(std::string& src, size_t pos, std::string flipParam, std::set<std::string>& patchedFunctions);

    void patchUsageOfSamplers(std::string& source, std::unordered_map<std::string, size_t> const& samplerAliasMap, std::set<std::string>& patchedFunctions);
    void patchSampler2DParam(std::string& source, std::unordered_map<std::string, size_t> const& samplerAliasMap, std::vector<std::string> const& samplerTokens, std::set<std::string>& patchedFunctions);

    void addTexture2DFlipFuncDecl(std::string& source, std::set<std::string> const& funcs);
    void addTexture2DFlipFuncDef(std::string& source, std::set<std::string> const& funcs);
    size_t findPosForUniformDef(std::string const& source);
    std::string getFlipTextureSwitchUniformName(size_t index);
    void updateSamplerNames(std::string& source, std::vector<std::string> const& samplerTokens, std::unordered_map<std::string, size_t>& samplerNames);
    std::unordered_map<std::string, size_t> buildSamplerAliasMap(std::string& source, std::unordered_map<std::string, size_t> const& samplerNames);
    bool patchFragCoord(std::string& source);
    void addScreenHeightUniform(std::string& source);
    void addFlipUniformDef(std::string& source, std::unordered_map<std::string, size_t> const& samplerNabmes);
    void addFragCoordFuncDecl(std::string& source);
    void addFragCoordFuncDef(std::string& source);
    void patchLargeMat4Array(std::string& source, int maxUniformVector);
    int getVersion(std::string const& source);
    void patchOutputRt(std::string& source);
};

NAMESPACE_AMAZING_ENGINE_END

#endif
