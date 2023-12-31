// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_CSS_STRING_SCANNER_H_
#define LYNX_CSS_PARSER_CSS_STRING_SCANNER_H_

#include <map>
#include <stack>
#include <string>
#include <vector>

namespace lynx {
namespace tasm {

enum class TokenType {
  /* single-character tokens */
  LEFT_PAREN,   // (
  RIGHT_PAREN,  // )
  COMMA,        // ,
  COLON,        // :
  DOT,          // .
  MINUS,        // -
  PLUS,         // +
  SEMICOLON,    // ;
  SLASH,        // /
  SHARP,        // #
  PERCENTAGE,   // %
  EQUAL,        // =
  /* literals */
  IDENTIFIER,
  STRING,
  NUMBER,
  HEX,
  /* Keywords */
  RGB,              // rgb
  RGBA,             // rgba
  HSL,              // hsl
  HSLA,             // hsla
  URL,              // url
  NONE,             // none
  TO,               // to
  LEFT,             // left
  TOP,              // top
  RIGHT,            // right
  BOTTOM,           // bottom
  CENTER,           // center
  PX,               // px
  RPX,              // rpx
  REM,              // rem
  EM,               // em
  VW,               // vw
  VH,               // vh
  PPX,              // ppx
  SP,               // sp
  MAX_CONTENT,      // max-content
  DEG,              // deg
  GRAD,             // GRAD
  RAD,              // rad
  TURN,             // turn
  AUTO,             // auto
  COVER,            // cover
  CONTAIN,          // contain
  REPEAT_X,         // repeat-x
  REPEAT_Y,         // repeat-y
  REPEAT,           // repeat
  NO_REPEAT,        // no-repeat
  SPACE,            // space
  ROUND,            // round
  BORDER_BOX,       // border-box
  PADDING_BOX,      // padding-box
  CONTENT_BOX,      // content-box
  LINEAR_GRADIENT,  // linear-gradient
  RADIAL_GRADIENT,  // radial-gradient
  CLOSEST_SIDE,     // closest-side
  CLOSEST_CORNER,   // closest-corner
  FARTHEST_SIDE,    // farthest-side
  FARTHEST_CORNER,  // farthest-corner
  ELLIPSE,          // ellipse
  CIRCLE,           // circle
  POLYGON,          // polygon
  SUPER_ELLIPSE,    // super-ellipse
  PATH,             // path
  AT,               // at
  DATA,             // data
  /* border key words */
  THIN,    // thin
  MEDIUM,  // medimu
  THICK,   // thick
  HIDDEN,  // hidden
  DOTTED,  // dotted
  DASHED,  // dashed
  SOLID,   // solid
  DOUBLE,  // double
  GROOVE,  // groove
  RIDGE,   // ridge
  INSET,   // inset
  OUTSET,  // outset
  /* text-decoration */
  UNDERLINE,
  LINE_THROUGH,
  WAVY,
  /* font-face */
  FORMAT,
  LOCAL,
  NORMAL,
  BOLD,
  /* compatible history keywords */
  TOBOTTOM,  // tobottom
  TOLEFT,    // toleft
  TORIGHT,   // toright
  TOTOP,     // totop
  /* function */
  CALC,         // calc(1px + 12px)
  ENV,          // env(safe-area-inset-right)
  FIT_CONTENT,  // fit-content(20px)
  /* others */
  ERROR,
  TOKEN_EOF,
  WHITESPACE,
  UNKNOWN,
};

struct Token final {
  TokenType type = TokenType::TOKEN_EOF;
  const char* start = nullptr;

  uint32_t length = 0;

  Token() = default;
  Token(TokenType type, const char* start, uint32_t length)
      : type(type), start(start), length(length) {}

  Token& operator=(const Token&) = default;
  ~Token() = default;
};

class Scanner final {
 public:
  Scanner(const char* content, uint32_t content_length)
      : content_(content),
        content_length_(content_length),
        start_(0),
        current_(0) {}

  ~Scanner() = default;

  Token ScanToken();

  char Advance();
  bool IsAtEnd();
  Token MakeToken(TokenType type);
  Token ErrorToken();
  Token String(char boundary);

  Token Number(bool begin_with_dot = false);
  Token Hex();
  Token Identifier();
  Token Whitespace();
  TokenType IdentifierType();
  bool Match(char expected);
  char Peek();
  char PeekNext();
  char PeekNextNext();
  void SkipWhiteSpace();
  const char* content() { return content_; }

 private:
  static bool IsWhitespace(char c);
  static bool IsDigit(char c);
  static bool IsAlpha(char c);
  void FunctionExpression();

  const char* content_;
  uint32_t content_length_;
  uint32_t start_;
  uint32_t current_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_PARSER_CSS_STRING_SCANNER_H_
