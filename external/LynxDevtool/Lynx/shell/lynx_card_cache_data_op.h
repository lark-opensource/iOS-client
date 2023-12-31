// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_CARD_CACHE_DATA_OP_H_
#define LYNX_SHELL_LYNX_CARD_CACHE_DATA_OP_H_

#include "lepus/value.h"

namespace lynx {
namespace shell {
enum class CacheDataType {
  UPDATE = 0,
  RESET,
};

class CacheDataOp {
 public:
  explicit CacheDataOp(lepus::Value value,
                       CacheDataType type = CacheDataType::UPDATE)
      : value_(value), type_(type){};
  const lepus::Value& GetValue() const { return value_; }
  CacheDataType GetType() const { return type_; }

  friend bool operator==(const CacheDataOp& left, const CacheDataOp& right) {
    return left.value_ == right.value_ && left.type_ == right.type_;
  }

 private:
  lepus::Value value_;
  CacheDataType type_;
};
}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_CARD_CACHE_DATA_OP_H_
