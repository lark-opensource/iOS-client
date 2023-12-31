// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_STRING_UTILS_H_
#define CANVAS_UTIL_STRING_UTILS_H_

#include <sstream>
#include <string>
#include <vector>

#include "base/base_export.h"

namespace lynx {
namespace canvas {
bool SplitString(const std::string& target, char separator,
                 std::vector<std::string>& result);

bool EndsWith(const std::string& s, const std::string& ending);

bool EndsWithIgnoreSourceCase(const std::string& s, const std::string& ending);

std::string StringToLowerASCII(const std::string& input);

// String utils
std::string TrimString(const std::string& str);

bool EqualsIgnoreCase(const std::string& left, const std::string& right);

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_STRING_UTILS_H_
