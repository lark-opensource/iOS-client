// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_JS_OBJECT_PAIR_H_
#define CANVAS_UTIL_JS_OBJECT_PAIR_H_

#include "jsbridge/napi/shim/shim_napi.h"

#define OBJECT_OR_NULL(obj) obj ? obj.js_value() : Env().Null()

namespace lynx {
namespace canvas {
template <typename T>
class JsObjectPair {
 public:
  constexpr JsObjectPair() : native_obj_(nullptr) {}

  constexpr JsObjectPair(T* native_obj) : js_obj_(), native_obj_(native_obj) {
    if (native_obj) {
      js_obj_ = native_obj->ObtainStrongRef();
    }
  }

  constexpr JsObjectPair(const JsObjectPair<T>& other)
      : js_obj_(), native_obj_(other.native_obj_) {
    if (native_obj_) {
      js_obj_ = native_obj_->ObtainStrongRef();
    }
  }

  JsObjectPair<T>& operator=(const JsObjectPair<T>& other) {
    native_obj_ = other.native_obj_;
    if (native_obj_) {
      js_obj_ = native_obj_->ObtainStrongRef();
    }
    return *this;
  }

  JsObjectPair<T>& operator=(JsObjectPair<T>&& other) {
    native_obj_ = other.native_obj_;
    js_obj_ = std::move(other.js_obj_);
    return *this;
  }

  constexpr operator bool() const { return native_obj_; }

  constexpr T* operator->() const { return native_obj_; }

  operator T*() const { return native_obj_; }

  T* native_obj() const { return native_obj_; }

  Napi::Value js_value() { return js_obj_.Value(); }

 private:
  Napi::ObjectReference js_obj_;
  T* native_obj_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_JS_OBJECT_PAIR_H_
