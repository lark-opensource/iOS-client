#ifndef _BLOB_
#define _BLOB_

#include <stdlib.h>
#include "internal_smash.h"
#include "tt_log.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)

// Blob
class Blob {
 public:
  explicit Blob(
      int num, int channel, int height, int width, int elem_size_in_bytes)
      : num_(num),
        channel_(channel),
        height_(height),
        width_(width),
        elem_size_in_bytes_(elem_size_in_bytes) {
    size_ = num * channel * width * height;
    data_ = malloc(size_ * elem_size_in_bytes_);
  }
  ~Blob() {
    if (data_) {
      free(data_);
      size_ = 0;
    }
  }

  void* Data() { return data_; }

  int Num() { return num_; }

  int Channel() { return channel_; }

  int Height() { return height_; }

  int Width() { return width_; }

  int Size() { return size_; }

  void Debug() {
    LOGD("n:%d, c:%d, h:%d, w:%d, elem_size=%d", num_, channel_, height_,
         width_, elem_size_in_bytes_);
  }

 private:
  void* data_;
  int size_;
  int num_;
  int channel_;
  int height_;
  int width_;
  int elem_size_in_bytes_;
};

NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif
