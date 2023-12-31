// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_CLIENT_H
#define LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_CLIENT_H

#include <memory>
#include <queue>

#include "base/closure.h"
#include "base/log/logging.h"
#include "jsbridge/java_script_debugger.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace lepus {
class Context;
}  // namespace lepus

namespace piper {
class Runtime;
}  // namespace piper

namespace devtool {
class InspectorJavaScriptDebugger;
class InspectorLepusDebugger;
class InspectorJsEnvProvider;
class InspectorClient;

enum ClientType { JsClient = 0, LepusClient, JsWorkerClient };

class InspectorClientProvider {
 public:
  static std::shared_ptr<InspectorClient> CreateInspectorClient(
      DebugType debug_type, ClientType client_type, bool shared_vm);
};

class InspectorClient : public std::enable_shared_from_this<InspectorClient> {
 public:
  static std::shared_ptr<InspectorClient> CreateInspectorClient(
      DebugType debug_type, ClientType client_type);
  static void CreateJsEnvProvider(DebugType type);
  static void CreateLepusEnvProvider();
  static void SetJsEnvProvider(InspectorJsEnvProvider* c);
  static InspectorJsEnvProvider* GetJsEnvProvider(DebugType type);
  static InspectorJsEnvProvider* GetLepusEnvProvider();

  explicit InspectorClient(ClientType type) : type_(type) {}
  virtual ~InspectorClient() {}

  virtual void InsertJSDebugger(
      const std::shared_ptr<InspectorJavaScriptDebugger>& debugger, int view_id,
      const std::string& group_id) = 0;
  virtual void RemoveJSDebugger(int view_id) = 0;
  virtual void SetLepusDebugger(
      std::shared_ptr<InspectorLepusDebugger> debugger) = 0;

  virtual void SetJSRuntime(const std::shared_ptr<piper::Runtime>& runtime,
                            int view_id) = 0;
  virtual void SetLepusContext(
      const std::shared_ptr<lepus::Context>& context) = 0;
  virtual void SetViewDestroyed(bool destroyed, int view_id) = 0;
  virtual void ConnectFrontend(int view_id) = 0;
  virtual void DisconnectFrontend(int view_id) = 0;
  virtual void DisconnectFrontendOfSharedJSContext(
      const std::string& group_str) = 0;
  virtual void SetBreakpointWhenReload(int view_id) = 0;
  virtual void DispatchMessageStop(int view_id) = 0;
  virtual void DispatchMessageFromFrontend(const std::string& message,
                                           int view_id) = 0;
  virtual void DispatchMessageFromFrontendSync(const std::string& message,
                                               int view_id) = 0;
  virtual void SendResponse(const std::string& message, int view_id) = 0;
  virtual void SendMessageProfileEnabled(int view_id) = 0;

  void DispatchMessageEnable(int view_id, bool runtime_enable);
  void DispatchDebuggerDisable(int view_id);

  virtual void SetStopAtEntry(bool stop_at_entry, int view_id) = 0;

 protected:
  std::string GetSimpleMessage(const std::string& method, int message_id = 0);
  std::string GetMessageSetBreakpointsActive(bool active, int message_id = 0);

  rapidjson::Document GetTargetInfo(const std::string& target_id,
                                    const std::string& title);
  std::string GetMessageTargetCreated(const std::string& target_id,
                                      const std::string& title);
  std::string GetMessageAttachedToTarget(const std::string& target_id,
                                         const std::string& session_id,
                                         const std::string& title);
  std::string GetMessageTargetDestroyed(const std::string& target_id);
  std::string GetMessageDetachFromTarget(const std::string& target_id,
                                         const std::string& session_id);

  bool ParseStrToJson(rapidjson::Document& json_mes, const std::string& mes);

  static InspectorJsEnvProvider* v8_provider_;
  static InspectorJsEnvProvider* qjs_provider_;
  static InspectorJsEnvProvider* lepus_provider_;

  ClientType type_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_CLIENT_H
