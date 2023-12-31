// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_RTC_HELPER_IMPL_H_
#define LYNX_KRYPTON_RTC_HELPER_IMPL_H_

#include "rtc/krypton_rtc_helper.h"

namespace lynx {
namespace canvas {
namespace rtc {

class RtcHelperImpl : public RtcHelper {
 public:
  RtcHelperImpl() { valid_ = true; }
  Napi::Value CreateRtcEngine(const Napi::CallbackInfo& info) override;
};

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_RTC_HELPER_IMPL_H_
