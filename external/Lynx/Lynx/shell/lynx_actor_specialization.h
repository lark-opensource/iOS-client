// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_ACTOR_SPECIALIZATION_H_
#define LYNX_SHELL_LYNX_ACTOR_SPECIALIZATION_H_

#include <string>
#include <utility>

#include "base/trace_event/trace_event.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "shell/lynx_actor.h"
#include "shell/lynx_engine.h"
#include "shell/native_facade.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/layout_context.h"

namespace lynx {
namespace shell {

template <typename T>
inline constexpr bool kIsLynxActor = std::is_same_v<T, runtime::LynxRuntime> ||
                                     std::is_same_v<T, shell::LynxEngine> ||
                                     std::is_same_v<T, shell::NativeFacade> ||
                                     std::is_same_v<T, tasm::LayoutContext>;

template <typename T>
inline constexpr const char* kActorTag = "";

template <>
inline constexpr const char* kActorTag<shell::NativeFacade> = "NativeFacade";

template <>
inline constexpr const char* kActorTag<shell::LynxEngine> = "LynxEngine";

template <>
inline constexpr const char* kActorTag<runtime::LynxRuntime> = "LynxRuntime";

template <>
inline constexpr const char* kActorTag<tasm::LayoutContext> = "LayoutContext";

template <typename C, typename T>
class LynxActorMixin<C, T, typename std::enable_if_t<kIsLynxActor<T>>> {
 public:
  void BeforeInvoked() {
    TRACE_EVENT_BEGIN(
        LYNX_TRACE_CATEGORY, nullptr, [&](lynx::perfetto::EventContext ctx) {
          ctx.event()->set_name(std::string(kTag).append("::Invoke"));
        });
  }

  void AfterInvoked() {
    {
      TRACE_EVENT(
          LYNX_TRACE_CATEGORY, nullptr, [&](lynx::perfetto::EventContext ctx) {
            ctx.event()->set_name(std::string(kTag).append("::AfterInvoked"));
          });
      auto* impl = static_cast<std::add_pointer_t<C>>(this)->Impl();
      if (impl != nullptr) {
        ConsumeImplIfNeeded(impl);
        auto stack = tasm::EventReportTracker::PopAll();
        if (!stack.empty()) {
          impl->Report(std::move(stack));
        }
      }
    }

    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  }

  void ConsumeImplIfNeeded(T* impl) {}

 private:
  static inline constexpr const char* kTag = kActorTag<T>;
};

template <>
inline void LynxActorMixin<LynxActor<LynxEngine>,
                           LynxEngine>::ConsumeImplIfNeeded(LynxEngine* impl) {
  impl->Flush();
}

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_ACTOR_SPECIALIZATION_H_
