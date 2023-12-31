// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#include "canvas/canvas_element.h"

namespace lynx {
namespace canvas {

namespace {
class CanvasElementAppShowObserver : public AppShowStatusObserver {
 public:
  explicit CanvasElementAppShowObserver(
      std::weak_ptr<InstanceGuard<CanvasElement>> instance_weak_guard)
      : canvas_element_guard_weak_(std::move(instance_weak_guard)) {}

  void OnAppEnterForeground() override {
    auto instance_guard = canvas_element_guard_weak_.lock();
    if (instance_guard) {
      auto *canvas_element = instance_guard->Get();
      auto resource_provider = canvas_element->ResourceProvider();
      if (resource_provider) {
        resource_provider->OnAppEnterForeground();
      }
    }
  }

  void OnAppEnterBackground() override {
    auto instance_guard = canvas_element_guard_weak_.lock();
    if (instance_guard) {
      auto *canvas_element = instance_guard->Get();
      auto resource_provider = canvas_element->ResourceProvider();
      if (resource_provider) {
        resource_provider->OnAppEnterBackground();
      }
    }
  }

 private:
  std::weak_ptr<InstanceGuard<CanvasElement>> canvas_element_guard_weak_;
};

}  // namespace

const static std::string kTouchStart = "touchstart";
const static std::string kTouchEnd = "touchend";
const static std::string kTouchMove = "touchmove";
const static std::string kTouchCancel = "touchcancel";

void CanvasElement::ListenAppShowStatus() {
  DCHECK(canvas_app_);
  std::weak_ptr<InstanceGuard<CanvasElement>> element_gard_weak =
      GetInstanceGuard();
  if (!app_show_status_observer_) {
    app_show_status_observer_ =
        std::make_shared<CanvasElementAppShowObserver>(element_gard_weak);
  }
  canvas_app_->RegisterAppShowStatusObserver(app_show_status_observer_);
}

void CanvasElement::ListenPlatformViewEvents() {
  if (!canvas_id_.empty()) {
    DCHECK(canvas_app_);
    // TODO(dupengcheng): remove weak, no need for here.
    std::weak_ptr<InstanceGuard<CanvasElement>> element_gard_weak =
        GetInstanceGuard();
    float system_ratio = canvas_app_->GetDevicePixelRatio();
    auto set_need_draw = [weak = element_gard_weak]() {
      if (auto guard_share = weak.lock()) {
        auto *canvas_element = guard_share->Get();
        auto resource_provider = canvas_element->ResourceProvider();
        if (resource_provider) {
          resource_provider->SetNeedRedraw();
        }
      }
    };
    event_listener_ =
        std::make_shared<PlatformViewEventListener>(PlatformViewEventListener{
            .platform_view_name = GetCanvasId(), .unique_key = UniqueId()});
    event_listener_->callbacks = {
        .surface_created_callback = [handle = set_need_draw](
                                        uintptr_t surface_key,
                                        const std::string &name, int32_t width,
                                        int32_t height) { handle(); },
        .surface_changed_callback = [handle = set_need_draw](
                                        uintptr_t surface_key, int32_t width,
                                        int32_t height) { handle(); },
        .view_size_changed_callback =
            [weak = element_gard_weak, ratio = system_ratio](
                int32_t old_width, int32_t old_height, int32_t new_width,
                int32_t new_height) {
              if (auto guard_share = weak.lock()) {
                auto *canvas_element = guard_share->Get();
                size_t surface_width =
                    static_cast<size_t>(new_width * ratio + 0.5);
                size_t surface_height =
                    static_cast<size_t>(new_height * ratio + 0.5);
                canvas_element->TriggerResizeEvent(surface_width,
                                                   surface_height);
              }
            },
        .touch_callback =
            [weak = element_gard_weak](std::shared_ptr<DataHolder> event) {
              if (auto guard_share = weak.lock()) {
                auto *canvas_element = guard_share->Get();
                canvas_element->TriggerTouchEvent(event);
              }
            },
        .view_need_redraw_callback = [handle = set_need_draw]() { handle(); },
    };

    canvas_app_->platform_view_observer()->RegisterEventListener(
        event_listener_);
  }
}

void CanvasElement::CancelListenPlatformViewEvents() {
  if (!canvas_id_.empty()) {
    DCHECK(canvas_app_);
    canvas_app_->platform_view_observer()->DeregisterEventListener(
        event_listener_);
  }
}

void CanvasElement::TriggerTouchEvent(std::shared_ptr<DataHolder> event) {
  Napi::ContextScope cscope(Env());
  Napi::HandleScope hscope(Env());
  // return if CanvasElement is released by GC
  if (JsObject().IsEmpty()) {
    return;
  }
#ifdef OS_IOS
  // In case GC is triggered synchronously before calling into JSC.
  auto ref = ObtainStrongRef();
#endif
  const auto *touchEvent = static_cast<const CanvasTouchEvent *>(event->Data());

  auto type = GetTouchEventType(touchEvent->action);
  if (GetEventListenerStatus(type)) {
    auto data = GenTouchEvent(type, event);
    TriggerEventInternal(type, data);
  }
}

void CanvasElement::TriggerResizeEvent(size_t width, size_t height) {
  KRYPTON_LOGI("CanvasElement trigger resize event ") << this;
  Napi::ContextScope cscope(Env());
  Napi::HandleScope hscope(Env());
  // return if CanvasElement is released by GC
  if (JsObject().IsEmpty()) {
    return;
  }
#ifdef OS_IOS
  // In case GC is triggered synchronously before calling into JSC.
  KRYPTON_LOGI("Obtain CanvasElement js object strong ref ") << this;
  auto ref = ObtainStrongRef();
#endif
  auto event = Napi::Object::New(Env());
  event["width"] = width;
  event["height"] = height;
  TriggerEventInternal("resize", event);
}

// touch event return three types touchList：
// touches，targettouches，changedtouches touches is same as targetTouches
// changedTouches list: if action type is touchMove，return all touch items。
// if action is touchstart or touchcancel, return the current activated one.
// touches and targetTouches list: if action is move or start，return all touch
// items，if action is cancel or end, the returned list should delete the
// current activated one.
Napi::Object CanvasElement::GenTouchEvent(const std::string &type,
                                          std::shared_ptr<DataHolder> event) {
  const auto *touchEvent = static_cast<const CanvasTouchEvent *>(event->Data());
  auto data = Napi::Object::New(Env());
  auto allTouches = Napi::Array::New(Env(), touchEvent->length);
  int flag = 0;
  Napi::Array touches = Napi::Array::New(Env());
  for (int i = 0; i < touchEvent->length; i++) {
    auto touchItem = GenTouchItem(type, touchEvent->touchList[i],
                                  touchEvent->canvas_x, touchEvent->canvas_y);
    allTouches.Set(i, touchItem);
    if (type == kTouchCancel || type == kTouchEnd) {
      if (i == touchEvent->index) continue;
    }
    touches.Set(flag, touchItem);
    flag++;
  }
  data["touches"] = touches;
  data["targetTouches"] = touches;
  if (type == kTouchMove) {
    // touchmove: return all touches
    data["changedTouches"] = allTouches;
  } else {
    // touchestart, touchcancel, touchEnd: return current activated touch item
    auto tmp = Napi::Array::New(Env(), 1);
    tmp.Set(static_cast<uint32_t>(0), allTouches.Get(touchEvent->index));
    data["changedTouches"] = tmp;
  }
  data["index"] = touchEvent->index;
  return data;
}

std::string CanvasElement::GetTouchEventType(CanvasTouchEvent::Action action) {
  switch (action) {
    case CanvasTouchEvent::TouchStart:
    case CanvasTouchEvent::PointerDown:
      return kTouchStart;
    case CanvasTouchEvent::TouchEnd:
    case CanvasTouchEvent::PointerUp:
      return kTouchEnd;
    case CanvasTouchEvent::TouchMove:
      return kTouchMove;
    case CanvasTouchEvent::TouchCancel:
      return kTouchCancel;
  }
}

Napi::Object CanvasElement::GenTouchItem(
    const std::string &type, const CanvasTouchEvent::TouchItem &event,
    int canvas_x, int canvas_y) {
  auto touch_item = Napi::Object::New(Env());
  touch_item["identifier"] = event.id;
  touch_item["type"] = type;
  float ratio = canvas_app_->GetDevicePixelRatio();

  // Align with helium
  // third_party/helium/scandium/js/lib/scandium.js:60
  touch_item["rawX"] = event.rawX * ratio;
  touch_item["rawY"] = event.rawY * ratio;
  touch_item["pageX"] = event.x;
  touch_item["pageY"] = event.y;
  touch_item["clientX"] = event.x;
  touch_item["clientY"] = event.y;
  touch_item["screenX"] = event.x;
  touch_item["screenY"] = event.y;
  return touch_item;
}

}  // namespace canvas
}  // namespace lynx
