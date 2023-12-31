// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_INSPECTOR_OWNER_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_INSPECTOR_OWNER_H_

#include <memory>
#include <string>

#include "shell/renderkit/devtool_wrapper/customized_message.h"
#include "shell/renderkit/lynx_page_reload_helper.h"
#include "shell/renderkit/public/lynx_view_base.h"

namespace lynx {
namespace devtool {

class MessageHandler;

class LYNX_EXPORT LynxBaseInspectorOwner {
 public:
  virtual ~LynxBaseInspectorOwner() = default;

  virtual void Init(
      LynxViewBase* view,
      const std::shared_ptr<LynxBaseInspectorOwner>& shared_self) = 0;
  virtual void SetReloadHelper(
      const std::shared_ptr<LynxPageReloadHelper>& reload_helper) = 0;
  virtual void SetSharedVM(const std::unique_ptr<LynxGroup>& group) = 0;
  virtual void OnTemplateAssemblerCreated(intptr_t ptr) = 0;
  virtual void StartCasting(int32_t quality, int32_t max_width,
                            int32_t max_height) = 0;
  virtual void StopCasting() = 0;
  virtual void ContinueCasting() = 0;
  virtual void PauseCasting() = 0;
  virtual void OnLoadFinished() = 0;
  virtual void ReloadLynxView(bool ignore_cache) = 0;
  virtual void NavigateLynxView(const std::string& url) = 0;
  // TODO(yanghuiwen): add emulateTouch
  virtual void Call(const std::string& function, const std::string& params) = 0;
  virtual intptr_t GetLynxDevtoolFunction() = 0;
  virtual void DispatchConsoleMessage(const std::string& message, int32_t level,
                                      int64_t time_stamp) = 0;
  // TODO(yanghuiwen): implement attachLynxView after async render supported
  virtual void AttachLynxView(LynxViewBase* lynx_view) = 0;
  virtual intptr_t CreateInspectorRuntimeManager() = 0;
  virtual intptr_t GetJavascriptDebugger() = 0;

  // methods in LynxBaseInspectorOwnerNG
  virtual void SendDevtoolMessage(CustomizedMessage& message) = 0;
  virtual void SubscribeMessage(
      const std::string& type,
      const std::shared_ptr<MessageHandler>& handler) = 0;
  virtual void UnsubscribeMessage(const std::string& type) = 0;

  virtual int32_t GetSessionId() = 0;
  virtual bool IsDebugging() = 0;
  virtual void DestroyDebugger() = 0;

 protected:
  LynxBaseInspectorOwner() = default;
};

class MessageHandler {
 public:
  virtual void OnMessage(const std::string& message) = 0;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_INSPECTOR_OWNER_H_
