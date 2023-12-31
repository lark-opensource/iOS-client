// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_BUFFERED_FIBER_DECODER_H_
#define LYNX_KRYPTON_AURUM_BUFFERED_FIBER_DECODER_H_

#include "aurum/decoder.h"
#include "aurum/loader.h"
#include "coroutine_context.h"

namespace lynx {
namespace canvas {
namespace au {

template <int STACK_SIZE>
class BufferedFiberDecoder : public DecoderBase {
 public:
  inline BufferedFiberDecoder(LoaderBase &loader) : DecoderBase(loader) {
    coroutine_makecontext(&ctx_, FiberMain, this,
                          reinterpret_cast<void *>(
                              (intptr_t(stack_ + sizeof(stack_)) & ~15) - 8));
  }

  virtual void Process() = 0;

  void ReadMeta() override final { Next(); }

  void Decode(Sample &output, int current_ample, int samples) final override {
    if (current_ample < buffer_start_ || current_ample >= buffer_end_) {
      // buffer not available
      next_sample_ = current_ample;
      Next();
      if (current_ample < buffer_start_ || current_ample >= buffer_end_) {
        return;
      }
    }

    // Remaining buffers:
    int buffer_available = buffer_end_ - current_ample;
    output.data = (short *)buffer_ + ((current_ample - buffer_start_) << 1);
    output.length = AU_MIN(buffer_available, samples);
  }

 protected:
  inline void Next() { SwapContext(&saved_context_, &ctx_); }

  inline void Yield() { SwapContext(&ctx_, &saved_context_); }

  inline static void SwapContext(coroutine_ucontext *saved_ctx,
                                 coroutine_ucontext *ctx) {
    volatile int ran = 0;
    coroutine_getcontext(saved_ctx);
    if (!__sync_swap(&ran, 1)) {
      coroutine_setcontext(ctx);
    }
  }

 protected:
  const SampleFormat *buffer_ = nullptr;
  int buffer_start_ = 0;  // buffer start offset
  int buffer_end_ = 0;    // buffer end offset
  int next_sample_ = 0;   // next buffer_start for the decoder
  bool running_ = true;

 private:
  coroutine_ucontext ctx_;
  coroutine_ucontext saved_context_;
  uint8_t stack_[STACK_SIZE];

  static void FiberMain(void *p) {
    auto decoder = reinterpret_cast<BufferedFiberDecoder *>(p);
    decoder->Process();
    coroutine_setcontext(&decoder->saved_context_);
  }
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_BUFFERED_FIBER_DECODER_H_
