// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_PATH_PARSER_H_
#define LYNX_LEPUS_PATH_PARSER_H_

#include <stdio.h>

#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>

#include "base/log/logging.h"

namespace lynx {
namespace lepus {

// handle value path
// a.b => [a, b]
// a[3] => [a, 3]
// returns an empty vector if path is invalid
static std::vector<std::string> ParseValuePath(const std::string &path) {
  std::vector<std::string> path_array;
  std::stringstream result;
  bool array_start_ = false;
  bool num_in_array_ = false;
  int digits = 0;
  std::size_t length = path.length();
  for (std::size_t index = 0; index < length; ++index) {
    char c = path[index];
    if (c == '.') {
      std::string ss = result.str();
      result.clear();
      result.str("");
      if (ss.length() > 0) {
        path_array.emplace_back(ss);
      }
    } else if (c == '[') {
      if (array_start_) {
        LOGE("Data Path Error, Path can not have nested []. Path: " << path);
        return {};
      }
      std::string ss = result.str();
      result.clear();
      result.str("");
      if (ss.length() > 0) {
        path_array.emplace_back(ss);
      }
      if (path_array.empty()) {
        LOGE("Data Path Error, Path can not start with []. Path: " << path);
        return {};
      }
      array_start_ = true;
      num_in_array_ = false;
    } else if (c == ']') {
      if (!num_in_array_) {
        LOGE("Data Path Error, Must has number in []. Path: " << path);
        return {};
      }
      array_start_ = false;
      path_array.emplace_back(std::to_string(digits));
      digits = 0;

      // there may have escape number in brackets like:
      // a[\1]
      // should clear result here
      result.clear();
      result.str("");
    } else if (c == '\\') {
      if (index == length - 1) {
        result << c;
        break;
      }

      char next = path[index + 1];
      if (next == '[' || next == ']' || next == '.') {
        // escape special char
        result << next;
        index++;
      } else {
        result << '\\';
      }
    } else if (array_start_) {
      if (c < '0' || c > '9') {
        LOGE("Data Path Error, Only number 0-9 could be inside []. Path: "
             << path);
        return {};
      }
      num_in_array_ = true;
      digits = 10 * digits + (c - '0');
    } else {
      result << c;
    }
  }
  if (array_start_) {
    LOGE("Data Path Error, [] should appear in pairs. Path: " << path);
    return {};
  }
  std::string ss = result.str();
  result.clear();
  result.str("");
  if (ss.length() > 0) {
    path_array.emplace_back(ss);
  }
  return path_array;
}

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_PATH_PARSER_H_
