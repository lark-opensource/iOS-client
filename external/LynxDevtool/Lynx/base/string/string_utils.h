// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_STRING_STRING_UTILS_H_
#define LYNX_BASE_STRING_STRING_UTILS_H_

#include <array>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "base/base_export.h"

namespace lynx {
namespace base {
inline bool BeginsWith(const std::string& s, const std::string& begin) {
  if (s.length() >= begin.length()) {
    return (0 == s.compare(0, begin.length(), begin));
  } else {
    return false;
  }
}

bool SplitString(const std::string& target, char separator,
                 std::vector<std::string>& result);

bool SplitStringBySpaceOutOfBrackets(const std::string& target,
                                     std::vector<std::string>& result);

std::string JoinString(const std::vector<std::string>& pieces);

std::string CamelCaseToDashCase(const std::string&);

BASE_EXPORT_FOR_DEVTOOL bool EndsWith(const std::string& s,
                                      const std::string& ending);

BASE_EXPORT_FOR_DEVTOOL void TrimWhitespaceASCII(const std::string& input,
                                                 int position,
                                                 std::string* output);
BASE_EXPORT_FOR_DEVTOOL std::string StringToLowerASCII(
    const std::string& input);

namespace internal {
template <class T>
void AppendStringImpl(std::stringstream& ss, const T& head) {
  ss << head;
}

template <class T, class... Args>
void AppendStringImpl(std::stringstream& ss, const T& head,
                      const Args&... args) {
  ss << head;
  AppendStringImpl(ss, args...);
}
}  // namespace internal

template <class... Args>
std::string AppendString(const Args&... args) {
  if constexpr (sizeof...(Args) > 0) {
    std::stringstream ss;
    internal::AppendStringImpl(ss, args...);
    return ss.str();
  }
  return {};
}

// String utils
std::string TrimString(const std::string& str);
std::vector<std::string> SplitStringByCharsOrderly(const std::string& str,
                                                   const std::vector<char>& cs);
void ReplaceAll(std::string& str, const std::string& from,
                const std::string& to);

std::string SafeStringConvert(const char* str);

std::string PtrToStr(void* ptr);

// (1,2, 3,4) ==> vector:{1,2,3,4}
bool ConvertParenthesesStringToVector(std::string& origin,
                                      std::vector<std::string>& ret,
                                      char separator = ',');
// delimiter=",": "a,b,(1,2,3),d" =>[a,b,(1,2,3),d]
std::vector<std::string> SplitStringIgnoreBracket(std::string str,
                                                  char delimiter);

// this method will modify input str.
// "a b    c  d   " => "a b c d "
void ReplaceMultiSpaceWithOne(std::string& str);

// The purpose of this function is to replace \n, \r, and \t in \"\" with \\n,
// \\r, and \\t, respectively, to avoid lepusNG generating code cache failure.
// Now, this function is only used in the encoder.
void ReplaceEscapeCharacterWithLiteralString(std::string& input);

// utf-8 String ==> utf-16 String
std::pair<bool, std::string> ConvertUtf8StringToUtf16String(
    const std::string& utf8_str, std::u16string& utf16_str);

// utf-16 String ==> utf-8 String
std::pair<bool, std::string> ConvertUtf16StringToUtf8String(
    const std::u16string& utf16_str, std::string& utf8_str);

std::string FormatStringWithVaList(const char* format, va_list args);
std::string FormatString(const char* format, ...);

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_STRING_STRING_UTILS_H_
