// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_HEADLESS_LYNX_VIEW_H_
#define LYNX_HEADLESS_HEADLESS_LYNX_VIEW_H_

#include <fstream>
#include <memory>
#include <string>
#include <thread>

#include "base/blocking_queue.h"
#include "headless/headless_platform_impl.h"
#include "jsbridge/headless/module_manager_headless.h"
#include "shell/headless/native_facade_headless.h"
#include "shell/lynx_shell.h"
#include "shell/module_delegate_impl.h"
#include "shell/testing/mock_tasm_delegate.h"
#include "tasm/radon/radon_base.h"
#include "tasm/react/element.h"
#include "tasm/react/element_container.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {
namespace headless {

// This exists to allow us to double-free HeadlessLynxView
class HeadlessLynxViewImpl {
 public:
  HeadlessLynxViewImpl();
  ~HeadlessLynxViewImpl();

 private:
  shell::NativeFacadeHeadless* facade_;          // NOT OWNED
  tasm::ElementManager* element_manager_;        // NOT OWNED
  headless::PaintingContext* painting_context_;  // NOT OWNED
  runtime::LynxRuntime* runtime_;                // NOT OWNED
  base::TaskRunnerManufactor* runners_;          // NOT OWNED
  shell::LynxEngine* engine_;                    // NOT OWNED
  std::unique_ptr<shell::LynxShell> shell_;
  std::shared_ptr<tasm::TemplateAssembler> tasm_;
  std::shared_ptr<ModuleManagerHeadless> module_manager_;
  std::shared_ptr<fml::AutoResetWaitableEvent> arwe_;

  friend class HeadlessLynxView;
  friend class SelectElementResult;
  friend class EventChannel;
};

class HeadlessLynxView : public Napi::ObjectWrap<HeadlessLynxView> {
 public:
  explicit HeadlessLynxView(const Napi::CallbackInfo& info);
  ~HeadlessLynxView() override;

  static Napi::Function GetConstructor(Napi::Env env);
  static Napi::Object Init(Napi::Env env, Napi::Object exports);

  Napi::Value UpdateDataByParsedData(const Napi::CallbackInfo& info);
  Napi::Value ResetDataByParsedData(const Napi::CallbackInfo& info);
  Napi::Value UpdateGlobalProps(const Napi::CallbackInfo& info);
  Napi::Value SendGlobalEvent(const Napi::CallbackInfo& info);
  Napi::Value RegisterNativeModule(const Napi::CallbackInfo& info);
  Napi::Value LoadTemplate(const Napi::CallbackInfo& info);
  Napi::Value LoadTemplateWithoutInitData(const Napi::CallbackInfo& info);
  Napi::Value LoadTemplateWithInitData(const Napi::CallbackInfo& info);
  Napi::Value ReloadTemplate(const Napi::CallbackInfo& info);
  Napi::Value ReloadTemplateWithoutInitData();
  Napi::Value ReloadTemplateWithInitData(const Napi::CallbackInfo& info);
  Napi::Value CreateEventChannel(const Napi::CallbackInfo& info);
  Napi::Value SelectElement(const Napi::CallbackInfo& info);
  Napi::Value SelectListElement(const Napi::CallbackInfo& info);
  Napi::Value SelectComponent(const Napi::CallbackInfo& info);
  Napi::Value DumpTree(const Napi::CallbackInfo& info);
  Napi::Value DumpSnapshot(const Napi::CallbackInfo& info);
  Napi::Value DumpCoverageInJSRuntime(const Napi::CallbackInfo& info);
  Napi::Value DumpCoverageInLepusRuntime(const Napi::CallbackInfo& info);
  Napi::Value InvokeDataProcessor(const Napi::CallbackInfo& info);
  Napi::Value OnEnterForeground(const Napi::CallbackInfo& info);
  Napi::Value OnEnterBackground(const Napi::CallbackInfo& info);
  Napi::Value CallLepusMethod(const Napi::CallbackInfo& info);
  Napi::Value Destroy(const Napi::CallbackInfo& info);

 private:
  HeadlessLynxViewImpl* impl_;

  friend class SelectElementResult;
  friend class EventChannel;
};

}  // namespace headless
}  // namespace lynx

#undef Napi

#endif  // LYNX_HEADLESS_HEADLESS_LYNX_VIEW_H_
