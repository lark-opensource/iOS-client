// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_BUILDER_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_BUILDER_H_
#include <functional>
#include <memory>
#include <string>
#include <utility>

#include "lynx_export.h"
#include "shell/renderkit/public/lynx_basic_types.h"
#include "shell/renderkit/public/lynx_config.h"
#include "shell/renderkit/public/lynx_group.h"
#include "shell/renderkit/public/lynx_resource_provider.h"

namespace lynx {

struct AsyncCallBackProbe {};
template <typename T, typename A>
class AsyncCallBackHandler {
 public:
  typedef void (T::*MemFunPtr)(A, const std::string&, int32_t);
  AsyncCallBackHandler(MemFunPtr mem_fun_ptr, T* obj,
                       const std::shared_ptr<AsyncCallBackProbe>& probe)
      : mem_fun_ptr_(mem_fun_ptr),
        object_this_(obj),
        async_callback_probe_(probe) {}

  AsyncCallBackHandler(MemFunPtr mem_fun_ptr, T* obj,
                       const std::shared_ptr<AsyncCallBackProbe>& probe,
                       const std::string& url, int32_t id)
      : mem_fun_ptr_(mem_fun_ptr),
        object_this_(obj),
        async_callback_probe_(probe),
        async_url_(url),
        callback_id_(id) {}

  AsyncCallBackHandler(const AsyncCallBackHandler& other)
      : mem_fun_ptr_(other.mem_fun_ptr_),
        object_this_(other.object_this_),
        async_callback_probe_(other.async_callback_probe_),
        async_url_(other.async_url_),
        callback_id_(other.callback_id_) {}

  AsyncCallBackHandler& operator=(const AsyncCallBackHandler& right) {
    if (this != &right) {
      mem_fun_ptr_ = right.mem_fun_ptr_;
      object_this_ = right.object_this_;
      async_callback_probe_ = right.async_callback_probe_;
      async_url_ = right.async_url_;
      callback_id_ = right.callback_id_;
    }
    return *this;
  }

  void operator()(A a) {
    if (std::shared_ptr<AsyncCallBackProbe> probe =
            async_callback_probe_.lock()) {
      (object_this_->*mem_fun_ptr_)(a, async_url_, callback_id_);
    }
  }

  void operator()(A a) const {
    if (std::shared_ptr<AsyncCallBackProbe> probe =
            async_callback_probe_.lock()) {
      (object_this_->*mem_fun_ptr_)(a, async_url_, callback_id_);
    }
  }

 private:
  MemFunPtr mem_fun_ptr_;
  T* object_this_;
  std::weak_ptr<AsyncCallBackProbe> async_callback_probe_;
  std::string async_url_;
  int32_t callback_id_ = -1;
};

struct LYNX_EXPORT LynxRect {
  float x;
  float y;
  float width;
  float height;
};

struct LYNX_EXPORT LynxSize {
  long cx;
  long cy;
};

struct LYNX_EXPORT LynxViewBaseBuilder {
  LynxViewBaseBuilder();
  ~LynxViewBaseBuilder();

  LynxViewBaseBuilder& operator=(const LynxViewBaseBuilder& other) noexcept {
    if (this == &other) {
      return *this;
    }
    group = other.group ? std::make_unique<LynxGroup>(*other.group) : nullptr;
    // config = std::make_unique<LynxConfig>(*other.config);
    screenSize = other.screenSize;
    rect = other.rect;
    fontScale = other.fontScale;
    threadStrategy = other.threadStrategy;
    enableLayoutSafepoint = other.enableLayoutSafepoint;
    enableAutoExpose = other.enableAutoExpose;
    enableTextNonContiguousLayout = other.enableTextNonContiguousLayout;
    external_js_provider_ = other.external_js_provider_;
    dynamic_component_provider_ = other.dynamic_component_provider_;
    return *this;
  }

  LynxViewBaseBuilder& operator=(LynxViewBaseBuilder&& other) noexcept {
    if (this == &other) {
      return *this;
    }
    group = std::move(other.group);
    config = std::move(other.config);
    screenSize = other.screenSize;
    rect = other.rect;
    fontScale = other.fontScale;
    threadStrategy = other.threadStrategy;
    enableLayoutSafepoint = other.enableLayoutSafepoint;
    enableAutoExpose = other.enableAutoExpose;
    enableTextNonContiguousLayout = other.enableTextNonContiguousLayout;
    external_js_provider_ = other.external_js_provider_;
    dynamic_component_provider_ = other.dynamic_component_provider_;
    return *this;
  }

  std::unique_ptr<LynxGroup> group;
  std::unique_ptr<LynxConfig> config;
  LynxSize screenSize{};
  LynxRect rect;
  float fontScale = 1.0f;
  LynxThreadStrategyForRender threadStrategy =
      LynxThreadStrategyForRenderAllOnUI;
  bool enableLayoutSafepoint = false;
  bool enableAutoExpose = true;
  bool enableTextNonContiguousLayout = false;
  constexpr static std::size_t kMaxPath = 260;
  lynx::LynxResourceProvider* external_js_provider_ = nullptr;
  lynx::LynxResourceProvider* dynamic_component_provider_ = nullptr;

  /**
   * Control whether updateData can take effect before loadTemplate
   */
  bool enablePreUpdateData = false;
};

using LynxViewBaseBuilderCallback = std::function<void(LynxViewBaseBuilder*)>;
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_BUILDER_H_
