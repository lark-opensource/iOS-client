// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_NG_PARSER_ASCII_CTYPE_H_
#define LYNX_CSS_NG_PARSER_ASCII_CTYPE_H_

#include "css/ng/css_utils.h"

namespace lynx {
namespace css {

constexpr bool IsASCII(UChar c) { return !(c & ~0x7F); }

constexpr bool IsASCIINumber(UChar c) { return c >= '0' && c <= '9'; }

constexpr bool IsASCIIHexNumber(UChar c) {
  return ((c | 0x20) >= 'a' && (c | 0x20) <= 'f') || IsASCIINumber(c);
}

constexpr int ToASCIIHexValue(UChar c) {
  return c < 'A' ? c - '0' : (c - 'A' + 10) & 0xF;
}

constexpr bool IsASCIIAlphaCaselessEqual(UChar css_character, char character) {
  // This function compares a (preferably) constant ASCII
  // lowercase letter to any input character.
  DCHECK(character >= 'a');
  DCHECK(character <= 'z');
  return (css_character | 0x20) == character;
}

constexpr bool IsASCIISpace(UChar c) {
  return c <= ' ' && (c == ' ' || (c <= 0xD && c >= 0x9));
}

template <typename CharType>
constexpr bool IsHTMLSpace(CharType character) {
  return character <= ' ' &&
         (character == ' ' || character == '\n' || character == '\t' ||
          character == '\r' || character == '\f');
}

constexpr bool IsSpaceOrNewline(UChar c) {
  return IsASCII(c) && c <= ' ' && (c == ' ' || (c <= 0xD && c >= 0x9));
}

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_PARSER_ASCII_CTYPE_H_
