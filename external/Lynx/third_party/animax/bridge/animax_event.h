// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BRIDGE_ANIMAX_EVENT_H_
#define ANIMAX_BRIDGE_ANIMAX_EVENT_H_

#include <string>

namespace lynx {
namespace animax {

class AnimaXElement;

static const std::string kKeyCode = "code";
static const std::string kKeyMessage = "msg";

static const std::string kKeyFps = "fps";
static const std::string kKeyMaxDropRate = "max_drop_rate";

static const std::string kKeyAnimationId = "animationID";
static const std::string kKeyCurrent = "current";
static const std::string kKeyTotal = "total";
static const std::string kKeyLoopIndex = "loopIndex";

enum class Event : uint8_t {
  kCompletion = 0,  // Play completion
  kStart,           // Animation starts
  kRepeat,          // A new loop starts
  kCancel,          // TODO(liuyufeng.0716): implement
  kReady,   // Resource are ready, you can call Play() if autoplay is false
  kUpdate,  // A new frame
  kError,   // Error occurs, more information can be found in error code and
            // error message
  kFps,     // Fps and max drop value event
};

enum class EventError : int32_t {
  kSuccess = 0,
  kResourceNotFound = 1,
  // kScaleImageFailed = 2, // Reserved
  // kRecreateBitmapFailed = 3, // Reserved
  kLocalResourceNotFound = 4,  // TODO(liuyufeng.0716): implement
};

class IEventParams {
 public:
  virtual ~IEventParams() = default;
};

class FpsParams : public IEventParams {
 public:
  FpsParams(int32_t max_drop_rate, double fps)
      : max_drop_rate_(max_drop_rate), fps_(fps) {}
  ~FpsParams() override = default;

  int32_t max_drop_rate_;
  double fps_;
};

class ErrorParams : public IEventParams {
 public:
  ErrorParams(EventError error, std::string message)
      : error_code_(static_cast<int32_t>(error)),
        error_message_(std::move(message)) {}
  ~ErrorParams() override = default;

  int32_t error_code_;
  std::string error_message_;
};

using EventListener =
    std::function<void(AnimaXElement *, const Event, IEventParams *)>;

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BRIDGE_ANIMAX_EVENT_H_
