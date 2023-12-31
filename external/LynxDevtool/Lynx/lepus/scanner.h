// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_SCANNER_H_
#define LYNX_LEPUS_SCANNER_H_

#include <string>

#include "lepus/lepus_string.h"
#include "lepus/token.h"
#include "parser/input_stream.h"
#include "tasm/config.h"

namespace lynx {
namespace lepus {
class Scanner {
 public:
  explicit Scanner(parser::InputStream* input);
  void NextToken(Token& token, const Token& current_token);
  void SetSdkVersion(std::string& sdk_version);

  int line() { return line_; }
  int column() { return column_; }
  std::string GetPartStr(Token& token) {
    return input_stream_->GetPartStr(token.line_, token.column_);
  }
  std::string GetPartStr(int32_t& line, int32_t& column) {
    return input_stream_->GetPartStr(line, column);
  }

 private:
  void ParseNewLine();
  void ParseSingleLineComment();
  void ParseMultiLineComment();
  void ParseNumber(Token& token);
  void ParseEqual(Token& token, int equal);
  void ParseTokenCharacter(Token& token, int token_character);
  void ParseString(Token& token);
  bool ParseRegExp(Token& token);
  void ParseId(Token& token);

  int EscapeConvert(char c);
  bool IsRegExpFlags(int current_character);

  int NextCharacter() {
    int character = input_stream_->Next();
    if (character != 0) {
      ++column_;
    } else {
      character = EOF;
    }
    return character;
  }

  void CharacterBack(int k) {
    if (k <= column_) {
      input_stream_->Back(k);
      column_ -= k;
    }
  }

  parser::InputStream* input_stream_;
  int current_character_ = EOF;
  Token current_token_;
  int line_ = 1;
  int column_ = 0;
  std::string sdk_version_;
};
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_SCANNER_H_
