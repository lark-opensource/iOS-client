// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_NAPI_EVENT_CHANNEL_H_
#define LYNX_HEADLESS_NAPI_EVENT_CHANNEL_H_

#include <memory>
#include <string>
#include <utility>

#include "base/blocking_queue.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {
namespace headless {

class EventChannel : public Napi::ObjectWrap<EventChannel> {
 public:
  explicit EventChannel(const Napi::CallbackInfo& info);
  ~EventChannel() override;

  static Napi::Function GetConstructor(Napi::Env env);

  Napi::Value AsyncIterator(const Napi::CallbackInfo& info);
  Napi::Value Next(const Napi::CallbackInfo& info);
  Napi::Value Close(const Napi::CallbackInfo& info);

 private:
  Napi::Reference<Napi::Object> lynx_view_;
  std::string event_name_;
  std::shared_ptr<base::BlockingQueue<std::pair<bool, void*>>> queue_;
  int id_;
  bool closed_ = false;
};

}  // namespace headless
}  // namespace lynx

#undef Napi

#endif  // LYNX_HEADLESS_NAPI_EVENT_CHANNEL_H_
