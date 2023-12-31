// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_CSS_TOKENIZER_H_
#define CANVAS_UTIL_CSS_TOKENIZER_H_

#include <cstring>
#include <string>

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

class CaseInsensitiveStringView {
 public:
  CaseInsensitiveStringView(const char *start, size_t count)
      : start_(start), count_(count) {
    DCHECK(count);
  }

  bool operator==(const char *rhs) {
    for (auto i = 0; i < count_; i++) {
      if (*(start_ + i) != std::tolower(*(rhs + i))) {
        return false;
      }
    }
    return true;
  }

  bool operator!=(const char *rhs) { return !(*this == rhs); }

  bool EndsWith(const char *rhs) {
    size_t len = std::strlen(rhs);
    if (len > count_) {
      return false;
    }
    auto *left = start_ + count_;
    auto *right = rhs + len;

    for (auto i = 0; i < len; i++) {
      left--;
      right--;

      if (*left != std::tolower(*right)) {
        return false;
      }
    }

    return true;
  }

  std::string ToString() const { return std::string(start_, count_); }

 private:
  const char *start_;
  const size_t count_;
};

enum TokenType {
  kIdentTokenType,
  kSpaceTokenType,
  kQuoteTokenType,
  kCommaTokenType,
  kEndTokenType,
};

class CSSTokenizer {
 public:
  CSSTokenizer(std::string source);

  CaseInsensitiveStringView Peek() const;

  TokenType PeekType() const { return cur_token_type_; }

  size_t ConsumeSpace();
  size_t ConsumeIdent();
  bool ConsumeQuote();
  void ConsumeIdentWithSpace();
  bool ConsumeCommaWithSpace();

  bool AtEnd() const;

 private:
  size_t FindNextNonIdent() const;
  size_t FindNextSpace() const;
  size_t FindNextNonSpace() const;
  void UpdateCurTokenType();

  const std::string source_;
  size_t cur_idx_;
  TokenType cur_token_type_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_CSS_TOKENIZER_H_
