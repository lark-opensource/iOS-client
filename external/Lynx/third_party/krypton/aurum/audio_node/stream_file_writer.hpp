// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/encoder.h"
#include "aurum/util/time.hpp"
#endif

#include "canvas/base/log.h"
#ifdef OS_ANDROID
#include <endian.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

int AudioContext::CreateStreamFileWriterNode() {
  return AllocActiveNode(new AudioStreamFileWriterNode());
}

inline EncoderBase *AutoDetermineEncoder(const char *path) {
  union {
    char chars[4];
    uint32_t value;
  } format;

  const char *tail = path + strlen(path) - 4;
  format.chars[0] = tail[0];
  format.chars[1] = tail[1];
  format.chars[2] = tail[2];
  format.chars[3] = tail[3];

  switch (format.value) {
    case htonl('.mp4'):
    case htonl('.m4a'):
      return encoder::Mp4aAac(path);
    case htonl('.wav'):
      return encoder::RiffWav(path);
    default:
      return nullptr;
  }
}

bool AudioContext::StartStreamFileWriter(int node_id, const std::string &path) {
  AudioStreamFileWriterNode &sf_write_node =
      nodes[node_id].As<AudioStreamFileWriterNode>();

  sf_write_node.Destroy();

  // Create an encoder to start the process.
  const char *entry;
  const char *curi = path.data();
  if (!curi) {
    return false;
  }

  if (strncmp(curi, "file://", 7) == 0) {
    entry = curi + 7;
  } else {
    KRYPTON_LOGE("wrong path: ") << (curi ?: "");
    return false;
  }
  KRYPTON_LOGV("file entry :") << (entry ?: "");

  sf_write_node.SetEncoder(AutoDetermineEncoder(entry));
  return sf_write_node.HasEncoder();
}

void AudioContext::StopStreamFileWriter(int node_id) {
  // Explicitly called when writing needs to be stopped to complete file writing
  KRYPTON_LOGV("stopStreamFileWriter (id ") << node_id << ":)";
  nodes[node_id].As<AudioStreamFileWriterNode>().Destroy();
}

void AudioStreamFileWriterNode::PostProcess(AudioContext &ctx, Sample output) {
  if (!encoder_) {
    return;
  }

  // Use the encoder to send the sample output to the encoder to write the file
  AU_LOCK(encoder_lock_);
  if (encoder_) {
    encoder_->Write(output);
  }
  AU_UNLOCK(encoder_lock_);
}

void AudioStreamFileWriterNode::Destroy() {
  if (encoder_) {
    AU_LOCK(encoder_lock_);
    delete encoder_;
    encoder_ = nullptr;
    AU_UNLOCK(encoder_lock_);
  }
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
