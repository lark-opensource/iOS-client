// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include <cstdint>

#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "ae_volume_detection.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioEffectHelperImpl::CreateVolumeDetectionNode(AudioContext &ctx) {
  return ctx.AllocActiveNode(new AudioVolumeDetectionNode());
}

void AudioVolumeDetectionNode::DoPreDestroy() {
  if (vd_pointer_) {
    Destroy_VolumeInst(vd_pointer_);
    vd_pointer_ = nullptr;
  }
}

void AudioVolumeDetectionNode::DoPostProcess(AudioContext &ctx, Sample output) {
  if (!vd_pointer_) {
    if (Init_VolumeInst(vd_pointer_, AU_SAMPLE_RATE) < 0) {
      KRYPTON_LOGE("init fo volume failed!");
      return;
    }
  }

  AU_LOCK(buf_lock_);
  // 1 represents no F0 value output. You need to continue calling
  // Process_VolumeInst until 0 is returned
  const size_t size = output.length * channels_;
  std::vector<std::pair<float, float>> tmp;
  while (Process_VolumeInst(vd_pointer_, output.data, size, tmp) > 0) {
  };

  if (!tmp.empty()) {
    const size_t max_size =
        static_cast<const size_t>(max_strorage_time_ / F0_SAMPLE_RATE);
    const size_t increased_size = tmp.size();
    const size_t cache_size = cache_.size();
    if (cache_size + increased_size > max_size) {
      const size_t gap = cache_size + increased_size - max_size;
      cache_.insert(std::end(cache_), std::begin(tmp), std::begin(tmp) + gap);
      volume_paris_.swap(cache_);
      cache_.clear();
      cache_.insert(std::end(cache_), std::begin(tmp) + gap, std::end(tmp));
    } else {
      cache_.insert(std::end(cache_), std::begin(tmp), std::end(tmp));
    }
  }

  AU_UNLOCK(buf_lock_);
}

void AudioVolumeDetectionNode::GetVolumeDetectionData(int length, float *time,
                                                      float *data) {
  AU_LOCK(buf_lock_);
  if (volume_paris_.empty()) {
    AU_UNLOCK(buf_lock_);
    return;
  }

  // the interval is about 20ms (once data)
  const size_t max = volume_paris_.size();
  for (size_t i = 0, v = 0; v < max && i < size_t(length); v++, i++) {
    time[i] = volume_paris_[v].first;
    data[i] = volume_paris_[v].second;
  }

  AU_UNLOCK(buf_lock_);
}

void AudioEffectHelperImpl::GetVolumeDetectionData(AudioContext &ctx,
                                                   int node_id, int length,
                                                   float *time_array,
                                                   float *data_array) {
  ctx.nodes[node_id].As<AudioVolumeDetectionNode>().GetVolumeDetectionData(
      length, time_array, data_array);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
