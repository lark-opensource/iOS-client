// Copyright 2019 The Lynx Authors. All rights reserved.
#include "base/string/string_utils.h"

#include <algorithm>
#include <array>
#include <cinttypes>
#include <cstring>
#include <sstream>
#include <string>

#include "base/debug/lynx_assert.h"

#if defined(OS_WIN)
#include <cstdarg>
#endif

namespace lynx {
namespace base {
const char kWhitespaceASCII[] = {0x09,  // CHARACTER TABULATION
                                 0x0A,  // LINE FEED (LF)
                                 0x0B,  // LINE TABULATION
                                 0x0C,  // FORM FEED (FF)
                                 0x0D,  // CARRIAGE RETURN (CR)
                                 0x20,  // SPACE
                                 0};

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

bool SplitStringBySpaceOutOfBrackets(const std::string& target,
                                     std::vector<std::string>& result) {
  size_t i = 0, len = target.length(), start = i, bracket = 0;
  while (i < len) {
    bool is_last = i == len - 1;
    char current_char = target[i];
    if (current_char == '(') {
      ++bracket;
    } else if (current_char == ')') {
      --bracket;
    }
    if (bracket > 0 || !isspace(current_char)) {
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

std::string JoinString(const std::vector<std::string>& pieces) {
  std::string joined;
  for (const auto& piece : pieces) {
    joined += piece + " ";
  }
  return joined;
}

bool EndsWith(const std::string& s, const std::string& ending) {
  if (s.length() >= ending.length()) {
    return (0 ==
            s.compare(s.length() - ending.length(), ending.length(), ending));
  } else {
    return false;
  }
}

// flexDirection => flex-direction
// backgroundColor => background-color
// width => width
// line-height => line-height
std::string CamelCaseToDashCase(const std::string& camel_case_property) {
  std::string dash_case_property;
  // "A" -> "-a" 2
  // The upper bound of length of responding dash_case_property
  // is 2 times the original one
  dash_case_property.reserve(camel_case_property.length() * 2);

  for (const auto& c : camel_case_property) {
    if (c >= 'A' && c <= 'Z') {
      dash_case_property.push_back('-');
      dash_case_property.push_back(std::tolower(c));
    } else {
      dash_case_property.push_back(c);
    }
  }

  return dash_case_property;
}

void TrimWhitespaceASCII(const std::string& input, int position,
                         std::string* output) {
  size_t first_good_char = std::string::npos;
  for (char c : kWhitespaceASCII) {
    size_t pos = input.find_first_not_of(c, position);
    if (pos == std::string::npos) continue;
    if (first_good_char == std::string::npos) first_good_char = pos;
    first_good_char = first_good_char < pos ? pos : first_good_char;
  }

  size_t last_good_char = input.size();
  for (char c : kWhitespaceASCII) {
    size_t pos = input.find_last_not_of(c, position);
    if (pos == std::string::npos) continue;
    last_good_char = last_good_char > pos ? last_good_char : pos;
  }

  if (input.empty() || first_good_char == std::string::npos ||
      last_good_char == std::string::npos) {
    output->clear();
    return;
  }

  *output = input.substr(first_good_char, last_good_char - first_good_char + 1);
  return;
}

std::string StringToLowerASCII(const std::string& input) {
  std::string output;
  output.reserve(input.size());
  for (char i : input) {
    if (i >= 'A' && i <= 'Z') {
      output.push_back(i - ('A' - 'a'));
    } else {
      output.push_back(i);
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

//
// Splits string by pattern in the char vector and following the order in
// vector. Won't spilt wrap by '', () or "" as string.
//
// "color: white; font-size: 100" => {"color", " white", " font-size", " 100"}
// "color:white; :font-size:100" => {"color", " white"}
// "color:white;:;width:100" => {"color", "white", "", "", "width","100"}
// "width: 200px; height: 200px;background-image: url('https://xxxx.jpg');"
// "width: 200px; height: 200px;background-image: url(https://xxxx.jpg);"
std::vector<std::string> SplitStringByCharsOrderly(
    const std::string& str, const std::vector<char>& cs) {
  const char* byte_array = str.c_str();
  size_t size = strlen(byte_array);
  std::vector<std::string> result;
  if (!size || cs.empty()) {
    result.push_back(str);
    return result;
  }
  char characters[256];
  memset(&characters[0], 0, 256);
  for (char c : cs) {
    switch (c) {
      case '{':
      case '}':
      case '(':
      case ')':
      case '\"':
      case '\'': {
        return {};
      }
      default:
        break;
    }
    characters[static_cast<int>(c)] = 1;
  }

  std::string value;
  int word_start = -1;
  uint32_t word_count = 0;
  bool word_produced = false;
  int order = 0;
  std::vector<std::string> grouper;
  bool is_variable = false;
  bool is_string = false;
  int end_char = -1;
  for (int i = 0; static_cast<size_t>(i) < size; ++i) {
    char c = byte_array[i];
    if (!is_variable && !is_string && cs[order % cs.size()] == c) {
      word_produced = true;
      order++;
    } else if (!is_variable && !is_string && characters[static_cast<int>(c)]) {
      // restart
      order = 0;
      word_start = -1;
      word_count = 0;
      grouper.clear();
    } else {
      if (c == '{') {
        is_variable = true;
      } else if (is_variable && c == '}') {
        is_variable = false;
      }
      if ((c == '\'' || c == '\"' || c == '(') && !is_string) {
        is_string = true;
        if (c == '(') {
          end_char = ')';
        } else {
          end_char = c;
        }
      } else if (is_string && c == end_char) {
        is_string = false;
        end_char = -1;
      }
      word_start = word_start == -1 ? i : word_start;
      word_count++;
    }
    if (word_produced || (static_cast<size_t>(i) == size - 1 && word_count)) {
      // consumed
      if (word_count) {
        grouper.emplace_back(byte_array, word_start, word_count);
      } else {
        grouper.emplace_back("");
      }
      word_start = -1;
      word_count = 0;

      if (grouper.size() == cs.size()) {
        // output
        result.insert(result.end(), grouper.begin(), grouper.end());
      }

      if (order % cs.size() == 0) {
        grouper.clear();
      }

      word_produced = false;
    }
  }
  return result;
}

void ReplaceAll(std::string& subject, const std::string& search,
                const std::string& replace) {
  size_t pos = 0;
  while ((pos = subject.find(search, pos)) != std::string::npos) {
    subject.replace(pos, search.length(), replace);
    pos += replace.length();
  }
}

std::string SafeStringConvert(const char* str) {
  return str == nullptr ? std::string() : str;
}

std::string PtrToStr(void* ptr) {
  // TODO(heshan):use std::to_chars instead when support c++17
  char temp[20]{0};
  // for hexadecimal, begin with 0x
#ifndef __EMSCRIPTEN__
  std::snprintf(temp, sizeof(temp), "0x%" PRIxPTR,
                reinterpret_cast<std::uintptr_t>(ptr));
#else
  // emcc not qualify cpp standard, use uint32 for PRIxPTR in 64bit...
  // so use zx instead...
  std::snprintf(temp, sizeof(temp), "0x%zx",
                reinterpret_cast<std::uintptr_t>(ptr));
#endif
  return temp;
}

// (1,2, 3,4) ==> vector:{1,2,3,4}
bool ConvertParenthesesStringToVector(std::string& origin,
                                      std::vector<std::string>& ret,
                                      char separator) {
  origin.erase(remove_if(origin.begin(), origin.end(), isspace), origin.end());
  auto start = origin.find("(");
  auto end = origin.find(")");
  if (start >= end) {
    return false;
  }
  origin = origin.substr(start + 1, end - start - 1);
  return base::SplitString(origin, separator, ret);
}

std::vector<std::string> SplitStringIgnoreBracket(std::string str,
                                                  char delimiter) {
  int start = 0;
  std::vector<std::string> result;
  bool has_bracket = false;
  for (int i = 0; static_cast<size_t>(i) < str.size(); i++) {
    if (str[i] == delimiter) {
      if (has_bracket) {
        continue;
      } else {
        if (i > start) {
          result.push_back(TrimString(str.substr(start, i - start)));
        }
        start = i + 1;
      }
    } else if (str[i] == '(') {
      has_bracket = true;
    } else if (str[i] == ')') {
      has_bracket = false;
    }
  }
  if (static_cast<size_t>(start) < str.size()) {
    result.push_back(TrimString(str.substr(start, str.size() - start)));
  }
  return result;
}

bool BothAreSpaces(char lhs, char rhs) {
  return (lhs == rhs) && (isspace(lhs));
}

// "a b    c  d   " => "a b c d "
void ReplaceMultiSpaceWithOne(std::string& str) {
  std::string::iterator new_end =
      std::unique(str.begin(), str.end(), &BothAreSpaces);
  str.erase(new_end, str.end());
}

// if \n, \r, \t in \"\", exec the following replace actions
// '\n' => "\n"
// '\r' => "\r"
// '\t' => "\t"
// "\"a\"" => "\"a\""
//  "\"a\nb\"" => "\"a\\nb\""
// "( x? \"a\" : \"b\")" => "( x? \"a\" : \"b\")"
// "( x ? \n \"a\" : \n\"b\")" => "( x ? \n \"a\" : \n\"b\")"
// "( x ? \n\"a \nc\": \n\"b\"" => "( x ? \n\"a \\nc\": \n\"b\""
// "( x ? \n a : \n b)" => "( x ? \n a : \n b)"
void ReplaceEscapeCharacterWithLiteralString(std::string& input) {
  int newline_count = 0;
  int double_quotes_count = 0;
  bool pre_is_escape = false;
  for (auto c : input) {
    if (c == '\\') {
      pre_is_escape = true;
      continue;
    }
    if (!pre_is_escape && c == '\"') {
      ++double_quotes_count;
    }
    if (c == '\r' || c == '\n' || c == '\t') {
      if (double_quotes_count % 2 == 1) {
        ++newline_count;
      }
    }
    pre_is_escape = false;
  }
  size_t len = input.size();
  input.resize(len + newline_count);
  size_t left = len - 1;
  size_t right = input.size() - 1;
  auto insert_back_slash = [](std::string& str, size_t& index) {
    --index;
    str[index] = '\\';
  };

  double_quotes_count = 0;
  while (left < right) {
    if (input[left] == '\"') {
      if (left == 0 || input[left - 1] != '\\') {
        ++double_quotes_count;
      }
    }
    if (double_quotes_count % 2 == 0) {
      input[right] = input[left];
      --right;
      --left;
      continue;
    }
    if (input[left] == '\n') {
      input[right] = 'n';
      insert_back_slash(input, right);
    } else if (input[left] == '\r') {
      input[right] = 'r';
      insert_back_slash(input, right);
    } else if (input[left] == '\t') {
      input[right] = 't';
      insert_back_slash(input, right);
    } else {
      input[right] = input[left];
    }
    --right;
    --left;
  }
}

namespace {
// Enum the number of bytes of UTF-8 characters.
enum UTF8_byte : size_t {
  kError = 0,
  kOneByte,
  kTwoBytes,
  kThreeBytes,
  kFourBytes
};

// Determine the number of bytes based on the first byte of UTF-8 characters.
// And check the validity of first byte of a UTF-8 character.
inline UTF8_byte GetUtf8ByteCount(char ch) {
  // Range of the first byte of UTF-8 characters for different types.
  constexpr uint8_t kOneByteFirstByteMin = 0;
  constexpr uint8_t kOneByteFirstByteMax = 0x80;
  constexpr uint8_t kTwoBytesFirstByteMin = 0xC2;
  constexpr uint8_t kTwoBytesFirstByteMax = 0xE0;
  constexpr uint8_t kThreeBytesFirstByteMin = 0xE0;
  constexpr uint8_t kThreeBytesFirstByteMax = 0xF0;
  constexpr uint8_t kFourBytesFirstByteMin = 0xF0;
  constexpr uint8_t kFourBytesFirstByteMax = 0xF8;
  // Judge the type of UTF-8 character.
  uint8_t temp = static_cast<uint8_t>(ch);
  if (kOneByteFirstByteMin <= temp && temp < kOneByteFirstByteMax) {
    return UTF8_byte::kOneByte;
  }
  if (kTwoBytesFirstByteMin <= temp && temp < kTwoBytesFirstByteMax) {
    return UTF8_byte::kTwoBytes;
  }
  if (kThreeBytesFirstByteMin <= temp && temp < kThreeBytesFirstByteMax) {
    return UTF8_byte::kThreeBytes;
  }
  if (kFourBytesFirstByteMin <= temp && temp < kFourBytesFirstByteMax) {
    return UTF8_byte::kFourBytes;
  }
  return UTF8_byte::kError;
}

// Check the validity of later bytes of a UTF-8 character.
inline bool CheckChU8LaterByte(char ch) {
  constexpr uint8_t kLaterByteMin = 0x80;
  constexpr uint8_t kLaterByteMax = 0xC0;
  uint8_t temp = static_cast<uint8_t>(ch);
  return kLaterByteMin <= temp && temp < kLaterByteMax;
}

// Convert UTF-32 character to UTF-16 character.
bool ConvertChUtf32ToChUtf16(char32_t utf32_ch,
                             std::array<char16_t, 2>& utf16_ch) {
  constexpr char32_t kUtf32MaxRange = 0x10FFFF;
  constexpr char32_t kUtf16TwoBytesMaxRange = 0x10000;
  constexpr char32_t kUtf16FirstBytePrefix = 0xD800;
  constexpr char32_t kUtf16SecondBytePrefix = 0xDC00;
  if (utf32_ch > kUtf32MaxRange) {
    return false;
  }
  if (utf32_ch < kUtf16TwoBytesMaxRange) {
    utf16_ch[0] = static_cast<char16_t>(utf32_ch);
    utf16_ch[1] = 0;
  } else {
    // Get the high 10 bits of UTF-32 and add UTF-16 the first byte of the
    // prefix.
    utf16_ch[0] = static_cast<char16_t>(
        (utf32_ch - kUtf16TwoBytesMaxRange) / 0x400 + kUtf16FirstBytePrefix);
    // Get the low 10 bits of UTF-32 and add UTF-16 the second byte of the
    // prefix.
    utf16_ch[1] = static_cast<char16_t>(
        (utf32_ch - kUtf16TwoBytesMaxRange) % 0x400 + kUtf16SecondBytePrefix);
  }
  return true;
}

// Convert UTF-8 character to UTF-16 character.
std::pair<bool, std::string> ConvertChUtf8ToChUtf16(
    const std::array<char, 4>& utf8_ch, std::array<char16_t, 2>& utf16_ch) {
  constexpr char kErrOccurInfo[] = "An error occurred in some UTF-8 strings!";
  constexpr char kOutOfRangeInfo[] = "The string is out of the range of UTF-8!";
  // Valid bits of bytes of the UTF-8 character.
  constexpr uint8_t kTwoBytesFirstByteValidBits = 0x1F;
  constexpr uint8_t kThreeBytesFirstByteValidBits = 0x0F;
  constexpr uint8_t kFourBytesFirstByteValidBits = 0x07;
  constexpr uint8_t kLaterByteValidBits = 0x3F;
  char32_t utf32_ch;
  UTF8_byte num_bytes = GetUtf8ByteCount(utf8_ch[0]);
  switch (num_bytes) {
    case UTF8_byte::kOneByte:
      // Convert UTF-8 character to UTF-32 character.
      utf32_ch = static_cast<char32_t>(utf8_ch[0]);
      // Convert UTF-32 character to UTF-16 character.
      if (!ConvertChUtf32ToChUtf16(utf32_ch, utf16_ch)) {
        return {false, kOutOfRangeInfo};
      }
      break;
    case UTF8_byte::kTwoBytes:
      // Check the validity of UTF-8 character.
      if ((static_cast<uint8_t>(utf8_ch[0]) & 0x1E) == 0 ||
          !CheckChU8LaterByte(utf8_ch[1])) {
        return {false, kErrOccurInfo};
      }
      // Convert UTF-8 character to UTF-32 character.
      utf32_ch = static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[0]) & kTwoBytesFirstByteValidBits)
          << 6);
      utf32_ch |= static_cast<char32_t>(static_cast<uint8_t>(utf8_ch[1]) &
                                        kLaterByteValidBits);
      // Convert UTF-32 character to UTF-16 character.
      if (!ConvertChUtf32ToChUtf16(utf32_ch, utf16_ch)) {
        return {false, kOutOfRangeInfo};
      }
      break;
    case UTF8_byte::kThreeBytes:
      // Check the validity of UTF-8 character.
      if ((static_cast<uint8_t>(utf8_ch[0]) & 0x0F) == 0 &&
          (static_cast<uint8_t>(utf8_ch[1]) & 0x20) == 0) {
        return {false, kErrOccurInfo};
      }
      if (!CheckChU8LaterByte(utf8_ch[1]) || !CheckChU8LaterByte(utf8_ch[2])) {
        return {false, kErrOccurInfo};
      }
      // Convert UTF-8 character to UTF-32 character.
      utf32_ch = static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[0]) & kThreeBytesFirstByteValidBits)
          << 12);
      utf32_ch |= static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[1]) & kLaterByteValidBits) << 6);
      utf32_ch |= static_cast<char32_t>(static_cast<uint8_t>(utf8_ch[2])) &
                  kLaterByteValidBits;
      // Convert UTF-32 character to UTF-16 character.
      if (!ConvertChUtf32ToChUtf16(utf32_ch, utf16_ch)) {
        return {false, kOutOfRangeInfo};
      }
      break;
    case UTF8_byte::kFourBytes:
      // Check the validity of UTF-8 character.
      if ((static_cast<uint8_t>(utf8_ch[0]) & 0x07) == 0 &&
          (static_cast<uint8_t>(utf8_ch[1]) & 0x30) == 0) {
        return {false, kErrOccurInfo};
      }
      if (!CheckChU8LaterByte(utf8_ch[1]) || !CheckChU8LaterByte(utf8_ch[2]) ||
          !CheckChU8LaterByte(utf8_ch[3])) {
        return {false, kErrOccurInfo};
      }
      // Convert UTF-8 character to UTF-32 character.
      utf32_ch = static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[0]) & kFourBytesFirstByteValidBits)
          << 18);
      utf32_ch |= static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[1]) & kLaterByteValidBits) << 12);
      utf32_ch |= static_cast<char32_t>(
          (static_cast<uint8_t>(utf8_ch[2]) & kLaterByteValidBits) << 6);
      utf32_ch |= static_cast<char32_t>(static_cast<uint8_t>(utf8_ch[3])) &
                  kLaterByteValidBits;
      // Convert UTF-32 character to UTF-16 character.
      if (!ConvertChUtf32ToChUtf16(utf32_ch, utf16_ch)) {
        return {false, kOutOfRangeInfo};
      }
      break;
    default:
      return {false, kErrOccurInfo};
      break;
  }

  return {true, ""};
}

// Enum the number of bytes of UTF-16 characters.
enum UTF16_byte : size_t {
  kU16Error = 0,
  kU16OneByte,
  kU16TwoBytes,
};

// Determine the number of bytes of UTF-16 characters.
inline UTF16_byte GetUtf16ByteCount(const std::array<char16_t, 2>& utf16_ch) {
  // Range of UTF-16 characters for different types.
  constexpr uint16_t kOneByteMinRange = 0;
  constexpr uint16_t kOneByteMaxRange = 0xFFFF;
  constexpr uint16_t kTwoBytesFirstByteMin = 0xD800;
  constexpr uint16_t kTwoBytesFirstByteMax = 0xDC00;
  constexpr uint16_t kTwoBytesSecondByteMin = 0xDC00;
  constexpr uint16_t kTwoBytesSecondByteMax = 0xE000;
  // Judge the type of UTF-16 character.
  uint16_t first_byte = static_cast<uint16_t>(utf16_ch[0]);
  uint16_t second_byte = static_cast<uint16_t>(utf16_ch[1]);
  if (second_byte == 0) {
    if (kOneByteMinRange <= first_byte && first_byte <= kOneByteMaxRange) {
      return UTF16_byte::kU16OneByte;
    }
  } else {
    if (kTwoBytesFirstByteMin <= first_byte &&
        first_byte < kTwoBytesFirstByteMax &&
        kTwoBytesSecondByteMin <= second_byte &&
        second_byte < kTwoBytesSecondByteMax) {
      return UTF16_byte::kU16TwoBytes;
    }
    if (kOneByteMinRange <= first_byte && first_byte <= kOneByteMaxRange) {
      return UTF16_byte::kU16OneByte;
    }
  }
  return UTF16_byte::kU16Error;
}

// Convert UTF-16 character to UTF-32 character.
inline bool ConvertChUtf16ToChUtf32(const std::array<char16_t, 2>& utf16_ch,
                                    char32_t& utf32_ch) {
  if (utf16_ch.empty()) {
    return false;
  }
  if (utf16_ch[1] == 0) {
    utf32_ch = static_cast<char32_t>(utf16_ch[0]);
  } else {
    utf32_ch = static_cast<char32_t>(
        (static_cast<uint16_t>(utf16_ch[0]) & 0x03FF) << 10);
    utf32_ch |=
        static_cast<char32_t>((static_cast<uint16_t>(utf16_ch[1]) & 0x03FF));
    utf32_ch += 0x10000;
  }
  return true;
}

// Convert UTF-32 character to UTF-8 character.
bool ConvertChUtf32ToChUtf8(char32_t utf32_ch, std::array<char, 4>& utf8_ch) {
  // Set the range of UTF-8 for different bytes
  constexpr char32_t kUtf8OneByteMinRange = 0;
  constexpr char32_t kUtf8TwoBytesMinRange = 0x0080;
  constexpr char32_t kUtf8ThreeBytesMinRange = 0x0800;
  constexpr char32_t kUtf8FourBytesMinRange = 0x10000;
  constexpr char32_t kUtf8FourBytesMaxRange = 0x10FFFF;
  // Convert to UTF-8 according to the different ranges of UTF-32
  utf8_ch = {0, 0, 0, 0};
  if (kUtf8OneByteMinRange <= utf32_ch && utf32_ch < kUtf8TwoBytesMinRange) {
    utf8_ch[0] = static_cast<char>(utf32_ch);
  } else if (utf32_ch < kUtf8ThreeBytesMinRange) {
    utf8_ch[0] =
        static_cast<char>(0xC0 + (static_cast<uint32_t>(utf32_ch) >> 6));
    utf8_ch[1] =
        static_cast<char>(0x80 + (static_cast<uint32_t>(utf32_ch) & 0x3F));
  } else if (utf32_ch < kUtf8FourBytesMinRange) {
    utf8_ch[0] =
        static_cast<char>(0xE0 + (static_cast<uint32_t>(utf32_ch) >> 12));
    utf8_ch[1] = static_cast<char>(
        0x80 + ((static_cast<uint32_t>(utf32_ch) >> 6) & 0x3F));
    utf8_ch[2] =
        static_cast<char>(0x80 + (static_cast<uint32_t>(utf32_ch) & 0x3F));
  } else if (utf32_ch <= kUtf8FourBytesMaxRange) {
    utf8_ch[0] =
        static_cast<char>(0xF0 + (static_cast<uint32_t>(utf32_ch) >> 18));
    utf8_ch[1] = static_cast<char>(
        0x80 + ((static_cast<uint32_t>(utf32_ch) >> 12) & 0x3F));
    utf8_ch[2] = static_cast<char>(
        0x80 + ((static_cast<uint32_t>(utf32_ch) >> 6) & 0x3F));
    utf8_ch[3] =
        static_cast<char>(0x80 + (static_cast<uint32_t>(utf32_ch) & 0x3F));
  } else {
    return false;
  }
  return true;
}

// convert UTF-16 character to UTF-8 character.
bool ConvertChUtf16ToChUtf8(const std::array<char16_t, 2>& utf16_ch,
                            std::array<char, 4>& utf8_ch) {
  if (utf16_ch.empty()) {
    return false;
  }
  char32_t utf32_ch;
  if (!ConvertChUtf16ToChUtf32(utf16_ch, utf32_ch)) {
    return false;
  }
  if (!ConvertChUtf32ToChUtf8(utf32_ch, utf8_ch)) {
    return false;
  }
  return true;
}

}  // namespace

// utf-8 String ==> utf-16 String
std::pair<bool, std::string> ConvertUtf8StringToUtf16String(
    const std::string& utf8_str, std::u16string& utf16_str) {
  if (utf8_str.empty()) {
    return {false, "The UTF-8 string is empty!"};
  }
  for (auto utf8_iter = utf8_str.begin(); utf8_iter != utf8_str.end();
       ++utf8_iter) {
    UTF8_byte num_bytes = GetUtf8ByteCount((*utf8_iter));
    if (num_bytes == UTF8_byte::kError) {
      return {false, "The string is out of the range of UTF-8!"};
    }
    // Read a single UTF-8 character.
    std::array<char, 4> utf8_ch;
    utf8_ch[0] = (*utf8_iter);
    for (size_t i = 1; i < num_bytes; i++) {
      ++utf8_iter;
      if (utf8_iter == utf8_str.end()) {
        utf16_str.clear();
        return {false, "The UTF-8 string is missing bytes!"};
      }
      utf8_ch[i] = (*utf8_iter);
    }
    // Convert UTF-8 character to UTF-16 character.
    std::array<char16_t, 2> utf16_ch;
    std::pair<bool, std::string> res =
        ConvertChUtf8ToChUtf16(utf8_ch, utf16_ch);
    if (!res.first) {
      return {false, res.second};
    }
    // Save the UTF-16 characters into the UTF-16 string.
    utf16_str.push_back(utf16_ch[0]);
    if (utf16_ch[1] != 0) {
      utf16_str.push_back(utf16_ch[1]);
    }
  }
  return {true, ""};
}

// utf-16 String ==> utf-8 String
std::pair<bool, std::string> ConvertUtf16StringToUtf8String(
    const std::u16string& utf16_str, std::string& utf8_str) {
  if (utf16_str.empty()) {
    return {false, "The UTF-16 string is empty!"};
  }
  constexpr char kOutOfRangeInfo[] =
      "The string is out of the range of UTF-16!";
  std::array<char16_t, 2> utf16_ch;
  // First, take two bytes of the UTF-16 string each time, assuming one
  // character;
  // Second, determine the number of bytes of UTF-16 characters;
  // Finally, do the UTF-16 to UTF-8 conversion with the correct number of
  // bytes.
  for (auto utf16_iter = utf16_str.begin(); utf16_iter != utf16_str.end();
       ++utf16_iter) {
    std::array<char, 4> utf8_ch;
    utf16_ch[0] = (*utf16_iter);
    if ((utf16_iter + 1) != utf16_str.end()) {
      utf16_ch[1] = (*(utf16_iter + 1));
    } else {
      utf16_ch[1] = 0;
    }
    UTF16_byte u16_num_bytes = GetUtf16ByteCount(utf16_ch);
    if (u16_num_bytes == UTF16_byte::kU16Error) {
      utf8_str.clear();
      return {false, kOutOfRangeInfo};
    }
    if (u16_num_bytes == UTF16_byte::kU16OneByte) {
      utf16_ch[1] = 0;
      if (!ConvertChUtf16ToChUtf8(utf16_ch, utf8_ch)) {
        utf8_str.clear();
        return {false, kOutOfRangeInfo};
      }
    }
    if (u16_num_bytes == UTF16_byte::kU16TwoBytes) {
      ++utf16_iter;
      if (!ConvertChUtf16ToChUtf8(utf16_ch, utf8_ch)) {
        utf8_str.clear();
        return {false, kOutOfRangeInfo};
      }
    }
    for (char i : utf8_ch) {
      if (i != 0) {
        utf8_str.push_back(i);
      }
    }
  }
  return {true, ""};
}

std::string FormatStringWithVaList(const char* format, va_list args) {
  int length, size = 100;
  char* mes = nullptr;
  if ((mes = static_cast<char*>(malloc(size * sizeof(char)))) == nullptr) {
    return "";
  }
  while (true) {
    va_list copy_args;
    va_copy(copy_args, args);
    length = vsnprintf(mes, size, format, copy_args);
    va_end(copy_args);
    if (length > -1 && length < size) break;
    size *= 2;
    char* clone = static_cast<char*>(realloc(mes, size * sizeof(char)));
    if (clone == nullptr) {
      break;
    } else {
      mes = clone;
      clone = nullptr;
    }
  }
  std::string message = mes;
  free(mes);
  mes = nullptr;
  return message;
}

std::string FormatString(const char* format, ...) {
  std::string error_msg;
  va_list args;
  va_start(args, format);
  error_msg = FormatStringWithVaList(format, args);
  va_end(args);
  return error_msg;
}

}  // namespace base
}  // namespace lynx
