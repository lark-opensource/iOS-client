// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css_tokenizer.h"

namespace lynx {
namespace canvas {
namespace {
bool IsQuote(char c) { return c == '"' || c == '\''; }

bool IsSpace(char c) { return c == ' '; }

bool IsComma(char c) { return c == ','; }

bool IsIdent(char c) { return !IsQuote(c) && !IsSpace(c) && !IsComma(c); }
}  // namespace
CSSTokenizer::CSSTokenizer(std::string source)
    : source_(std::move(source)), cur_idx_(0) {
  UpdateCurTokenType();
}

bool CSSTokenizer::AtEnd() const { return cur_idx_ == source_.size(); }

CaseInsensitiveStringView CSSTokenizer::Peek() const {
  if (cur_token_type_ != kIdentTokenType) {
    return CaseInsensitiveStringView(source_.data() + cur_idx_, 1);
  }

  auto find_next_non_ident_idx = FindNextNonIdent();
  return CaseInsensitiveStringView(source_.data() + cur_idx_,
                                   find_next_non_ident_idx - cur_idx_);
}

size_t CSSTokenizer::FindNextNonIdent() const {
  for (size_t i = cur_idx_; i < source_.size(); ++i) {
    if (!IsIdent(source_[i])) {
      return i;
    }
  }
  return source_.size();
}

size_t CSSTokenizer::FindNextSpace() const {
  for (size_t i = cur_idx_; i < source_.size(); ++i) {
    if (IsSpace(source_[i])) {
      return i;
    }
  }
  return source_.size();
}

size_t CSSTokenizer::FindNextNonSpace() const {
  for (size_t i = cur_idx_; i < source_.size(); ++i) {
    if (!IsSpace(source_[i])) {
      return i;
    }
  }
  return source_.size();
}

void CSSTokenizer::UpdateCurTokenType() {
  if (AtEnd()) {
    cur_token_type_ = kEndTokenType;
    return;
  }

  if (IsSpace(source_[cur_idx_])) {
    cur_token_type_ = kSpaceTokenType;
    return;
  }

  if (IsQuote(source_[cur_idx_])) {
    cur_token_type_ = kQuoteTokenType;
    return;
  }

  if (IsComma(source_[cur_idx_])) {
    cur_token_type_ = kCommaTokenType;
    return;
  }

  cur_token_type_ = kIdentTokenType;
}

size_t CSSTokenizer::ConsumeSpace() {
  auto next_non_space_idx = FindNextNonSpace();
  size_t count = next_non_space_idx - cur_idx_;
  cur_idx_ = next_non_space_idx;
  UpdateCurTokenType();
  return count;
}

size_t CSSTokenizer::ConsumeIdent() {
  if (cur_token_type_ != kIdentTokenType) {
    return 0;
  }
  auto next_no_ident_idx = FindNextNonIdent();
  size_t count = next_no_ident_idx - cur_idx_;
  cur_idx_ = next_no_ident_idx;
  UpdateCurTokenType();
  return count;
}

bool CSSTokenizer::ConsumeQuote() {
  if (cur_token_type_ != kQuoteTokenType) {
    return false;
  }

  cur_idx_++;
  UpdateCurTokenType();
  return true;
}

void CSSTokenizer::ConsumeIdentWithSpace() {
  ConsumeIdent();
  ConsumeSpace();
}

bool CSSTokenizer::ConsumeCommaWithSpace() {
  if (cur_token_type_ != kCommaTokenType) {
    return false;
  }

  cur_idx_++;
  ConsumeSpace();

  return true;
}

}  // namespace canvas
}  // namespace lynx
