// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL

#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include <cmath>
#include <cstdint>

#include "F0Detection.h"
#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace au {

static constexpr float F0_SAMPLE_RATE = 20.0f;

int AudioEffectHelperImpl::CreateF0DetectionNode(AudioContext &ctx, float min,
                                                 float max) {
  return ctx.AllocActiveNode(new AudioF0DetectionNode(min, max));
}

void AudioF0DetectionNode::DoPreDestroy() {
  if (f0_detector_) {
    if (Destroy_F0Inst(f0_detector_) != 0) {
      LOGE("[Aurum] destory f0 detector failed!");
    }
    f0_detector_ = nullptr;
  }
}

void AudioF0DetectionNode::DoPostProcess(AudioContext &ctx, Sample output) {
  if (!f0_detector_) {
    if (Init_F0Inst(f0_detector_, AU_SAMPLE_RATE, min_, max_) < 0) {
      KRYPTON_LOGE("init fo detector failed!");
      return;
    }
  }

  AU_LOCK(buf_lock_);
  //  1 represents that there is no F0 value output, and it is necessary to
  //  continue calling process_ F0inst until 0 is returned
  const size_t size = output.length * channels_;
  std::vector<std::pair<float, float>> tmp;
  while (Process_F0Inst(f0_detector_, output.data, size, tmp) > 0) {
  };

  if (!tmp.empty()) {
    const size_t max_size =
        static_cast<const size_t>(max_strorage_time_ / F0_SAMPLE_RATE);
    const size_t increased_size = tmp.size();
    const size_t cache_size = cache_.size();
    if (cache_size + increased_size > max_size) {
      const size_t gap = cache_size + increased_size - max_size;
      cache_.insert(std::end(cache_), std::begin(tmp), std::begin(tmp) + gap);
      f0_pairs_.swap(cache_);
      cache_.clear();
      cache_.insert(std::end(cache_), std::begin(tmp) + gap, std::end(tmp));
    } else {
      cache_.insert(std::end(cache_), std::begin(tmp), std::end(tmp));
    }
  }

  AU_UNLOCK(buf_lock_);
}

void AudioF0DetectionNode::GetF0DetectionData(int length, float *time,
                                              float *data) {
  AU_LOCK(buf_lock_);
  if (f0_pairs_.empty()) {
    KRYPTON_LOGV("F0 NO DATA");
    AU_UNLOCK(buf_lock_);
    return;
  }

  // the interval is about 20ms (once data)
  const int max = int(f0_pairs_.size());
  for (int i = 0, v = 0; v < max && i < length; v++, i++) {
    time[i] = f0_pairs_[v].first;
    data[i] = f0_pairs_[v].second;
  }

  AU_UNLOCK(buf_lock_);
}

void AudioEffectHelperImpl::GetF0DetectionData(AudioContext &ctx, int node_id,
                                               int length, float *time_array,
                                               float *data_array) {
  ctx.nodes[node_id].As<AudioF0DetectionNode>().GetF0DetectionData(
      length, time_array, data_array);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
