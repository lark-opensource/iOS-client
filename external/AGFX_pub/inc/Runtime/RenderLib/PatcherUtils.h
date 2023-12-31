/**
 * @file PatcherUtils.h
 * @author lishaoyuan (lishaoyuan@bytedance.com)
 * @brief [Deprecated] PatcherUtils 
 * APIs should not be exposed 
 * @version 1.0
 * @date 2021-09-01
 * @copyright Copyright (c) 2021 Bytedance Inc. All rights reserved.
 */
#pragma once

#include <string>
#include <functional>

#include "FlipPatcher_texture_info.h"

#include "Gaia/AMGPrerequisites.h"
#include "Runtime/RenderLib/RendererDeviceTypes.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

namespace PatcherUtils
{

inline bool isWordChar(char c)
{
    return std::isalnum(c) || c == '_';
}
inline bool isWhitespace(char c)
{
    return std::isspace(c) != 0;
}

size_t findClosingBracket(std::string const& src, size_t pos);
size_t getArgument(std::string const& src, size_t pos);
void removeComment(std::string& src);

size_t findToken(std::string token, std::string const& src, size_t pos);
size_t find_token_and_process(std::string& src, std::string const& token, std::function<long(std::string&, size_t&)> process, size_t begin = 0ul, size_t end = std::string::npos);
std::string getTokenBeforeParam(std::string const& src, size_t pos);
size_t getTokenBeforeParam(std::string const& src, size_t pos, std::string& token);
size_t forward_if(std::string const& src, size_t pos, bool (*pred)(char));
size_t backward_if(std::string const& src, size_t pos, bool (*pred)(char));
size_t nextToken(std::string const& src, size_t pos, std::string& token);
size_t prevToken(std::string const& src, size_t pos, std::string& token);
size_t functionBegin(std::string const& src, size_t pos);
bool isFunctionParam(std::string const& src, size_t pos);
bool isFunctionDef(std::string const& src, size_t pos);
bool isFunctionCall(std::string const& src, size_t pos);
size_t findClosingBrace(std::string const& src, size_t pos);

} // namespace PatcherUtils

NAMESPACE_AMAZING_ENGINE_END
