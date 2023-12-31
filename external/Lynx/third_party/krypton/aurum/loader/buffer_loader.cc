// Copyright 2022 The Lynx Authors. All rights reserved.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <new>

#include "aurum/loader.h"

namespace lynx {
namespace canvas {
namespace au {

class BufferLoader : public LoaderBase {
 public:
  BufferLoader(const void *ptr, int length, bool copy) {
    data_.SetData(ptr, length, copy);
    total_content_length_ = length;
  }

  LoadResult Read(size_t start, size_t end, LoaderData &data) override {
    data = data_;

    if (total_content_length_ >= 0 && end > size_t(total_content_length_)) {
      return LoadResult::EndOfFile;
    }

    return LoadResult::OK;
  }
};

void loader::Buffer(LoaderBase *base, const void *ptr, int length, bool copy) {
  new (base) BufferLoader(ptr, length, copy);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
