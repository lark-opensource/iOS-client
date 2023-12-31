// Copyright 2022 The Lynx Authors. All rights reserved.

#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include "aurum/encoder.h"
#include "canvas/base/log.h"

#ifdef OS_ANDROID
#include <endian.h>
#else
#include <stdint.h>
#include <sys/types.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

struct __attribute__((__packed__)) Head {
  uint32_t riff_chunk_head;  // "RIFF"
  uint32_t riff_size;        // size of fmt chunk and data chunk
  uint32_t format;           // "WAVE"
  // fmt chunk
  uint32_t fmt_chunk_head;  // "fmt "
  uint32_t fmt_chunk_size;  // = 16
  uint16_t audio_format;    // = 1
  uint16_t channels;        // 1 or 2
  uint32_t sample_rate;
  uint32_t byte_rate;    // sample_rate * block_align
  uint16_t block_align;  //  channels * bits_per_sample / 8
  uint16_t bits_per_sample;
  // data chunk
  uint32_t data_chunk_head;  // "data"
  uint32_t data_chunk_size;
};

static void WriteWavHeader(long samples, uint8_t *ptr) {
  constexpr int channels = 2;
  constexpr int sample_rate = 44100;
  uint32_t byte_rate =
      channels * sample_rate *
      2;  // dual channel, 44100 bit rate, 2 bytes per sample short

  Head &head = *reinterpret_cast<Head *>(ptr);
  head.riff_chunk_head = htonl('RIFF');
  head.riff_size = uint32_t(samples * channels * 2 + sizeof(Head) - 8);  //
  head.format = htonl('WAVE');

  head.fmt_chunk_head = htonl('fmt ');
  head.fmt_chunk_size = 16;
  head.audio_format = 1;
  head.channels = channels;
  head.sample_rate = sample_rate;
  head.byte_rate = byte_rate;
  head.block_align = channels * 16 / 8;
  head.bits_per_sample = 16;

  head.data_chunk_head = htonl('data');
  head.data_chunk_size = uint32_t(samples * channels * 2);
}

class WavEncoder : public EncoderBase {
 public:
  inline WavEncoder(int fd) : fd_(fd) {
    capacity_ = 4 * 1024 * 1024;  // 4M with 30s pcm data
    ftruncate(fd_, capacity_);
    addr_ = (uint8_t *)::mmap(nullptr, size_t(capacity_),
                              PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  }
  virtual ~WavEncoder();
  virtual void Write(Sample) override;

 private:
  int fd_, total_samples_ = 0;
  off_t capacity_;
  uint8_t *addr_;
};

void WavEncoder::Write(Sample sample) {
  int offset = sizeof(Head) + (total_samples_ << 2);
  int required = sample.length << 2;
  if (offset + required > capacity_) {
    if (addr_ != MAP_FAILED) {
      ::munmap(addr_, capacity_);
    }
    do {
      capacity_ <<= 1;
    } while (offset + required > capacity_);

    ftruncate(fd_, capacity_);
    addr_ = (uint8_t *)::mmap(nullptr, size_t(capacity_),
                              PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
  }
  if (addr_ == MAP_FAILED) {
    KRYPTON_LOGE("mmap failed");
    return;
  }
  memcpy(addr_ + offset, sample.data, required);
  total_samples_ += sample.length;
}

WavEncoder::~WavEncoder() {
  WriteWavHeader(total_samples_, addr_);
  ftruncate(fd_, sizeof(Head) + (total_samples_ << 2));
  if (addr_ != MAP_FAILED) {
    ::munmap(addr_, capacity_);
  }
  ::close(fd_);
}

EncoderBase *encoder::RiffWav(const char *path) {
  int fd = ::open(path, O_CREAT | O_RDWR | O_TRUNC, 0666);
  if (-1 == fd) {
    KRYPTON_LOGE("cannot open/create file at %s") << (path ?: "");
    return nullptr;
  }

  return new WavEncoder(fd);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
