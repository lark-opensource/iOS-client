// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_MEDIA_DECODE_BUFFER_H_
#define LYNX_KRYPTON_AURUM_MEDIA_DECODE_BUFFER_H_

#include <memory.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <functional>
#include <vector>

namespace lynx {
namespace canvas {
namespace au {

class DecodeBuffer {
 public:
  DecodeBuffer() { Reset(); }

  size_t Size() { return back_ - front_; }

  bool IsEmpty() { return Size() == 0; }

  void Reset() { front_ = back_ = 0; }

  size_t Fill(uint8_t *data, size_t byte) {
    if (buffer_.size() < byte) {
      buffer_.resize(byte);
    }

    memcpy(buffer_.data(), data, byte);
    front_ = 0;
    back_ = byte;
    return 0;
  }

  size_t Fetch(uint8_t *data, size_t byte) {
    size_t tmp_size = std::min(this->Size(), byte);
    memcpy(data, &buffer_[front_], tmp_size);
    front_ += tmp_size;
    return tmp_size;
  }

 private:
  size_t front_, back_;
  std::vector<uint8_t> buffer_;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_MEDIA_DECODE_BUFFER_H_
