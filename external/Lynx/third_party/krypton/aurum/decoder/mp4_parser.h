// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_MP4_PARSER_H_
#define LYNX_KRYPTON_AURUM_MP4_PARSER_H_

#include <vector>

#include "aurum/loader/loader_data.h"
#include "canvas/base/log.h"

#ifdef OS_ANDROID
#include <endian.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

static constexpr int ADTS_HEADER_SIZE = 7;

class MP4Parser {
 public:
  struct Chunk {
    uint32_t offset;
    uint32_t samples_end;
  };

  struct {
    uint32_t current_chunk;
    uint32_t current_sample;
    uint32_t chunk_offset;
    uint32_t samples_end;
  } iterator;

  inline void Reset() { memset(&iterator, 0, sizeof(iterator)); }

  inline MP4Parser() { Reset(); }

  // returns false when last frame has reached
  inline bool NextSample(ChunkInfo &result) {
    if (iterator.current_sample == iterator.samples_end) {  // visit next chunk
      if (iterator.current_chunk == chunks_.size()) {       // next first chunk
        KRYPTON_LOGV("no more chunks");
        result.SetLength(0);
        return true;
      }
      iterator.samples_end = chunks_[iterator.current_chunk].samples_end;
      iterator.chunk_offset = chunks_[iterator.current_chunk].offset;
      iterator.current_chunk++;
    }
    size_t size = sample_size_ == 0 ? sample_sizes_[iterator.current_sample++]
                                    : sample_size_;
    bool succ = Read(iterator.chunk_offset, size, result);
    iterator.chunk_offset += size;
    return succ;
  }

  virtual bool Read(size_t offset, size_t size, ChunkInfo &result) = 0;

  bool ParseHead();

  struct Box {
    struct Iter {
      inline Iter(const uint8_t *data, size_t size)
          : data_(data), size_(size), offset_(0) {}

      inline const Box *Next() {
        if (offset_ >= size_) {
          return nullptr;
        }

        const Box *ret = reinterpret_cast<const Box *>(data_ + offset_);
        offset_ += htonl(ret->size_);
        return ret;
      }

     private:
      const uint8_t *data_;
      size_t size_;
      size_t offset_;
    };

    template <uint32_t tag>
    inline bool Is() const {
      return tag_ == htonl(tag);
    }

    inline uint32_t Size() const { return htonl(size_) - 8; }

    Iter GetIter() const { return Iter(data_, Size()); }

    template <typename T>
    inline const T *As() const {
      return reinterpret_cast<const T *>(data_);
    }

    const uint8_t *Data() const { return data_; }

   private:
    uint32_t size_;
    uint32_t tag_;
    const uint8_t data_[0];
  };

 private:
  bool ParseStbl(const Box &box);
  bool ParseMoov(const void *data);

 protected:
  struct ADTSContext {
    uint32_t profile;
    uint32_t sample_rate_index;
    uint32_t channel_conf;

    inline void OnExtraData(const uint8_t *);
  } adts_context;

  inline void AACSetAdtsHead(unsigned char *buf, int size) {
    size += ADTS_HEADER_SIZE;

    buf[0] = 0xff;
    buf[1] = 0xf1;
    buf[2] = uint8_t((adts_context.profile - 1) << 6 |
                     adts_context.sample_rate_index << 2 |
                     adts_context.channel_conf >> 2);
    buf[3] = uint8_t((adts_context.channel_conf & 0x3) << 6 | size >> 11);
    buf[4] = uint8_t((size & 0x7ff) >> 3);
    buf[5] = uint8_t(((size & 7) << 5) | 0x1f);
    buf[6] = 0xfc;
  }

 protected:
  std::vector<Chunk> chunks_;
  uint32_t sample_size_ = 0;
  std::vector<uint32_t> sample_sizes_;

  uint32_t sample_rate_ = 0;
  uint32_t sample_bit_depth_;
  uint32_t channel_count_;
  uint32_t time_scale_ = 0;
  uint32_t duration_ = 0;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_MP4_PARSER_H_
