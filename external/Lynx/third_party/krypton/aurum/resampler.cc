// Copyright 2022 The Lynx Authors. All rights reserved.

#include <stdio.h>
#include <string.h>

#include "aurum/audio_context.h"
#include "aurum/config.h"
#include "aurum/sample.h"
#include "canvas/base/log.h"
#include "signal_processing_library_aurum.h"

namespace lynx {
namespace canvas {
namespace au {

template <typename T, int capacity>
class FixedSampleBuffer {
 public:
  inline T *Resize(int length) {
    start_ = 0;
    len_ = length;
    return data_;
  }

  inline void Fill(T *output, int length) {
    memcpy(output, data_ + start_, length * sizeof(T));
    start_ += length;
  }

  inline int Length() { return len_ - start_; }

  inline void Clear() { start_ = len_ = 0; }

 private:
  int start_ = 0, len_ = 0;
  T data_[capacity];
};

struct ChannelResampler {
  enum class Mode : uint32_t {
    kNone,
    k1To1,    // 44.1k
    k1To2,    // 22.05k
    k1To4,    // 11.025k
    k2To11,   // 8k
    k4To11,   // 16k
    k6To11,   // 24k
    k8To11,   // 32k
    k12To11,  // 48k
  };

  inline ChannelResampler() {}

  Mode mode = Mode::kNone;

  bool Init(uint32_t from, uint32_t to) {
    // division algorithm
    uint32_t a = from, b = to, c = a % b;
    while (c) {
      a = b;
      b = c;
      c = a % b;
    }
    from = from / b;
    to = to / b;
    Mode mode;

#define MODE(a, b) a << 16 | b
    switch (MODE(from, to)) {
      case MODE(1, 1):
        mode = Mode::k1To1;
        break;
      case MODE(1, 2):
        mode = Mode::k1To2;
        break;
      case MODE(1, 4):
        mode = Mode::k1To4;
        break;
      case MODE(2, 11):
      case MODE(80, 441):  // 8000 -> 44100
        mode = Mode::k2To11;
        break;
      case MODE(4, 11):
      case MODE(160, 441):  // 16000 -> 44100
        mode = Mode::k4To11;
        break;
      case MODE(6, 11):
      case MODE(80, 147):  // 24000 -> 44100
        mode = Mode::k6To11;
        break;
      case MODE(8, 11):
      case MODE(320, 441):  // 32000 -> 44100
        mode = Mode::k8To11;
        break;
      case MODE(12, 11):
      case MODE(160, 147):  // 48000 -> 44100
        mode = Mode::k12To11;
        break;
      default:
        this->mode = Mode::kNone;
        return false;
    }
#undef MODE

    if (mode == this->mode) {
      return true;
    }

    switch (this->mode = mode) {
      case Mode::kNone:
        // should not goes here
        break;
      case Mode::k1To1:
        break;
      case Mode::k1To2:
        new (&resampler1to2) Resampler1To2();
        break;
      case Mode::k1To4:
        new (&resampler1to4) Resampler1To4();
        break;
      case Mode::k2To11:
        new (&resampler2to11) Resampler2To11();
        break;
      case Mode::k4To11:
        new (&resampler4to11) Resampler4To11();
        break;
      case Mode::k6To11:
        new (&resampler6to11) Resampler6To11();
        break;
      case Mode::k8To11:
        new (&resampler8to11) Resampler8To11();
        break;
      case Mode::k12To11:
        new (&resampler12to11) Resampler12To11();
        break;
      default:
        break;
    }

    return true;
  }

  inline int Required(int len) {
    Base *inst = &base;
    return inst->Required(len);
  }

  inline int Resample(const int16_t *in, int len, int16_t *out) {
    Base *inst = &base;
    return inst->Resample(in, len, out);
  }

 private:
  inline void Setup(Mode mode);

  struct Base {
    inline Base() {}

    virtual int Resample(const int16_t *in, int len, int16_t *out) {
      return 0;
    };

    virtual int Required(int n) { return n; }
  };

  struct Resampler1To2 : Base {
    int32_t state0[8];

    inline Resampler1To2() { memset(state0, 0, sizeof(state0)); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      WebRtcSpl_UpsampleBy2(in, len, out, state0);
      return len << 1;
    }

    virtual int Required(int n) override { return (n + 1) >> 1; }
  };

  struct Resampler1To4 : Resampler1To2 {
    int32_t state1[8];

    inline Resampler1To4() { memset(state1, 0, sizeof(state1)); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      constexpr int seg_len = 128;
      int16_t tmp[seg_len << 2];
      for (int i = 0; i < len; i += seg_len) {
        int curLen = (len > i + seg_len) ? seg_len : (len - i);
        WebRtcSpl_UpsampleBy2(in, curLen, tmp, state0);
        WebRtcSpl_UpsampleBy2(tmp, (curLen << 1), out, state1);
        in += curLen << 1;
        out += curLen << 3;
      }
      return len << 2;
    }

    virtual int Required(int n) override { return (n + 3) >> 2; }
  };

  struct Resampler4To11 : Base {
    WebRtcSpl_State8khzTo22khz state1;

    inline Resampler4To11() { WebRtcSpl_ResetResample8khzTo22khz(&state1); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      int32_t tmpmem[98];
      for (int i = 0; i < len; i += 80) {
        // convert 80 samples to 220 samples
        WebRtcSpl_Resample8khzTo22khz(in, out, &state1, tmpmem);
        in += 160;
        out += 440;
      }
      return len * 11 / 4;
    }

    virtual int Required(int n) override {
      return ((n * 4 + 10) / 11 + 79) / 80 * 80;
    }
  };

  struct Resampler2To11 : Resampler4To11 {
    int32_t state0[8];

    inline Resampler2To11() { memset(state0, 0, sizeof(state0)); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      int16_t tmp[80 << 1];
      for (int i = 0; i < len; i += 40) {
        // convert 40 samples to 80 samples
        WebRtcSpl_UpsampleBy2(in, 40, tmp, state0);  // 40 -> 80

        // convert 80 samples to 220 samples
        Resampler4To11::Resample(tmp, 80, out);
        in += 80;
        out += 440;
      }
      return len * 11 / 2;
    }

    virtual int Required(int n) override {
      return ((n * 2 + 10) / 11 + 39) / 40 * 40;
    }
  };

  struct Resampler8To11 : Base {
    WebRtcSpl_State16khzTo22khz state1;

    inline Resampler8To11() { WebRtcSpl_ResetResample16khzTo22khz(&state1); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      int32_t tmpmem[88];
      for (int i = 0; i < len; i += 160) {
        // convert 160 samples to 220 samples
        WebRtcSpl_Resample16khzTo22khz(in, out, &state1, tmpmem);
        in += 320;
        out += 440;
      }
      return len * 11 / 8;
    }

    virtual int Required(int n) override {
      return ((n * 8 + 10) / 11 + 159) / 160 * 160;
    }
  };

  struct Resampler12To11 : Base {
    WebRtcSpl_State48khzTo16khz state1;
    WebRtcSpl_State8khzTo22khz state2;

    inline Resampler12To11() {
      WebRtcSpl_ResetResample48khzTo16khz(&state1);
      WebRtcSpl_ResetResample8khzTo22khz(&state2);
    }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      int16_t tmp[160 << 1];
      int32_t tmpmem[496];
      for (int i = 0; i < len; i += 480) {
        // convert 480 samples to 440 samples
        WebRtcSpl_Resample48khzTo16khz(in, tmp, &state1,
                                       tmpmem);  // 480 mono -> 160 tmp
        WebRtcSpl_Resample8khzTo22khz(tmp, out, &state2,
                                      tmpmem);  // 80 tmp -> 220 mono
        WebRtcSpl_Resample8khzTo22khz(&tmp[160], &out[440], &state2, tmpmem);
        in += 480 << 1;
        out += 440 << 1;
      }
      return len * 11 / 12;
    }

    virtual int Required(int n) override {
      return ((n * 12 + 10) / 11 + 479) / 480 * 480;
    }
  };

  struct Resampler6To11 : Resampler12To11 {
    int32_t state0[8];

    inline Resampler6To11() { memset(state0, 0, sizeof(state0)); }

    virtual int Resample(const int16_t *in, int len, int16_t *out) override {
      int16_t tmp[480 << 1];
      for (int i = 0; i < len; i += 240) {
        // convert 480 samples to 440 samples
        WebRtcSpl_UpsampleBy2(in, 240, tmp, state0);  // 240 -> 480
        Resampler12To11::Resample(tmp, 480, out);
        in += 240 << 1;
        out += 440 << 1;
      }
      return len * 11 / 6;
    }

    virtual int Required(int n) override {
      return ((n * 6 + 10) / 11 + 239) / 240 * 240;
    }
  };

  union {
    Base base;
    Resampler1To2 resampler1to2;
    Resampler1To4 resampler1to4;
    Resampler2To11 resampler2to11;
    Resampler4To11 resampler4to11;
    Resampler6To11 resampler6to11;
    Resampler8To11 resampler8to11;
    Resampler12To11 resampler12to11;
  };
};

class Resampler {
 private:
  static constexpr int MAX_SAMPLES_ = 1024;
  bool inited_;
  FixedSampleBuffer<int16_t, MAX_SAMPLES_ * 2> buffer_;
  ChannelResampler ch0_, ch1_;

 public:
  int channels = -1;
  int sample_rate = -1;
  int output_sample_rate = -1;

  inline bool Init(int channels, int sample_rate, int output_sample_rate) {
    if (this->channels == channels && this->sample_rate == sample_rate &&
        this->output_sample_rate == output_sample_rate) {
      return inited_;
    }
    this->channels = channels;
    this->sample_rate = sample_rate;
    this->output_sample_rate = output_sample_rate;

    inited_ = ch0_.Init(sample_rate, output_sample_rate);
    if (!inited_) {
      return false;
    }
    buffer_.Clear();

    if (channels == 2) {
      ch1_.Init(sample_rate, output_sample_rate);
    }
    return true;
  }

  inline static void ReadFully(AudioContext &ctx, SampleSource &input,
                               int required, int16_t *output) {
    for (int16_t *curr = output, *end = output + (required << 1); curr < end;) {
      int samples = int((end - curr) >> 1);  // number of samples to read
      samples = AU_MIN(samples, 480);
      // read
      Sample temp(0, curr);
      input.ReadSamples(ctx, temp,
                        samples);  // Pass in MutableSample to reduce one copy
      if (!temp.length) {
        memset(curr, 0, (end - curr) << 1);
        break;
      }
      if (temp.data != curr) {
        memcpy(curr, temp.data, temp.length << 2);
      }
      curr += temp.length << 1;
    }
  }

  inline void Resample(AudioContext &ctx, SampleSource &input, short *output,
                       int len) {
    if (sample_rate == output_sample_rate) {
      ReadFully(ctx, input, len, output);
      if (channels == 1) {
        MonoToStereo(output, len);
      }
      return;
    }

    int buffered =
        buffer_.Length() >> 1;  // buffer interleaved storage with two channels

    if (buffered >= len) {
      buffer_.Fill(output, len << 1);
      return;
    }

    if (buffered) {
      buffer_.Fill(output, buffered << 1);
    }

    int16_t *resampled = buffer_.Resize(0);
    // number of samples to read
    int original_samples = ch0_.Required(len - buffered);
    // fprintf(stderr, "required %d -> %d\n", len - buffered, original_samples);

    int16_t original[MAX_SAMPLES_ * 2];
    ReadFully(ctx, input, original_samples, original);  // original samples

    int output_len = ch0_.Resample(original, original_samples, resampled);
    if (channels == 2) {
      ch1_.Resample(original + 1, original_samples, resampled + 1);
    } else {
      MonoToStereo(resampled, output_len);
    }

    buffer_.Resize(output_len << 1);
    buffer_.Fill(output + (buffered << 1), (len - buffered) << 1);
  }

 private:
  inline static void MonoToStereo(int16_t *data, int samples) {
    for (int i = 0; i < samples; i++) {
      data[(i << 1) + 1] = data[i << 1];
    }
  }
};

Sample SampleSource::Resample(AudioContext &ctx, int samples) {
  if (!resampler_) {
    resampler_ = new Resampler();
  }

  if (!resampler_->Init(channels_, sample_rate_, AU_SAMPLE_RATE)) {
    return {0, nullptr};
  }
  resampler_->Resample(ctx, *this, buffer_, samples);
  return {samples, buffer_};
}

SampleSource::~SampleSource() {
  delete resampler_;
  resampler_ = nullptr;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
