// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_STREAM_H_
#define LYNX_KRYPTON_AURUM_AUDIO_STREAM_H_

#include <stdint.h>
#include <string.h>

#include "aurum/config.h"
#include "aurum/converter.h"

namespace lynx {
namespace canvas {
namespace au {

class StreamBase {
 public:
  // Write non interleaved mono data
  inline void WriteMono(const short *samples, int len) {
    AU_LOCK(rw_lock_);
    int tail = AU_STREAM_BUF_LEN - (write_offset_ & (AU_STREAM_BUF_LEN - 1));
    if (tail < len) {
      ConvertMonoToStereo(
          buffer_ + ((write_offset_ & (AU_STREAM_BUF_LEN - 1)) << 1), samples,
          tail);
      ConvertMonoToStereo(buffer_, samples + tail, len - tail);
    } else {
      ConvertMonoToStereo(
          buffer_ + ((write_offset_ & (AU_STREAM_BUF_LEN - 1)) << 1), samples,
          len);
    }
    write_offset_ += len;
    if (write_offset_ - read_offset_ > 4096) {
      read_offset_ = write_offset_ - 4096;
    }
    AU_UNLOCK(rw_lock_);
  }

  inline void Write(const short *samples, int len) {
    AU_LOCK(rw_lock_);
    int tail = AU_STREAM_BUF_LEN - (write_offset_ & (AU_STREAM_BUF_LEN - 1));
    if (tail < len) {
      memcpy(buffer_ + ((write_offset_ & (AU_STREAM_BUF_LEN - 1)) << 1),
             samples, tail << 2);
      memcpy(buffer_, samples + (tail << 1), (len - tail) << 2);
    } else {
      memcpy(buffer_ + ((write_offset_ & (AU_STREAM_BUF_LEN - 1)) << 1),
             samples, len << 2);
    }
    write_offset_ += len;
    if (write_offset_ - read_offset_ > 4096) {
      read_offset_ = write_offset_ - 4096;
    }

    AU_UNLOCK(rw_lock_);
  }

  inline int Read(short *output, int len) {
    AU_LOCK(rw_lock_);

    int remains = AU_STREAM_BUF_LEN - (read_offset_ & (AU_STREAM_BUF_LEN - 1));
    len = AU_MIN(len, remains);
    remains = write_offset_ - read_offset_;
    len = AU_MIN(len, remains);

    memcpy(output, buffer_ + ((read_offset_ & (AU_STREAM_BUF_LEN - 1)) << 1),
           len << 2);

    read_offset_ += len;

    AU_UNLOCK(rw_lock_);
    return len;
  }

  virtual ~StreamBase() = default;

  virtual void Start() = 0;

  virtual void Stop() = 0;

  int GetSampleRate() const { return sample_rate_; }
  int GetChannels() const { return channels_; }

 protected:
  int sample_rate_ = 0;
  int channels_ = 0;

 private:
  int rw_lock_ = 0;
  short buffer_[AU_STREAM_BUF_LEN * 2];  // loop buffer
  int read_offset_ = 0;
  int write_offset_ = 0;
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_STREAM_H_
