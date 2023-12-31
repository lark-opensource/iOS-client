// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_CLIENT_LEPUS_IMPL_H
#define LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_CLIENT_LEPUS_IMPL_H

#include <map>
#include <memory>
#include <string>

#include "jsbridge/js_debug/quickjs_base/inspector_client_quickjs_base.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {
class QuickjsContextWrapper;
}

namespace devtool {
class ScriptManager;

class LepusChannelImpl : public lepus_inspector::LepusInspector::LepusChannel,
                         public Channel {
 public:
  explicit LepusChannelImpl(lepus_inspector::LepusInspector *inspector);

  void sendResponse(int call_id, const std::string &message) override;
  void sendNotification(const std::string &message) override;

  void flushProtocolNotifications() override {}
};

class InspectorClientLepusImpl : public InspectorClientQuickJSBase {
 public:
  InspectorClientLepusImpl(ClientType type);

  virtual ~InspectorClientLepusImpl();

  void SetLepusDebugger(
      std::shared_ptr<InspectorLepusDebugger> debugger) override;
  void SetLepusContext(const std::shared_ptr<lepus::Context> &context) override;

  void ConnectFrontend(int view_id = -1) override;
  void DisconnectFrontend(int view_id) override;
  void DisconnectFrontendOfSharedJSContext(
      const std::string &group_str) override {}

  void DispatchMessageFromFrontend(const std::string &message,
                                   int view_id = -1) override;

  void SendResponse(const std::string &message, int view_id) override;

  void runMessageLoopOnPause(const std::string &context_group_id) override;
  std::queue<std::string> getMessageFromFrontend() override;

 private:
  const std::unique_ptr<ScriptManager> &GetScriptManagerByViewId(
      int view_id) override;
  const std::shared_ptr<Channel> &GetChannelByViewId(int view_id) override;

  std::vector<std::string> GetMessagePosterToChrome(const std::string &message);
  std::vector<std::string> GetMessagePostedToJSEngine(
      rapidjson::Value &message);

  void GetMessageWithoutSessionId(rapidjson::Value &message);

  std::string target_id_;
  std::string session_id_;
  std::string engine_type_;

  std::weak_ptr<lepus::Context> context_;
  std::weak_ptr<InspectorLepusDebugger> lepus_debugger_;
  std::unique_ptr<lepus_inspector::LepusInspector> inspector_;
  std::shared_ptr<Channel> channel_;
  std::unique_ptr<ScriptManager> script_manager_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_CLIENT_LEPUS_IMPL_H
