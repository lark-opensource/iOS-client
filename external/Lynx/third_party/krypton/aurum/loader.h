// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_LOADER_H_
#define LYNX_KRYPTON_AURUM_LOADER_H_

#include "aurum/decoder.h"
#include "aurum/loader/loader_data.h"

namespace lynx {
namespace canvas {
namespace au {

enum class LoadResult : int32_t {
  OK = 0,
  Pending = 1,     // not buffered
  EndOfFile = -1,  // out of file range
  Error = -2,      // loader status error
};
class DecoderBase;

class LoaderBase {
 public:
  virtual LoadResult Read(size_t start, size_t end, LoaderData &data) {
    return LoadResult::Error;
  }

  virtual ~LoaderBase() { ReleaseDecoders(); }

  inline DecoderBase *Decoder();

  inline void ReleaseDecoders(DecoderBase *decoder);

  size_t ReceivedContentLength() const { return data_.DataLength(); };

  ssize_t TotalContentLength() const { return total_content_length_; };

 protected:
  ssize_t total_content_length_{-1};
  LoaderData data_;

 private:
  DecoderBase *free_decoders_[4];
  int free_decoders_len_{0};
  int free_decoders_lock_{0};

  inline void ReleaseDecoders();
};

namespace loader {

void Buffer(LoaderBase *, const void *, int length, bool copy);
void Platform(LoaderBase *, const char *, void **delegate);

}  // namespace loader
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#include "aurum/decoder.h"

namespace lynx {
namespace canvas {
namespace au {

DecoderBase *LoaderBase::Decoder() {
  AU_LOCK(free_decoders_lock_);
  DecoderBase *ret;
  if (free_decoders_len_) {
    ret = free_decoders_[--free_decoders_len_];
  } else {
    ret = decoder::Decoder(*this);
  }
  AU_UNLOCK(free_decoders_lock_);
  return ret;
}

void LoaderBase::ReleaseDecoders(DecoderBase *decoder) {
  AU_LOCK(free_decoders_lock_);
  if (free_decoders_len_ <
      int(sizeof(free_decoders_) / sizeof(free_decoders_[0]))) {
    if (decoder->GetState() == DecoderState::EndOfFile) {
      decoder->SetState(DecoderState::Meta);
    }
    free_decoders_[free_decoders_len_++] = decoder;
    decoder = nullptr;  // don't delete
  }
  AU_UNLOCK(free_decoders_lock_);
  delete decoder;
}

void LoaderBase::ReleaseDecoders() {
  AU_LOCK(free_decoders_lock_);
  while (free_decoders_len_--) {
    delete free_decoders_[free_decoders_len_];
  }
  AU_UNLOCK(free_decoders_lock_);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_LOADER_H_
