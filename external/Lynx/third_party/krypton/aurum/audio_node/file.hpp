// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "aurum/audio_engine.h"
#include "aurum/decoder.h"

namespace lynx {
namespace canvas {
namespace au {

static inline uint32_t SDBMHash(const uint8_t *path, int len) {
  uint32_t hash = 0xffffffff;
  for (int i = 0; i < len; i++) {
    hash = hash * 65599 + path[i];
  }
  return hash;
}

static int FindLoader(AudioContext &ctx, const char *path, int path_len) {
  uint32_t hash = SDBMHash(reinterpret_cast<const uint8_t *>(path), path_len);

  for (auto it = ctx.loaders.Begin(); it.Next();) {
    AudioLoader &loader = *it;
    int path_offset = path_len - sizeof(loader.path);
    if (loader.hash == hash && loader.path_len == path_len &&
        !strncmp(path + (AU_MAX(path_offset, 0)), loader.path,
                 sizeof(loader.path))) {
      loader.deref_countdown = 0x7fffffff;  // reset countdown
      return it.id;
    }
  }

  const char *curi = path;
  if (!curi) {
    return -1;
  }

  AudioLoader &loader = ctx.loaders.Alloc();
  loader.hash = hash;
  loader.path_len = path_len;

  int path_offset = path_len - sizeof(loader.path);
  strncpy(loader.path, path + (AU_MAX(path_offset, 0)), sizeof(loader.path));

  PlatformLoaderDelegate *delegate = nullptr;
  loader::Platform(&loader.base, curi, (void **)&delegate);

  auto &platform = ctx.engine->GetPlatform();
  platform.LoadAsync(platform.user_ptr, path, delegate);
  return loader.id;
}

static inline void UnRef(Pool<AudioLoader, 8> &loaders, int id) {
  if (id == -1) {
    return;
  }

  AudioLoader &loader = loaders[id];
  loader.refs--;

  if (!loader.refs) {
    loader.deref_countdown = 10;  // release loader after about 10s
  }
}

void AudioContext::ResetAudioLoader(int audio_id, const std::string &path) {
  Audio &audio = audios[audio_id];

  audio.canplay = false;  // canplay needs to be triggered
  audio.decoder.Reset();
  audio.ResetAudioIdle();

  UnRef(loaders, audio.loader);
  audio.loader = -1;

  if (!path.length()) {
    return;
  }

  int loader = FindLoader(*this, path.c_str(), int(path.length()));
  if (loader == -1) {
    return;
  }
  loaders[loader].refs++;

  audio.loader = loader;
}

void AudioContext::SetAudioBufferLoader(int audio_id, int length,
                                        const void *ptr) {
  Audio &audio = audios[audio_id];

  audio.canplay = false;  // canplay needs to be triggered
  audio.decoder.Reset();
  audio.ResetAudioIdle();

  UnRef(loaders, audio.loader);
  audio.loader = -1;

  AudioLoader &loader = AllocLoader();
  loader::Buffer(&loader.base, ptr, length, true);
  loader.deref_countdown = 0x7fffffff;
  loader.refs++;

  audio.loader = loader.id;
}

int AudioContext::CreateAudioElementSourceNode(int audio_id) {
  return AllocNode(new AudioElementSourceNode(audios[audio_id]));
}

void AudioElementSourceNode::OnMeta(const DecoderBase *decoder) {
  const auto &meta = decoder->GetMetaRef();
  channels_ = meta.channels;
  sample_rate_ = meta.sample_rate;
}

inline void AudioElementSourceNode::OnError(AudioContext &ctx,
                                            std::string err_msg) {
  // release loader and reset status
  this->Dispatch(NodeEvent::Error, ctx, err_msg);
  audio_.decoder.Reset();
  UnRef(ctx.loaders, audio_.loader);
  audio_.loader = -1;
  audio_.ResetAudioIdle();
}

Sample AudioElementSourceNode::OnProcess(AudioContext &ctx, int len) {
  struct LoaderRef {
    AudioContext &ctx;
    int loader_id;

    inline LoaderRef(AudioContext &ctx, Audio &audio)
        : ctx(ctx), loader_id(audio.loader) {
      if (loader_id >= 0) {
        ctx.loaders[loader_id].refs++;
      }
    }

    inline ~LoaderRef() { UnRef(ctx.loaders, loader_id); }
  };

  LoaderRef loader_ref(ctx, audio_);
  if (loader_ref.loader_id == -1) {
    return {0, nullptr};
  }

  LoaderBase &loader = ctx.loaders[loader_ref.loader_id].base;

  if (!audio_.canplay) {
    // init decoder
    Ref<DecoderBase> decoder_ref = audio_.decoder;
    DecoderBase *decoder = decoder_ref.Get();

    if (!decoder) {
      decoder = loader.Decoder();
      if (!decoder) {
        return {0, nullptr};
      }
      audio_.decoder.Reset(decoder);
      decoder_ref.Reset(decoder);
    }

    if (decoder->GetState() == DecoderState::Init) {
      decoder->ReadMeta();
    }

    if (decoder->GetState() != DecoderState::Meta) {
      if (decoder->GetState() == DecoderState::Error) {
        // Do not retry creating the decoder until the src is reset
        this->OnError(ctx,
                      "(Decode Error) AudioElementSourceNode OnProcess: first "
                      "decoder state is error");
      }
      return {0, nullptr};
    }

    DCHECK(decoder->GetState() == DecoderState::Meta);
    OnMeta(decoder);
    audio_.canplay = true;
    const auto &meta = decoder->GetMetaRef();
    if (meta.samples == -1) {
      audio_.duration = 0;
    } else {
      audio_.duration = double(meta.samples) / meta.sample_rate;
    }
    Dispatch(AudioNodeBase::NodeEvent::CanPlay, ctx);
    audio_.decoder.Reset();  // release the decoder until play is called
  }

  DCHECK(audio_.canplay);
  audio_.executeActions(ctx, this);
  if (!audio_.started) {
    return {0, nullptr};
  }

  // init decoder
  Ref<DecoderBase> decoder_ref = audio_.decoder;
  DecoderBase *decoder = decoder_ref.Get();

  if (!decoder) {
    decoder = loader.Decoder();
    if (!decoder) {
      return {0, nullptr};
    }
    audio_.decoder.Reset(decoder);
    decoder_ref.Reset(decoder);
    if (decoder->GetState() == DecoderState::Meta) {
      OnMeta(decoder);
    }
  }

  if (decoder->GetState() == DecoderState::Init) {
    decoder->ReadMeta();
    if (decoder->GetState() == DecoderState::Meta) {
      OnMeta(decoder);
    }
  }

  if (decoder->GetState() != DecoderState::Meta) {
    if (decoder->GetState() == DecoderState::Error) {
      this->OnError(ctx,
                    "(Decode Error) AudioElementSourceNode OnProcess: second "
                    "decoder state is error");
    }

    return {0, nullptr};
  }

  Sample output = Resample(ctx, len);
  DoMultiply(output, audio_.volume);
  return output;
}

void AudioElementSourceNode::ReadSamples(AudioContext &ctx, Sample &output,
                                         int len) {
  if (!audio_.started) {
    return;
  }

  DecoderBase *decoder = audio_.decoder.Get();
  if (!decoder) {
    // resetAudioLoader may be called during decoding, resulting audio.decoder
    // be cleared, waiting for the next decoding cycle
    output.length = 0;
    return;
  }
  // read
  const auto &meta = decoder->GetMetaRef();

  if (audio_.current_time_is_dirty) {
    audio_.current_sample = audio_.current_time * meta.sample_rate;
    audio_.current_time_is_dirty = false;
  }

  if (meta.samples != -1 && audio_.current_sample + len > meta.samples) {
    int32_t samples_to_decode = meta.samples - audio_.current_sample;
    if (samples_to_decode > 0) {
      decoder->Decode(output, audio_.current_sample, samples_to_decode);
    }
  } else {
    decoder->Decode(output, audio_.current_sample, len);
  }

  switch (decoder->GetState()) {
    case DecoderState::Init:  // should not reach here
    case DecoderState::Meta:
      break;
    case DecoderState::Error:
      audio_.started = false;
      this->Dispatch(
          NodeEvent::Error, ctx,
          "(Decode Error) AudioElementSourceNode ReadSamples : decoder "
          "state is error");
      return;
    case DecoderState::EndOfFile:  // read to the end of the stream, copy the
                                   // output and send the end message
      break;
  }

  audio_.current_sample += output.length;
  if ((meta.samples != -1 && audio_.current_sample >= meta.samples) ||
      decoder->GetState() == DecoderState::EndOfFile) {
    if (audio_.loop) {
      audio_.current_sample = 0;
      decoder->SetState(DecoderState::Meta);
    } else {
      audio_.started = false;
      audio_.current_sample = meta.samples;
      audio_.status = Audio::Status::Ended;
      this->Dispatch(NodeEvent::End, ctx);
      audio_.decoder.Reset();
    }
  }

  double current_time = double(audio_.current_sample) / meta.sample_rate;
  if (!audio_.current_time_is_dirty) {
    audio_.current_time = current_time;
  }
  audio_.time_offset = CurrentTimeUs() / 1.0e6 - current_time;
  // During debugging, you can comment below to reduce the impact
  this->Dispatch(NodeEvent::TimeUpdate, ctx);
  // audio.Dispatch(this, kNodeEventTimeUpdate, ctx);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
