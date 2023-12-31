// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_JS_OBJECT_H_
#define LYNX_LEPUS_JS_OBJECT_H_

#include <memory>
#include <unordered_map>

#include "base/ref_counted.h"

namespace lynx {
namespace lepus {

class LEPUSObject : public base::RefCountedThreadSafeStorage {
 public:
  class JSIObjectProxy {
   public:
    JSIObjectProxy(int64_t id);
    virtual ~JSIObjectProxy() = default;
    int64_t jsi_object_id() { return jsi_object_id_; }

   protected:
    int64_t jsi_object_id_;
  };
  static lynx::base::scoped_refptr<LEPUSObject> Create();
  static base::scoped_refptr<LEPUSObject> Create(
      std::shared_ptr<JSIObjectProxy> proxy) {
    return base::AdoptRef<LEPUSObject>(new LEPUSObject(proxy));
  }

  LEPUSObject(std::shared_ptr<JSIObjectProxy> lepus_obj_proxy);

  virtual void ReleaseSelf() const override;

  std::shared_ptr<LEPUSObject::JSIObjectProxy> jsi_object_proxy();

  // return -1 if no JSIObjectProxy
  int64_t JSIObjectID();

  friend bool operator==(const LEPUSObject& left, const LEPUSObject& right);

  friend bool operator!=(const LEPUSObject& left, const LEPUSObject& right) {
    return !(left == right);
  }

 private:
  std::shared_ptr<JSIObjectProxy> jsi_object_proxy_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_JS_OBJECT_H_
