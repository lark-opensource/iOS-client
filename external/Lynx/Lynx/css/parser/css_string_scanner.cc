// Copyright 2020 The Lynx Authors. All rights reserved.

#include "css/parser/css_string_scanner.h"

#include <cstring>

#include "css/parser/css_token_type_hash.h"

namespace lynx {
namespace tasm {

Token Scanner::ScanToken() {
  start_ = current_;

  if (IsAtEnd()) {
    return MakeToken(TokenType::TOKEN_EOF);
  }

  char c = Advance();

  if (IsWhitespace(c)) {
    return Whitespace();
  }

  if (IsAlpha(c)) {
    return Identifier();
  }
  // [<Number>] <dot> <Number>
  if (IsDigit(c) || (c == '.' && IsDigit(Peek()))) {
    return Number(c == '.');
  }

  // negative number
  if (c == '-') {
    if (IsDigit(Peek()) || (Peek() == '.' && IsDigit(PeekNext()))) {
      return Number();
    }
  }

  // hex number
  if (c == '#') {
    return Hex();
  }

  switch (c) {
    case '(':
      return MakeToken(TokenType::LEFT_PAREN);
    case ')':
      return MakeToken(TokenType::RIGHT_PAREN);
    case ',':
      return MakeToken(TokenType::COMMA);
    case ':':
      return MakeToken(TokenType::COLON);
    case '.':
      return MakeToken(TokenType::DOT);
    case '-':
      return MakeToken(TokenType::MINUS);
    case '+':
      return MakeToken(TokenType::PLUS);
    case ';':
      return MakeToken(TokenType::SEMICOLON);
    case '/':
      return MakeToken(TokenType::SLASH);
      // fixme(renzhongyue): all '#' are parsed to hex number now. This path is
      // unreachable.
    case '#':
      return MakeToken(TokenType::SHARP);
    case '%':
      return MakeToken(TokenType::PERCENTAGE);
    case '\'':
      return String('\'');
    case '\"':
      return String('\"');
    default:
      return MakeToken(TokenType::UNKNOWN);
  }
}

char Scanner::Advance() {
  current_++;
  return content_[current_ - 1];
}

bool Scanner::Match(char expected) {
  if (IsAtEnd()) {
    return false;
  }

  if (content_[current_] != expected) {
    return false;
  }

  current_++;
  return true;
}

bool Scanner::IsWhitespace(char c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r' || c == '\f';
}

bool Scanner::IsDigit(char c) { return c >= '0' && c <= '9'; }

bool Scanner::IsAlpha(char c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

Token Scanner::String(char boundary) {
  // skip first `'`
  Advance();
  while (Peek() != boundary && !IsAtEnd()) {
    Advance();
  }

  if (IsAtEnd()) {
    // Unterminated string without `'` at end , like 'xxxxx
    return ErrorToken();
  }
  // skip last `'`
  Advance();

  return MakeToken(TokenType::STRING);
}

void Scanner::FunctionExpression() {
  char left_paren = '(';
  char right_paren = ')';

  std::stack<char> brackets;
  SkipWhiteSpace();
  if (Peek() != left_paren || IsAtEnd()) {
    return;
  }
  brackets.push(left_paren);
  while (!IsAtEnd() && !brackets.empty()) {
    Advance();
    if (Peek() == left_paren) {
      brackets.push(left_paren);
    }
    if (Peek() == right_paren) {
      brackets.pop();
    }
  }
  if (IsAtEnd()) {
    return;
  }
  Advance();
}

Token Scanner::Number(bool begin_with_dot) {
  // in case is negative number
  if (Peek() == '-' && (IsDigit(PeekNext() || PeekNext() == '.'))) {
    Advance();
  }
  while (IsDigit(Peek())) {
    Advance();
  }
  if (begin_with_dot && Peek() == '.') {
    return MakeToken(TokenType::NUMBER);
  }
  // support float number
  if (Peek() == '.' && IsDigit(PeekNext())) {
    // consume the dot
    Advance();
  }

  while (IsDigit(Peek())) {
    Advance();
  }

  // <number> ,e , -, <number> like '3e-5'
  if (Peek() == 'e' && PeekNext() == '-' && IsDigit(PeekNextNext())) {
    Advance();  // e
    Advance();  // -
  }
  while (IsDigit(Peek())) {
    Advance();
  }

  return MakeToken(TokenType::NUMBER);
}

Token Scanner::Hex() {
  // skip #
  start_ = current_;
  while (IsAlpha(Peek()) || IsDigit(Peek())) {
    Advance();
  }

  return MakeToken(TokenType::HEX);
}

Token Scanner::Whitespace() {
  while (IsWhitespace(Peek())) {
    Advance();
  }

  return MakeToken(TokenType::WHITESPACE);
}

Token Scanner::Identifier() {
  while (IsAlpha(Peek()) || IsDigit(Peek())) {
    bool is_alpha = IsAlpha(Peek());
    Advance();
    if (is_alpha && Peek() == '-') {
      Advance();
    }
  }

  return MakeToken(IdentifierType());
}

bool Scanner::IsAtEnd() {
  return content_[current_] == '\0' || current_ > content_length_;
}

Token Scanner::MakeToken(TokenType type) {
  return Token{type, content_ + start_ + (type == TokenType::STRING ? 1 : 0),
               current_ - start_ - (type == TokenType::STRING ? 2 : 0)};
}

Token Scanner::ErrorToken() { return Token(TokenType::ERROR, nullptr, 0); }

char Scanner::Peek() {
  if (current_ > content_length_) {
    return '\0';
  }
  return content_[current_];
}

char Scanner::PeekNext() {
  if (IsAtEnd()) {
    return '\0';
  }

  return content_[current_ + 1];
}

char Scanner::PeekNextNext() {
  if (PeekNext() == '\0' || current_ + 2 > content_length_) {
    return '\0';
  }

  return content_[current_ + 2];
}

TokenType Scanner::IdentifierType() {
  if (start_ > content_length_ || current_ > content_length_) {
    return TokenType::TOKEN_EOF;
  }
  size_t len = current_ - start_;
  char s[len + 1];
  strncpy(s, content_ + start_, len);
  s[len] = 0;
  auto* it = ScannerTokenHash::GetTokenType(s, len);
  if (it != nullptr) {
    if (it->type == TokenType::CALC || it->type == TokenType::ENV ||
        it->type == TokenType::FIT_CONTENT) {
      FunctionExpression();
    }
    return it->type;
  }

  return TokenType::IDENTIFIER;
}

void Scanner::SkipWhiteSpace() {
  for (;;) {
    char c = Peek();
    if (IsWhitespace(c)) {
      Advance();
    } else {
      return;
    }
  }
}

}  // namespace tasm
}  // namespace lynx
