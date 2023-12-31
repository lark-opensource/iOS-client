// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_LYNX_H_
#define LYNX_JSBRIDGE_BINDINGS_LYNX_H_

#include <memory>
#include <vector>

#include "jsbridge/bindings/js_app.h"
#include "jsbridge/jsi/jsi.h"
#ifndef OS_WIN
#include "tasm/fluency/fluency_tracer.h"
#endif
namespace lynx {
namespace piper {
class LynxProxy : public HostObject {
 public:
  LynxProxy(std::weak_ptr<Runtime> rt, std::weak_ptr<App> app)
      : rt_(rt),
        native_app_(app),
        animation_frame_handler_(
            std::make_unique<runtime::AnimationFrameTaskHandler>()){};
  ~LynxProxy() = default;

  virtual Value get(Runtime*, const PropNameID& name) override;
  virtual void set(Runtime*, const PropNameID& name,
                   const Value& value) override;
  virtual std::vector<PropNameID> getPropertyNames(Runtime& rt) override;

  piper::Value RequestAnimationFrame(piper::Function func);
  void CancelAnimationFrame(int64_t id);
  void DoFrame(int64_t time_stamp);

  void PauseAnimationFrame();
  void ResumeAnimationFrame();

  void Destroy();
  void SetPostDoFrameTaskWithFunction(piper::Function func);

 private:
  std::weak_ptr<Runtime> rt_;
  std::weak_ptr<App> native_app_;
  std::unique_ptr<runtime::AnimationFrameTaskHandler> animation_frame_handler_;
  bool has_paused_animation_frame_{false};
#ifndef OS_WIN
  lynx::tasm::FluencyTracer fluency_tracer_;
#endif
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_LYNX_H_
