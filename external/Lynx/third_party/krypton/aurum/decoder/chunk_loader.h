// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_CHUNK_LOADER_H_
#define LYNX_KRYPTON_AURUM_CHUNK_LOADER_H_

#include "aurum/decoder/buffered_fiber_decoder.h"

namespace lynx {
namespace canvas {
namespace au {

class ChunkLoader {
 public:
  virtual void Rewind() = 0;

  virtual bool GuessType(int &, int &, int &) { return true; }

  virtual bool NextChunk(ChunkInfo &, size_t = 0) = 0;

  virtual ~ChunkLoader() = default;

  template <typename LoaderRef>
  static ChunkLoader *M4A(LoaderRef &ref);
};

template <int STACK_SIZE>
class FiberLoader : public BufferedFiberDecoder<STACK_SIZE> {
 public:
  inline FiberLoader(LoaderBase &loader)
      : BufferedFiberDecoder<STACK_SIZE>(loader) {}

  inline int32_t FillData(size_t byte_offset, size_t len, ChunkInfo &result) {
    if (this->loader_.TotalContentLength() != -1) {
      size_t maxlen = this->loader_.TotalContentLength() - byte_offset;
      if (maxlen <= 0) {
        this->state_ = DecoderState::EndOfFile;
        result.SetLength(0);
        return 0;
      }
      if (len > maxlen) {
        len = maxlen;
      }
    }

    LoaderData loader_data;
    while (true) {
      LoadResult ret =
          this->loader_.Read(byte_offset, byte_offset + len, loader_data);
      if (ret == LoadResult::Pending) {
        this->Yield();
        continue;
      }
      if (ret == LoadResult::EndOfFile) {
        result.SetLength(0);
        return 0;
      }
      if (ret == LoadResult::Error) {
        result.SetLength(0);
        return -1;
      }

      result.Reset(loader_data, byte_offset, len);
      return static_cast<int32_t>(len);
    }
  }

  inline ChunkLoader *M4A() {
    return ChunkLoader::M4A(*reinterpret_cast<FiberLoader<0> *>(this));
  }
};

template <int STACK_SIZE>
class RawChunkLoader : public ChunkLoader {
 public:
  using LoaderRef = FiberLoader<STACK_SIZE> &;

  inline RawChunkLoader(LoaderRef ref) : ref_(ref) {}

  void Rewind() override { byte_offset_ = 0; }

  bool NextChunk(ChunkInfo &info, size_t expect_len) override {
    int32_t len = ref_.FillData(byte_offset_, expect_len, info);
    if (len == 0) {
      return true;  // EOF
    }

    if (len < 0) {
      return false;  // Error
    }

    byte_offset_ += len;
    return true;
  }

 private:
  LoaderRef ref_;
  size_t byte_offset_ = 0;
};

template <int STACK_SIZE>
class ADTSLoader : public ChunkLoader {
 public:
  using LoaderRef = FiberLoader<STACK_SIZE> &;

  inline ADTSLoader(LoaderRef ref, int32_t adts_head) : ref_(ref) {
    srate_ = (adts_head >> 18) & 15;
    channels_ = (adts_head >> 30) & 3;
  }

  void Rewind() override { byte_offset_ = 0; }

  bool GuessType(int &channels_out, int &sample_rate_out,
                 int &samples_out) override {
    channels_out = channels_;
    sample_rate_out = srate_;
    samples_out = -1;
    return true;
  }

  bool NextChunk(ChunkInfo &info, size_t expect_len) override {
    int32_t len = ref_.FillData(byte_offset_, expect_len, info);
    if (len == 0) {
      return true;  // EOF
    }
    if (len < 0) {
      return false;  // Error
    }

    const uint8_t *data = info.Data();
    uint32_t block_len =
        ((data[3] & 0x3) << 11) + (data[4] << 3) + ((data[5] & 0xe0) >> 5);
    if (len < int(block_len)) {
      return false;  // block corrupt
    }

    byte_offset_ += block_len;
    info.SetLength(block_len);
    return true;
  }

 private:
  LoaderRef ref_;
  size_t byte_offset_ = 0;
  int32_t srate_, channels_;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_CHUNK_LOADER_H_
