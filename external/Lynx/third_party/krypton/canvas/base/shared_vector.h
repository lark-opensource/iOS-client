// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BASE_SHARED_VECTOR_H_
#define CANVAS_BASE_SHARED_VECTOR_H_

#include <vector>

namespace lynx {
namespace canvas {
template <typename T>
class SharedVector {
 public:
  SharedVector(const std::vector<T>& source)
      : data_(source.data()), size_(source.size()) {}

  SharedVector(const T* data, size_t size) : data_(data), size_(size) {}

  const T* Data() const { return data_; }

  const T& operator[](std::size_t idx) const { return data_[idx]; }

  size_t Size() const { return size_; }

 private:
  const T* data_;
  const size_t size_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BASE_SHARED_VECTOR_H_
