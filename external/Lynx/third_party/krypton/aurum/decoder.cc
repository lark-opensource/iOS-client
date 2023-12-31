#include "aurum/decoder.h"

#include <stdint.h>

#include "aurum/aurum.h"
#include "aurum/decoders.h"
#include "aurum/loader.h"

namespace lynx {
namespace canvas {
namespace au {

Decoder **DecoderListPtr() {
  static Decoder *decoders = nullptr;
  return &decoders;
}

void decoder::Use(class Decoder &decoder) {
  class Decoder **p = DecoderListPtr();
  while (*p) {
    if (*p == &decoder) {
      return;  // already inserted
    }
    p = &((*p)->next);
  }
  *p = &decoder;
  decoder.next = nullptr;
}

void DecoderBase::UnRef() {
  if (!__sync_sub_and_fetch(&refs_, 1)) {
    loader_.ReleaseDecoders(this);
  }
}

class UnsupportedDecoder : public DecoderBase {
 public:
  inline UnsupportedDecoder(LoaderBase &loader) : DecoderBase(loader) {
    state_ = DecoderState::Error;
  }

  virtual void ReadMeta() override {}
  virtual void Decode(Sample &output, int current_ample, int samples) override {
  }
};

DecoderBase *decoder::Decoder(LoaderBase &loader) {
  LoaderData data;
  auto total_content_length = loader.TotalContentLength();
  LoadResult result =
      loader.Read(0,
                  (total_content_length < 0 || total_content_length > 4096
                       ? 4096
                       : total_content_length),
                  data);
  if (result == LoadResult::Pending) {
    return nullptr;
  }

  if (result == LoadResult::EndOfFile || result == LoadResult::Error ||
      data.Data() == nullptr) {
    return new UnsupportedDecoder(loader);
  }

  size_t first_received_min_len = 256;
  total_content_length = loader.TotalContentLength();
  if (total_content_length >= 0 &&
      first_received_min_len > size_t(total_content_length)) {
    // waiting for more data
    first_received_min_len = total_content_length;
  }

  if (loader.ReceivedContentLength() < first_received_min_len) {
    return nullptr;
  }

  auto curr = *DecoderListPtr();
  for (; curr; curr = curr->next) {
    DecoderBase *ret = curr->Create(data.Data(), loader);
    if (ret) {
      return ret;
    }
  }

  return new UnsupportedDecoder(loader);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
