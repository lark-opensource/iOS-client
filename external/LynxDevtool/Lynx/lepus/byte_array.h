// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_BYTE_ARRAY_H_
#define LYNX_LEPUS_BYTE_ARRAY_H_

#include <memory>
#include <utility>

#include "base/ref_counted.h"

namespace lynx {
namespace lepus {

class ByteArray : public base::RefCountedThreadSafeStorage {
 public:
  static base::scoped_refptr<ByteArray> Create() {
    return base::AdoptRef<ByteArray>(new ByteArray(nullptr, 0));
  }
  static base::scoped_refptr<ByteArray> Create(std::unique_ptr<uint8_t[]> ptr,
                                               size_t length) {
    return base::AdoptRef<ByteArray>(new ByteArray(std::move(ptr), length));
  }

  ByteArray(std::unique_ptr<uint8_t[]> ptr, size_t length);

  std::unique_ptr<uint8_t[]> MovePtr();

  size_t GetLength();

  virtual void ReleaseSelf() const override;
  ~ByteArray() override = default;

 private:
  ByteArray(const ByteArray&) = delete;
  ByteArray& operator=(const ByteArray&) = delete;

  std::unique_ptr<uint8_t[]> ptr_;
  size_t length_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BYTE_ARRAY_H_
