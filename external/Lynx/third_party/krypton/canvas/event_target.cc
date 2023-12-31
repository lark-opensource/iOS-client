// Copyright 2021 The Lynx Authors. All rights reserved.

#include "event_target.h"

#include "canvas/event.h"
#include "jsbridge/bindings/canvas/napi_event.h"
#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace canvas {

using piper::CallbackHelper;

// todo Support object as param
#define LISTENER_CHECKER(l) \
  if (!l.IsFunction()) return;

void EventTarget::AddEventListener(const std::string &type,
                                   Napi::Object listener, bool capture) {
  //  LISTENER_CHECKER(listener)
  //  auto it = _listeners.find(type);
  //  if (it != _listeners.end()) {
  //    it->second.emplace_back(listener);
  //  } else {
  //    _listeners.emplace(std::make_pair(type,
  //    std::vector<Napi::Object>({listener})));
  //  }
}

void EventTarget::RemoveEventListener(const std::string &type,
                                      Napi::Object listener, bool capture) {
  //  LISTENER_CHECKER(listener)
  //  auto it = _listeners.find(type);
  //  if (it == _listeners.end()) return;
  //  auto res = std::find(it->second.begin(), it->second.end(), listener);
  //  if (res != it->second.end()) {
  //    it->second.erase(res);
  //  }
}

bool EventTarget::DispatchEvent(Event *event) {
  // todo
  return true;
}

void EventTarget::TriggerEventListeners(const std::string &type,
                                        const Napi::Value &payload) {
  if (JsObject().Has("triggerEvent")) {
    Napi::Value callback = JsObject()["triggerEvent"];
    if (callback.IsFunction()) {
      CallbackHelper helper;
      Napi::Function callback_function = callback.As<Napi::Function>();
      if (helper.PrepareForCall(callback_function)) {
        helper.CallWithThis(JsObject(),
                            {Napi::String::New(Env(), type), payload});
      }
    }
  }
}

void EventTarget::ResetEventListenerStatus(const std::string &type,
                                           bool hasListeners) {
  auto it = std::find(listen_events_.begin(), listen_events_.end(), type);
  if (hasListeners) {
    if (it == listen_events_.end()) {
      listen_events_.emplace_back(type);
    }
  } else {
    if (it != listen_events_.end()) {
      listen_events_.erase(it);
    }
  }
}

bool EventTarget::GetEventListenerStatus(const std::string &type) {
  auto onType = "on" + type;
  // if has onEvent listener, e.g. canvas.ontouchmove
  if (JsObject().Has(onType.c_str())) {
    return true;
  }
  auto it = std::find(listen_events_.begin(), listen_events_.end(), type);
  if (it != listen_events_.end()) {
    return true;
  }
  return false;
}

}  // namespace canvas
}  // namespace lynx
