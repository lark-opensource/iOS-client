// Copyright 2021 The Lynx Authors. All rights reserved.
#include "lepus/byte_array.h"

namespace lynx {
namespace lepus {

ByteArray::ByteArray(std::unique_ptr<uint8_t[]> ptr, size_t length)
    : ptr_(std::move(ptr)), length_(length) {}

std::unique_ptr<uint8_t[]> ByteArray::MovePtr() {
  length_ = 0;
  return std::move(ptr_);
}

size_t ByteArray::GetLength() { return length_; }

void ByteArray::ReleaseSelf() const { delete this; }

}  // namespace lepus
}  // namespace lynx
