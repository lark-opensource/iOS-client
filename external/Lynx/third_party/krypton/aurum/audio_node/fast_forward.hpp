// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/encoder.h"
#endif

namespace lynx {
namespace canvas {
namespace au {

struct AudioFastForwardNode::StopFastForwardTask {
  AudioContext &ctx;
  AudioFastForwardNode &node;

  StopFastForwardTask(AudioContext &ctx, AudioFastForwardNode &node)
      : ctx(ctx), node(node) {}

  static void run(StopFastForwardTask *task) {
    AU_LOCK(task->node.encoder_lock_);
    delete task->node.encoder_;
    task->node.encoder_ = nullptr;
    AU_UNLOCK(task->node.encoder_lock_);

    task->node.Dispatch(AudioNodeBase::NodeEvent::End, task->ctx);
    delete task;
  }
};

Sample AudioFastForwardNode::OnProcess(AudioContext &ctx, int len) {
  if (!encoder_ || !start_flag_ || len < 441) {
    return {0, nullptr};
  }

  static constexpr uint32_t AU_CONSUME_TIMEOUT =
      10000;  // The consumption time is limited to 10ms
  static constexpr int32_t AU_FFWD_SAMPLES =
      480;  // 480 samples processed at a time

  uint64_t time_now = CurrentTimeUs();
  uint64_t deadline =
      (AU_CONSUME_TIMEOUT + time_now + ctx.consume_begin_time) / 2;

  int saved_generation = generation_;
  while (time_now < deadline && ffwd_count_down_) {
    int ffwd_samples =
        AU_MIN(AU_FFWD_SAMPLES,
               ffwd_count_down_);  // specifies the maximum number
                                   // of samples per process

    generation_ = ++ffwd_generation_;
    Sample output = AudioStreamFileWriterNode::OnProcess(ctx, ffwd_samples);
    if (!output.length) {
      // write 0
      short zeroBuffer[AU_FFWD_SAMPLES * 2] = {0};
      output.length = ffwd_samples;
      output.data = zeroBuffer;

      AU_LOCK(encoder_lock_);
      if (encoder_) {
        encoder_->Write(output);
      }
      AU_UNLOCK(encoder_lock_);
    }

    ffwd_count_down_ -= ffwd_samples;
    time_now = CurrentTimeUs();
  }
  generation_ = saved_generation;

  if (0 == ffwd_count_down_) {
    // asynchronous execution to prevent jamming caused by destroying the
    // encoder
    ctx.engine->Execute(new StopFastForwardTask(ctx, *this),
                        StopFastForwardTask::run);

    start_flag_ = false;
  }
  return {0, nullptr};
}

int AudioContext::CreateFastForwardNode() {
  return AllocActiveNode(new AudioFastForwardNode());
}

bool AudioContext::StartFastForward(AudioNodeID node_id, Utf8Value path,
                                    int samples) {
  AudioFastForwardNode &fast_forward_node =
      nodes[node_id].As<AudioFastForwardNode>();
  fast_forward_node.Destroy();
  if (fast_forward_node.HasEncoder()) {
    KRYPTON_LOGE("call FFWD start after FFWDNode ended");
    return false;
  }

  std::string uri;
  const char *entry;
  const char *curi = uri.data();
  if (!curi) {
    return false;
  }

  if (strncmp(curi, "file://", 7) == 0) {
    entry = curi + 7;
  } else {
    // unsupported type
    KRYPTON_LOGE("wrong FFwdNode path") << (curi ?: "");
    return false;
  }
  KRYPTON_LOGI("file entry :") << (entry ?: "");

  fast_forward_node.SetEncoder(AutoDetermineEncoder(entry));
  fast_forward_node.SetFFWDCountDown(samples);

  fast_forward_node.SetStartFlag(true);

  return fast_forward_node.HasEncoder();
}
}  // namespace au
}  // namespace canvas
}  // namespace lynx
