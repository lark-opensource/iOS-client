// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_LOADER_DATA_H_
#define LYNX_KRYPTON_AURUM_LOADER_DATA_H_

#include <stdint.h>
#include <unistd.h>

#include <memory>

namespace lynx {
namespace canvas {
namespace au {

class LoaderData {
 public:
  size_t DataLength() const { return data_length_; }

  void* Data() const { return const_cast<void*>(data_ext_ ?: buffer_.get()); }

  size_t BufferLength() const { return buffer_length_; }

  void Reset() {
    data_ext_ = nullptr;
    buffer_ = nullptr;
    data_length_ = buffer_length_ = 0;
  }

  bool AllocBuffer(size_t buffer_length) {
    bool buffer_ready = (buffer_ && buffer_length_ >= buffer_length);
    if (buffer_ready) {
      return true;
    }

    uint8_t* new_buffer = new uint8_t[buffer_length];
    if (new_buffer == nullptr) {
      return false;
    }

    if (data_length_ > 0 && data_ext_ == nullptr && buffer_.get() != nullptr) {
      memcpy(new_buffer, buffer_.get(), data_length_);
    }

    buffer_length_ = buffer_length;
    buffer_ =
        std::shared_ptr<uint8_t>(new_buffer, std::default_delete<uint8_t[]>());

    return true;
  }

  bool FillBuffer(size_t offset, const void* data, size_t data_length) {
    AutoClearDataExt();

    if (buffer_ == nullptr || data == nullptr ||
        offset + data_length > buffer_length_) {
      return false;
    }

    memcpy(buffer_.get() + offset, data, data_length);
    if (data_length_ < offset + data_length) {
      data_length_ = offset + data_length;
    }
    return true;
  }

  bool SetData(const void* data, int length, bool copy) {
    if (length == 0) {
      data_length_ = 0;
      data_ext_ = nullptr;
      buffer_ = nullptr;
      return true;
    }

    if (length < 0 || data == nullptr) {
      return false;
    }

    if (!copy) {
      data_ext_ = data;
      data_length_ = length;
      return true;
    }

    if (!AllocBuffer(length)) {
      return false;
    }

    data_length_ = 0;

    return FillBuffer(0, data, length);
  }

 private:
  void AutoClearDataExt() {
    if (data_ext_) {
      data_ext_ = nullptr;
      data_length_ = 0;
    }
  }

 private:
  const void* data_ext_{nullptr};
  std::shared_ptr<uint8_t> buffer_{nullptr};
  size_t data_length_{0}, buffer_length_{0};
};

class ChunkInfo {
 public:
  size_t Length() const { return length_; }

  uint8_t* Data() const {
    if (data_.DataLength() < offset_) {
      return nullptr;
    }
    return reinterpret_cast<uint8_t*>(data_.Data()) + offset_;
  }

  void Reset() {
    length_ = offset_ = 0;
    data_.Reset();
  }

  void Reset(const LoaderData& data, size_t offset, size_t length) {
    data_ = data;
    offset_ = offset;
    SetLength(length);
  }

  void SetLength(size_t length) {
    length_ = length;
    if (offset_ + length > data_.DataLength()) {
      length_ = 0;
    }
  }

 private:
  size_t length_{0}, offset_{0};
  LoaderData data_;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_LOADER_DATA_H_
