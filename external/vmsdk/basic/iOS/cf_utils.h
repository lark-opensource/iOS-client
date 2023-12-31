//
//  cf_utils.h
//  vmsdk
//
//  Created by bytedance on 2022/10/17.
//

#ifndef VMSDK_BASIC_IOS_CF_UTILS_H
#define VMSDK_BASIC_IOS_CF_UTILS_H
namespace vmsdk {
namespace general {
template <class T>
class CFRef {
 public:
  CFRef() : instance_(nullptr) {}

  CFRef(T instance) : instance_(instance) {}

  CFRef(const CFRef& other) : instance_(other.instance_) {
    if (instance_) {
      CFRetain(instance_);
    }
  }

  CFRef(CFRef&& other) : instance_(other.instance_) {
    other.instance_ = nullptr;
  }

  CFRef& operator=(CFRef&& other) {
    Reset(other.Release());
    return *this;
  }

  ~CFRef() {
    if (instance_ != nullptr) {
      CFRelease(instance_);
    }
    instance_ = nullptr;
  }

  void Reset(T instance = nullptr) {
    if (instance_ != nullptr) {
      CFRelease(instance_);
    }

    instance_ = instance;
  }

  [[nodiscard]] T Release() {
    auto instance = instance_;
    instance_ = nullptr;
    return instance;
  }

  operator T() const { return instance_; }

  operator bool() const { return instance_ != nullptr; }

 private:
  T instance_;

  CFRef& operator=(const CFRef&) = delete;
};
}  // namespace general
}  // namespace vmsdk
#endif /* cf_utils_h */
