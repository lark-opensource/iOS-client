// Copyright 2019 The Lynx Authors. All rights reserved.
#include "canvas/util/string_utils.h"

#include <cinttypes>
#include <cstring>
#include <sstream>

#include "base/debug/lynx_assert.h"
namespace lynx {
namespace canvas {
bool SplitString(const std::string& target, char separator,
                 std::vector<std::string>& result) {
  size_t i = 0, len = target.length(), start = i;
  while (i < len) {
    bool is_last = i == len - 1;
    char current_char = target[i];
    if (current_char != separator) {
      if (is_last) {
        result.push_back(target.substr(start));
      }
    } else {
      if (i == start) {
        start++;
      } else {
        result.push_back(target.substr(start, i - start));
        start = i + 1;
      }
    }
    i++;
  }
  return !result.empty();
}

bool EndsWith(const std::string& s, const std::string& ending) {
  if (s.length() >= ending.length()) {
    return (0 ==
            s.compare(s.length() - ending.length(), ending.length(), ending));
  } else {
    return false;
  }
}

std::string StringToLowerASCII(const std::string& input) {
  std::string output;
  output.reserve(input.size());
  for (int i = 0; i < input.size(); ++i) {
    if (input[i] >= 'A' && input[i] <= 'Z') {
      output.push_back(input[i] - ('A' - 'a'));
    } else {
      output.push_back(input[i]);
    }
  }
  return output;
}

//
// Uses for trim blank around string off.
//    " aa "     =>   "aa"
//    " a  a "   =>   "a  a"
//
std::string TrimString(const std::string& str) {
  if (str.empty()) return str;
  size_t length = str.size();
  uint32_t front_space_count = 0;
  uint32_t back_space_count = 0;
  uint32_t total_space_count = 0;
  while (front_space_count < length && str[front_space_count] == ' ') {
    front_space_count++;
    break;
  }
  while (front_space_count + back_space_count < length &&
         str[length - back_space_count - 1] == ' ') {
    back_space_count++;
    break;
  }
  total_space_count = front_space_count + back_space_count;
  return str.substr(front_space_count, length - total_space_count);
}

bool EndsWithIgnoreSourceCase(const std::string& s, const std::string& ending) {
  return EndsWith(StringToLowerASCII(s), ending);
}

bool EqualsIgnoreCase(const std::string& left, const std::string& right) {
  auto left_lower = StringToLowerASCII(left);
  auto right_lower = StringToLowerASCII(right);

  return left_lower == right_lower;
}
}  // namespace canvas
}  // namespace lynx
