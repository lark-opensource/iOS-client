// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_PROP_BUNDLE_H_
#define LYNX_TASM_REACT_PROP_BUNDLE_H_

#include <sys/types.h>

#include <memory>
#include <string>
#include <unordered_map>

#include "lepus/value-inl.h"
#include "tasm/react/event.h"

namespace lynx {
namespace tasm {

class PropBundle {
 public:
  PropBundle() : tag_() {}

  virtual ~PropBundle() {}
  virtual void SetNullProps(const char* key) = 0;
  virtual void SetProps(const char* key, unsigned int value) = 0;
  virtual void SetProps(const char* key, int value) = 0;
  virtual void SetProps(const char* key, const char* value) = 0;
  virtual void SetProps(const char* key, bool value) = 0;
  virtual void SetProps(const char* key, double value) = 0;
  virtual void SetProps(const char* key, const lepus::Value& value) = 0;
  virtual void SetEventHandler(const EventHandler& handler) = 0;
  virtual void ResetEventHandler() = 0;

  inline const lepus::String& tag() const { return tag_; }
  inline void set_tag(const lepus::String& tag) { tag_ = tag; }

  static std::unique_ptr<PropBundle> Create();

 private:
  lepus::String tag_;
  std::unordered_map<std::string, EventHandler*> event_handler_map;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_PROP_BUNDLE_H_
