// Copyright 2023 The Lynx Authors. All rights reserved.
#ifndef LYNX_CSS_PARSER_CSS_TOKEN_TYPE_HASH_H_
#define LYNX_CSS_PARSER_CSS_TOKEN_TYPE_HASH_H_
/* C++ code produced by gperf version 3.1 */
/* Command-line: gperf -D -t css_token_type_hash.tmpl  */
/* Computed positions: -k'1,3,$' */

#if !(                                                                         \
    (' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) && ('%' == 37) && \
    ('&' == 38) && ('\'' == 39) && ('(' == 40) && (')' == 41) &&               \
    ('*' == 42) && ('+' == 43) && (',' == 44) && ('-' == 45) && ('.' == 46) && \
    ('/' == 47) && ('0' == 48) && ('1' == 49) && ('2' == 50) && ('3' == 51) && \
    ('4' == 52) && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) && \
    ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) && ('=' == 61) && \
    ('>' == 62) && ('?' == 63) && ('A' == 65) && ('B' == 66) && ('C' == 67) && \
    ('D' == 68) && ('E' == 69) && ('F' == 70) && ('G' == 71) && ('H' == 72) && \
    ('I' == 73) && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) && \
    ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) && ('R' == 82) && \
    ('S' == 83) && ('T' == 84) && ('U' == 85) && ('V' == 86) && ('W' == 87) && \
    ('X' == 88) && ('Y' == 89) && ('Z' == 90) && ('[' == 91) &&                \
    ('\\' == 92) && (']' == 93) && ('^' == 94) && ('_' == 95) &&               \
    ('a' == 97) && ('b' == 98) && ('c' == 99) && ('d' == 100) &&               \
    ('e' == 101) && ('f' == 102) && ('g' == 103) && ('h' == 104) &&            \
    ('i' == 105) && ('j' == 106) && ('k' == 107) && ('l' == 108) &&            \
    ('m' == 109) && ('n' == 110) && ('o' == 111) && ('p' == 112) &&            \
    ('q' == 113) && ('r' == 114) && ('s' == 115) && ('t' == 116) &&            \
    ('u' == 117) && ('v' == 118) && ('w' == 119) && ('x' == 120) &&            \
    ('y' == 121) && ('z' == 122) && ('{' == 123) && ('|' == 124) &&            \
    ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
#error \
    "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gperf@gnu.org>."
#endif

#line 7 "TokenType.gperf"

#include <cstring>

#include "css_string_scanner.h"
namespace lynx {
namespace tasm {
#line 12 "TokenType.gperf"
struct KeywordTypes {
  const char *name;
  lynx::tasm::TokenType type;
};
/* maximum key range = 137, duplicates = 0 */

class ScannerTokenHash {
 private:
  static inline unsigned int hash(const char *str, size_t len);

 public:
  static const struct KeywordTypes *GetTokenType(const char *str, size_t len);
};

inline unsigned int ScannerTokenHash::hash(const char *str, size_t len) {
  static const unsigned char asso_values[] = {
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      0,   140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 60,  45,  20,  20,  25,  85,  40,  50,
      10,  140, 50,  0,   15,  5,   15,  10,  140, 0,   15,  0,   85,  35,  10,
      0,   10,  140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
      140};
  unsigned int hval = static_cast<unsigned int>(len);

  switch (hval) {
    default:
      hval += asso_values[static_cast<unsigned char>(str[2])];
    /*FALLTHROUGH*/
    case 2:
    case 1:
      hval += asso_values[static_cast<unsigned char>(str[0])];
      break;
  }
  return hval + asso_values[static_cast<unsigned char>(str[len - 1])];
}

const struct KeywordTypes *ScannerTokenHash::GetTokenType(const char *str,
                                                          size_t len) {
  enum {
    TOTAL_KEYWORDS = 75,
    MIN_WORD_LENGTH = 2,
    MAX_WORD_LENGTH = 15,
    MIN_HASH_VALUE = 3,
    MAX_HASH_VALUE = 139
  };

  static const struct KeywordTypes token_list[] = {
#line 27 "TokenType.gperf"
      {"rpx", lynx::tasm::TokenType::RPX},
#line 81 "TokenType.gperf"
      {"toleft", lynx::tasm::TokenType::TOLEFT},
#line 82 "TokenType.gperf"
      {"toright", lynx::tasm::TokenType::TORIGHT},
#line 38 "TokenType.gperf"
      {"turn", lynx::tasm::TokenType::TURN},
#line 78 "TokenType.gperf"
      {"normal", lynx::tasm::TokenType::NORMAL},
#line 26 "TokenType.gperf"
      {"px", lynx::tasm::TokenType::PX},
#line 33 "TokenType.gperf"
      {"ppx", lynx::tasm::TokenType::PPX},
#line 45 "TokenType.gperf"
      {"no-repeat", lynx::tasm::TokenType::NO_REPEAT},
#line 83 "TokenType.gperf"
      {"totop", lynx::tasm::TokenType::TOTOP},
#line 44 "TokenType.gperf"
      {"repeat", lynx::tasm::TokenType::REPEAT},
#line 20 "TokenType.gperf"
      {"to", lynx::tasm::TokenType::TO},
#line 42 "TokenType.gperf"
      {"repeat-x", lynx::tasm::TokenType::REPEAT_X},
#line 61 "TokenType.gperf"
      {"thin", lynx::tasm::TokenType::THIN},
#line 51 "TokenType.gperf"
      {"linear-gradient", lynx::tasm::TokenType::LINEAR_GRADIENT},
#line 72 "TokenType.gperf"
      {"outset", lynx::tasm::TokenType::OUTSET},
#line 22 "TokenType.gperf"
      {"top", lynx::tasm::TokenType::TOP},
#line 77 "TokenType.gperf"
      {"local", lynx::tasm::TokenType::LOCAL},
#line 34 "TokenType.gperf"
      {"max-content", lynx::tasm::TokenType::MAX_CONTENT},
#line 32 "TokenType.gperf"
      {"sp", lynx::tasm::TokenType::SP},
#line 43 "TokenType.gperf"
      {"repeat-y", lynx::tasm::TokenType::REPEAT_Y},
#line 71 "TokenType.gperf"
      {"inset", lynx::tasm::TokenType::INSET},
#line 25 "TokenType.gperf"
      {"center", lynx::tasm::TokenType::CENTER},
#line 28 "TokenType.gperf"
      {"rem", lynx::tasm::TokenType::REM},
#line 52 "TokenType.gperf"
      {"radial-gradient", lynx::tasm::TokenType::RADIAL_GRADIENT},
#line 50 "TokenType.gperf"
      {"content-box", lynx::tasm::TokenType::CONTENT_BOX},
#line 41 "TokenType.gperf"
      {"contain", lynx::tasm::TokenType::CONTAIN},
#line 19 "TokenType.gperf"
      {"none", lynx::tasm::TokenType::NONE},
#line 67 "TokenType.gperf"
      {"solid", lynx::tasm::TokenType::SOLID},
#line 49 "TokenType.gperf"
      {"padding-box", lynx::tasm::TokenType::PADDING_BOX},
#line 29 "TokenType.gperf"
      {"em", lynx::tasm::TokenType::EM},
#line 37 "TokenType.gperf"
      {"rad", lynx::tasm::TokenType::RAD},
#line 86 "TokenType.gperf"
      {"calc", lynx::tasm::TokenType::CALC},
#line 23 "TokenType.gperf"
      {"right", lynx::tasm::TokenType::RIGHT},
#line 65 "TokenType.gperf"
      {"dotted", lynx::tasm::TokenType::DOTTED},
#line 30 "TokenType.gperf"
      {"vw", lynx::tasm::TokenType::VW},
#line 54 "TokenType.gperf"
      {"closest-corner", lynx::tasm::TokenType::CLOSEST_CORNER},
#line 70 "TokenType.gperf"
      {"ridge", lynx::tasm::TokenType::RIDGE},
#line 58 "TokenType.gperf"
      {"circle", lynx::tasm::TokenType::CIRCLE},
#line 16 "TokenType.gperf"
      {"hsl", lynx::tasm::TokenType::HSL},
#line 48 "TokenType.gperf"
      {"border-box", lynx::tasm::TokenType::BORDER_BOX},
#line 62 "TokenType.gperf"
      {"medium", lynx::tasm::TokenType::MEDIUM},
#line 57 "TokenType.gperf"
      {"ellipse", lynx::tasm::TokenType::ELLIPSE},
#line 75 "TokenType.gperf"
      {"wavy", lynx::tasm::TokenType::WAVY},
#line 40 "TokenType.gperf"
      {"cover", lynx::tasm::TokenType::COVER},
#line 66 "TokenType.gperf"
      {"dashed", lynx::tasm::TokenType::DASHED},
#line 59 "TokenType.gperf"
      {"at", lynx::tasm::TokenType::AT},
#line 85 "TokenType.gperf"
      {"super-ellipse", lynx::tasm::TokenType::SUPER_ELLIPSE},
#line 84 "TokenType.gperf"
      {"path", lynx::tasm::TokenType::PATH},
#line 63 "TokenType.gperf"
      {"thick", lynx::tasm::TokenType::THICK},
#line 24 "TokenType.gperf"
      {"bottom", lynx::tasm::TokenType::BOTTOM},
#line 74 "TokenType.gperf"
      {"line-through", lynx::tasm::TokenType::LINE_THROUGH},
#line 80 "TokenType.gperf"
      {"tobottom", lynx::tasm::TokenType::TOBOTTOM},
#line 79 "TokenType.gperf"
      {"bold", lynx::tasm::TokenType::BOLD},
#line 53 "TokenType.gperf"
      {"closest-side", lynx::tasm::TokenType::CLOSEST_SIDE},
#line 39 "TokenType.gperf"
      {"auto", lynx::tasm::TokenType::AUTO},
#line 64 "TokenType.gperf"
      {"hidden", lynx::tasm::TokenType::HIDDEN},
#line 60 "TokenType.gperf"
      {"data", lynx::tasm::TokenType::DATA},
#line 69 "TokenType.gperf"
      {"groove", lynx::tasm::TokenType::GROOVE},
#line 31 "TokenType.gperf"
      {"vh", lynx::tasm::TokenType::VH},
#line 18 "TokenType.gperf"
      {"url", lynx::tasm::TokenType::URL},
#line 21 "TokenType.gperf"
      {"left", lynx::tasm::TokenType::LEFT},
#line 76 "TokenType.gperf"
      {"format", lynx::tasm::TokenType::FORMAT},
#line 14 "TokenType.gperf"
      {"rgb", lynx::tasm::TokenType::RGB},
#line 88 "TokenType.gperf"
      {"fit-content", lynx::tasm::TokenType::FIT_CONTENT},
#line 87 "TokenType.gperf"
      {"env", lynx::tasm::TokenType::ENV},
#line 56 "TokenType.gperf"
      {"farthest-corner", lynx::tasm::TokenType::FARTHEST_CORNER},
#line 35 "TokenType.gperf"
      {"deg", lynx::tasm::TokenType::DEG},
#line 46 "TokenType.gperf"
      {"space", lynx::tasm::TokenType::SPACE},
#line 15 "TokenType.gperf"
      {"rgba", lynx::tasm::TokenType::RGBA},
#line 47 "TokenType.gperf"
      {"round", lynx::tasm::TokenType::ROUND},
#line 17 "TokenType.gperf"
      {"hsla", lynx::tasm::TokenType::HSLA},
#line 55 "TokenType.gperf"
      {"farthest-side", lynx::tasm::TokenType::FARTHEST_SIDE},
#line 36 "TokenType.gperf"
      {"grad", lynx::tasm::TokenType::GRAD},
#line 68 "TokenType.gperf"
      {"double", lynx::tasm::TokenType::DOUBLE},
#line 73 "TokenType.gperf"
      {"underline", lynx::tasm::TokenType::UNDERLINE}};

  static const signed char lookup[] = {
      -1, -1, -1, 0,  -1, -1, 1,  2,  -1, 3,  -1, 4,  5,  6,  7,  8,  9,  10,
      11, 12, 13, 14, -1, 15, -1, 16, 17, 18, 19, -1, 20, 21, -1, 22, -1, 23,
      24, 25, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, -1, 35, 36, 37, -1, 38,
      -1, 39, 40, 41, -1, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, -1, -1,
      53, -1, -1, -1, -1, -1, -1, 54, -1, 55, -1, -1, 56, -1, 57, 58, 59, 60,
      -1, 61, -1, 62, -1, -1, 63, -1, 64, -1, 65, -1, -1, 66, -1, 67, -1, -1,
      -1, 68, 69, -1, -1, -1, 70, -1, -1, -1, -1, -1, -1, -1, -1, 71, 72, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 73, -1, -1, 74};

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH) {
    unsigned int key = hash(str, len);

    if (key <= MAX_HASH_VALUE) {
      int index = lookup[key];

      if (index >= 0) {
        const char *s = token_list[index].name;

        if (*str == *s && !strcmp(str + 1, s + 1)) return &token_list[index];
      }
    }
  }
  return nullptr;
}
#line 89 "TokenType.gperf"

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_PARSER_CSS_TOKEN_TYPE_HASH_H_
