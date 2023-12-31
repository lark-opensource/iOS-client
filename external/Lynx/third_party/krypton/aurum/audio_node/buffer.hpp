// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif

namespace lynx {
namespace canvas {
namespace au {

int AudioContext::CreateBufferSourceNode() {
  return AllocNode(new AudioBufferSourceNode());
}

void AudioContext::SetBuffer(int node_id, int channels, int sample_rate,
                             int length, const float *ptr) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  buffer.SetBuffer(channels, sample_rate, length, ptr);
}

void AudioContext::ClearBuffer(int node_id) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  buffer.ClearBuffer();
}

void AudioContext::SetBufferLoop(int node_id, bool loop) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  buffer.SetLoop(loop);
}

void AudioContext::StartBuffer(int node_id, float offset) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  buffer.Start(offset);
}

void AudioContext::StopBuffer(int node_id) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  buffer.Stop();
}

inline void Copy(short *output, const float *input, int count) {
  for (int i = 0; i < count; i++) {
    output[i << 1] = input[i] * 0x7fff;
  }
}

inline void Copy(float *output, const float *input, int count) {
  for (int i = 0; i < count; i++) {
    output[i << 1] = input[i];
  }
}

template <typename SampleType>
inline void Copy(SampleType *output, const float *input, int count, bool mono,
                 int length) {
  Copy(output, input, count);
  if (!mono) {
    Copy(output + 1, input + length, count);
  }
}

Sample AudioBufferSourceNode::OnProcess(AudioContext &ctx, int len) {
  if (!started_ || !length_) {
    return {0, nullptr};
  }

  return Resample(ctx, len);
}

void AudioBufferSourceNode::SetBuffer(int channels, int sample_rate, int length,
                                      const float *ptr) {
  channels_ = channels;
  sample_rate_ = sample_rate;
  length_ = length;
  ptr_ = ptr;
  sample_offset_ = total_offset_ = 0;
}

void AudioBufferSourceNode::ClearBuffer() {
  channels_ = 0;
  sample_rate_ = 0;
  length_ = 0;
  ptr_ = nullptr;
  sample_offset_ = total_offset_ = 0;
}

void AudioBufferSourceNode::ReadSamples(AudioContext &ctx, Sample &output,
                                        int len) {
  if (!started_) {
    return;
  }

  if (int(sample_offset_) > length_) {
    if (!loop_) {
      return;
    }
    sample_offset_ %= length_;
  }

  output.length = len;

  bool mono = channels_ == 1;

  if (int(sample_offset_) > length_ - len) {
    if (loop_) {                               // splice tail and head
      int residue = length_ - sample_offset_;  // tail
      // copy tail segment first
      Copy(output.data, ptr_ + sample_offset_, residue, mono, length_);
      // number of samples to be copied
      sample_offset_ = len - residue;  // head
      Copy(output.data + (residue << 1), ptr_, sample_offset_, mono, length_);
    } else if (int(sample_offset_) < length_) {
      // copy tail segment only
      Copy(output.data, ptr_ + sample_offset_, length_ - sample_offset_, mono,
           length_);
      output.length = length_ - sample_offset_;
      sample_offset_ = length_;
      started_ = false;
    } else {
      output.length = 0;
      started_ = false;
    }
  } else {
    Copy(output.data, ptr_ + sample_offset_, len, mono, length_);
    sample_offset_ += len;
  }
  total_offset_ += len;

  if (!started_) {
    Dispatch(NodeEvent::End, ctx);
  }
}

int AudioContext::GetBufferOffset(AudioNodeID node_id) {
  AudioBufferSourceNode &buffer = nodes[node_id].As<AudioBufferSourceNode>();
  return buffer.TotalOffset();
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
