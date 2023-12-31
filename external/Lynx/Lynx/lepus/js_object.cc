#include "lepus/js_object.h"

namespace lynx {
namespace lepus {
lynx::base::scoped_refptr<LEPUSObject> LEPUSObject::Create() {
  return base::AdoptRef<LEPUSObject>(
      new LEPUSObject(std::shared_ptr<JSIObjectProxy>()));
}

LEPUSObject::LEPUSObject(std::shared_ptr<JSIObjectProxy> lepus_obj_proxy)
    : jsi_object_proxy_(lepus_obj_proxy) {}

LEPUSObject::JSIObjectProxy::JSIObjectProxy(int64_t id) : jsi_object_id_(id) {}

void LEPUSObject::ReleaseSelf() const { delete this; }

std::shared_ptr<LEPUSObject::JSIObjectProxy> LEPUSObject::jsi_object_proxy() {
  return jsi_object_proxy_;
}

int64_t LEPUSObject::JSIObjectID() {
  return jsi_object_proxy_ ? jsi_object_proxy_->jsi_object_id() : -1;
}

bool operator==(const LEPUSObject& left, const LEPUSObject& right) {
  if (!left.jsi_object_proxy_ || !right.jsi_object_proxy_) {
    return (!left.jsi_object_proxy_ && !right.jsi_object_proxy_) ? true : false;
  } else {
    return left.jsi_object_proxy_->jsi_object_id() ==
           right.jsi_object_proxy_->jsi_object_id();
  }
}

}  // namespace lepus
}  // namespace lynx
