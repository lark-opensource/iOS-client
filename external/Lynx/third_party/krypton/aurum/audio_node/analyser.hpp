// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/audio_node.h"
#include "fft4g.h"

namespace lynx {
namespace canvas {
namespace au {

inline float ToDecibel(float re, float im, float m) {
  return 10 * log10f(re * re + im * im) - m;
}

inline float FreqMinus(unsigned short count) { return 20 * log10f(count); }

void AudioAnalyserNode::DoFFT() {
  if (transformed_) {
    return;
  }
  // copy the samples to fftbuf and pre multiply the factor
  for (int i = 0; i < count_; ++i) {
    fft_buf_[i] = time_samples_[i] * fft_factor_[i];
  }

  WebRtc_rdft(count_, 1, fft_buf_, ip_, fft_win_);

  short *out = freq_samples_;
  const float m = FreqMinus(count_);
  float factor = 65535.f / (dec_max_ - dec_min_);
  for (const float *cur = fft_buf_, *end = fft_buf_ + count_; cur < end;
       cur += 2) {
    float val = ToDecibel(cur[0], cur[1], m);
    if (val > dec_max_) {
      *out = 32767;
    } else if (val < dec_min_) {
      *out = -32768;
    } else {
      *out = int16_t((val - dec_min_) * factor - 32768);
    }
    out++;
  }

  transformed_ = true;
}

void AudioAnalyserNode::GetByteData(bool is_frequency, int len, uint8_t *ptr) {
  len = AU_MIN(len, (count_ >> 1));  // len <= fftSize / 2

  AU_LOCK(buf_lock_);
  if (!is_frequency) {
    const int16_t *samples = time_samples_;
    for (int i = 0; i < len; i++) {
      int x = *samples++, y = *samples++;
      ptr[i] = uint8_t((x + y + 65536) >> 9);
    }
  } else {
    DoFFT();

    const int16_t *samples = freq_samples_;
    for (int i = 0; i < len; i++) {
      int x = *samples++;
      ptr[i] = uint8_t((x + 32768) >> 8);
    }
  }
  AU_UNLOCK(buf_lock_);
}

void AudioAnalyserNode::GetFloatData(bool is_frequency, int len, float *ptr) {
  len = AU_MIN(len, (count_ >> 1));  // len <= fftSize / 2

  AU_LOCK(buf_lock_);
  if (!is_frequency) {
    const int16_t *samples = time_samples_;
    for (int i = 0; i < len; i++) {
      int x = *samples++, y = *samples++;
      ptr[i] = (x + y) / 65536.f;
    }
  } else {
    DoFFT();

    const int16_t *samples = freq_samples_;
    for (int i = 0; i < len; i++) {
      int x = *samples++;
      ptr[i] = x / 32768.f;
    }
  }
  AU_UNLOCK(buf_lock_);
}

Sample AudioAnalyserNode::OnProcess(AudioContext &ctx, int len) {
  Sample output = AudioProcessorNode::OnProcess(ctx, len);
  if (!output.length) {
    return output;
  }

  AU_LOCK(buf_lock_);

  const SampleFormat *data = output.data;
  // data to populate
  int filled = count_ - pos_;
  filled = AU_MIN(filled, output.length);

  for (int i = 0; i < filled; i++) {
    int l = *data++, r = *data++;
    recv_cache_[pos_++] = (l + r) >> 1;
  }

  if (pos_ == count_) {
    // fill a buffer with the data to be filled
    memcpy(time_samples_, recv_cache_, count_ << 1);
    transformed_ = false;
    pos_ = 0;
  }

  const int fil_max = AU_MIN(count_, output.length);
  while (filled++ < fil_max) {
    int l = *data++, r = *data++;
    recv_cache_[pos_++] = (l + r) >> 1;
  }

  AU_UNLOCK(buf_lock_);
  return output;
}

int AudioContext::CreateAnalyserNode() {
  return AllocActiveNode(new AudioAnalyserNode());
}

void AudioContext::UpdateAnalyserParam(int node_id, AnalyserParam param_id,
                                       int val) {
  AudioAnalyserNode &analyser = nodes[node_id].As<AudioAnalyserNode>();
  if (AnalyserParam::FFTSize == param_id) {
    switch (val) {
      case 128:
        analyser.SetFFTSize<128>();
        break;
      case 256:
        analyser.SetFFTSize<256>();
        break;
      case 512:
        analyser.SetFFTSize<512>();
        break;
      case 1024:
        analyser.SetFFTSize<1024>();
        break;
      case 2048:
        analyser.SetFFTSize<2048>();
        break;
      case 4096:
        analyser.SetFFTSize<4096>();
        break;
      default:
        break;
    }
  } else if (AnalyserParam::MinDecibels == param_id) {
    analyser.SetDecMin(val);
  } else if (AnalyserParam::MaxDecibels == param_id) {
    analyser.SetDecMax(val);
  }
}

void AudioContext::GetAnalyserDataByte(int node_id, bool is_frequency,
                                       int length, unsigned char *buffer_ptr) {
  nodes[node_id].As<AudioAnalyserNode>().GetByteData(is_frequency, length,
                                                     buffer_ptr);
}

void AudioContext::GetAnalyserDataFloat(int node_id, bool is_frequency,
                                        int length, float *buffer_ptr) {
  nodes[node_id].As<AudioAnalyserNode>().GetFloatData(is_frequency, length,
                                                      buffer_ptr);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
