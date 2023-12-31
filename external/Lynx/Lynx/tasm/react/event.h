// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_EVENT_H_
#define LYNX_TASM_REACT_EVENT_H_
#include <optional>
#include <string>
#include <vector>

#include "lepus/value-inl.h"

namespace lynx {
namespace tasm {

struct EventOption {
  // Determines whether the event can bubble. Default value is false.
  bool bubbles_{false};
  // Determines whether the event can cross the component boundary. When it is
  // false, the event will only be triggered on the node tree that references
  // the component, and will not enter any other components. Default value is
  // false.
  bool composed_{false};
  // Determines whether the event has a capture phase. Default value is false.
  bool capture_phase_{false};
  // Determines whether the event is listened by lepus.
  bool lepus_event_{false};
  // Determines whether the event is triggered by fe.
  bool from_frontend_{false};
};

struct PiperEventContent {
  // jsb event function name
  lepus::String piper_func_name_;
  // jsb event function args
  lepus::Value piper_func_args_;

  // Constructor
  // piper_func_name: jsb method name
  // piper_func_args: args needed for jsb method , the format:
  // {tasmEntryName:__Card__, callbackId:0, fromPiper:true, methodDetail:
  // {method:aMethod, module:aModule, param:[arg1, arg2, ...]}}
  PiperEventContent(const lepus::String piper_func_name,
                    const lepus::Value piper_func_args)
      : piper_func_name_(piper_func_name), piper_func_args_(piper_func_args) {}

  lepus::Value ToLepusValue() const;
};

class EventHandler {
 public:
  EventHandler(const lepus::String& type, const lepus::String& name,
               const lepus::String& function)
      : EventHandler(true, type, name, function, lepus::Value(), lepus::Value(),
                     std::nullopt) {}

  EventHandler(const lepus::String& type, const lepus::String& name,
               const lepus::Value& lepus_script,
               const lepus::Value& lepus_function)
      : EventHandler(false, type, name, lepus::String(), lepus_script,
                     lepus_function, std::nullopt) {}

  // Constructor for SSR server events, supports multiply jsb calls.
  EventHandler(
      const lepus::String& type, const lepus::String& name,
      const std::optional<std::vector<PiperEventContent>>& piper_event_vec)
      : EventHandler(true, type, name, lepus::String(), lepus::Value(),
                     lepus::Value(), piper_event_vec) {}

  EventHandler(const EventHandler& other) {
    this->is_js_event_ = other.is_js_event_;
    this->type_ = other.type_;
    this->name_ = other.name_;
    this->function_ = other.function_;
    this->lepus_script_ = other.lepus_script_;
    this->lepus_function_ = other.lepus_function_;
    this->piper_event_vec_ = other.piper_event_vec_;
  }
  virtual ~EventHandler() {}

  EventHandler& operator=(const EventHandler& other) {
    this->is_js_event_ = other.is_js_event_;
    this->type_ = other.type_;
    this->name_ = other.name_;
    this->function_ = other.function_;
    this->lepus_script_ = other.lepus_script_;
    this->lepus_function_ = other.lepus_function_;
    this->piper_event_vec_ = other.piper_event_vec_;
    return *this;
  }

  bool is_js_event() const { return is_js_event_; }
  bool is_piper_event() const { return piper_event_vec_.has_value(); }
  const lepus::String& name() const { return name_; }
  const lepus::String& type() const { return type_; }
  const lepus::String& function() const { return function_; }

  const lepus::Value& lepus_script() const { return lepus_script_; }
  const lepus::Value& lepus_function() const { return lepus_function_; }
  lepus::Value& lepus_function() { return lepus_function_; }

  const std::optional<std::vector<PiperEventContent>>& piper_event_vec() const {
    return piper_event_vec_;
  }

  virtual bool IsBindEvent() const;
  virtual bool IsCatchEvent() const;
  virtual bool IsCaptureBindEvent() const;
  virtual bool IsCaptureCatchEvent() const;
  virtual bool IsGlobalBindEvent() const;

  lepus::Value ToLepusValue() const;

 private:
  EventHandler(
      bool is_js_event, const lepus::String& type, const lepus::String& name,
      const lepus::String& function, const lepus::Value& lepus_script,
      const lepus::Value& lepus_function,
      const std::optional<std::vector<PiperEventContent>>& piper_event_vec)
      : is_js_event_(is_js_event),
        type_(type),
        name_(name),
        function_(function),
        lepus_script_(lepus_script),
        lepus_function_(lepus_function),
        piper_event_vec_(piper_event_vec) {}

  bool is_js_event_;
  lepus::String type_;
  lepus::String name_;
  // JS function name
  lepus::String function_;

  // lepus script, js object
  lepus::Value lepus_script_;
  // lepus function, js object
  lepus::Value lepus_function_;

  // ssr server events vector
  std::optional<std::vector<PiperEventContent>> piper_event_vec_;
};

}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_REACT_EVENT_H_
