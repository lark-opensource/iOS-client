// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_CAPTURE_BASE_H_
#define LYNX_KRYPTON_AURUM_CAPTURE_BASE_H_

#include <mutex>

#include "aurum/audio_stream.h"
#include "aurum/config.h"

namespace lynx {
namespace canvas {
namespace au {

class CopyStream : public StreamBase {
 public:
  virtual void Start() override { is_valid_ = true; }
  virtual void Stop() override { is_valid_ = false; }
  inline bool IsValid() { return is_valid_; }

 private:
  bool is_valid_ = false;
};

class CaptureBase : public StreamBase {
 public:
  virtual void ForceStart() = 0;
  virtual void ForceStop() = 0;

  // Method called when go to the background, without modifying the business
  // mode
  inline void Pause() {
    std::lock_guard<std::mutex> lock(capture_lock_);
    is_paused_ = true;
    ForceStop();
  }
  // Method called when return to the foreground, without modifying the business
  // mode
  inline void Resume() {
    std::lock_guard<std::mutex> lock(capture_lock_);
    is_paused_ = false;
  }

  virtual void Start() override {
    std::lock_guard<std::mutex> lock(capture_lock_);
    if (!is_paused_) {
      ForceStart();
    }
  }

  virtual void Stop() override {
    std::lock_guard<std::mutex> lock(capture_lock_);
    ForceStop();
  }

 protected:
  CopyStream copy_stream_;

 private:
  bool is_paused_ = false;  // pause (background) the state ensures that the
                            // microphone is not turned on
  std::mutex capture_lock_;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_CAPTURE_BASE_H_
