// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_STREAM_H_
#define LYNX_KRYPTON_AURUM_STREAM_H_

#include "aurum/audio_node.h"
#include "aurum/audio_stream.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioContext::CreateStreamSourceNode(uint64_t stream_id) {
  StreamBase *stream = reinterpret_cast<StreamBase *>(stream_id);
  return AllocNode(
      new AudioStreamSourceNode(stream, stream ? stream->GetChannels() : 0,
                                stream ? stream->GetSampleRate() : 0));
}

void AudioStreamSourceNode::Setup() {
  if (stream_) {
    stream_->Start();
  }
}

void AudioStreamSourceNode::Cleanup() {
  if (stream_) {
    stream_->Stop();
  }
}

void AudioStreamSourceNode::ReadSamples(AudioContext &ctx, Sample &output,
                                        int len) {
  if (!stream_) {
    return;
  }

  output.length = stream_->Read(output.data, len);
}

AudioStreamSourceNode::~AudioStreamSourceNode() {
  // no delete stream;
  // capture node is directly deleted in the AudioEngine destructor
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_STREAM_H_
