// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_RTC_HELPER_H_
#define LYNX_KRYPTON_RTC_HELPER_H_

#include <memory>

#include "base/base_export.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
namespace rtc {

class RtcHelper {
 public:
  BASE_EXPORT static RtcHelper& Instance();
  BASE_EXPORT static bool IsValid() { return Instance().valid_; }
  void RegisterRtcBindings(Napi::Object& obj);

  virtual void RegisterImpl(RtcHelper* ptr) {}
  virtual void* GetAppContext() { return nullptr; }

  virtual Napi::Value CreateRtcEngine(const Napi::CallbackInfo& info) = 0;

 protected:
  std::atomic<bool> valid_ = false;
};

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_RTC_HELPER_H_
