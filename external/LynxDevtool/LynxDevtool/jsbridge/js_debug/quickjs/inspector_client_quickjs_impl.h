// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_QUICKJS_INSPECTOR_CLIENT_QUICKJS_IMPL_H
#define LYNX_INSPECTOR_JS_DEBUG_QUICKJS_INSPECTOR_CLIENT_QUICKJS_IMPL_H

#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>

#include "jsbridge/js_debug/quickjs_base/inspector_client_quickjs_base.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace piper {
class QuickjsContextWrapper;
}

namespace devtool {
class ScriptManager;

class QJSChannelImpl : public lepus_inspector::QJSInspector::QJSChannel,
                       public Channel {
 public:
  explicit QJSChannelImpl(lepus_inspector::QJSInspector *inspector, int view_id,
                          const std::string &group_id);

  void sendResponse(int call_id, const std::string &message) override;
  void sendNotification(const std::string &message) override;

  void flushProtocolNotifications() override {}

 private:
  int view_id_;
  std::string group_id_;
};

struct QJSDebugBundle {
  int view_id_ = -1;
  int runtime_id_ = -1;
  std::string group_id_ = "-1";
  bool single_group_ = true;
  bool view_destroyed_ = false;
  std::weak_ptr<InspectorJavaScriptDebugger> js_debugger_;
  std::unique_ptr<ScriptManager> script_manager_;
  std::shared_ptr<Channel> channel_;
  std::weak_ptr<piper::QuickjsContextWrapper> context_;
};

class InspectorClientQuickJSImpl : public InspectorClientQuickJSBase {
 public:
  InspectorClientQuickJSImpl(ClientType type);

  virtual ~InspectorClientQuickJSImpl();

  void InsertJSDebugger(
      const std::shared_ptr<InspectorJavaScriptDebugger> &debugger, int view_id,
      const std::string &group_id) override;
  void RemoveJSDebugger(int view_id) override;
  void SetViewDestroyed(bool destroyed, int view_id) override;

  void SetJSRuntime(const std::shared_ptr<piper::Runtime> &runtime,
                    int view_id) override;

  void ConnectFrontend(int view_id) override;
  void DisconnectFrontend(int view_id) override;
  void DisconnectFrontendOfSharedJSContext(
      const std::string &group_str) override;
  void DispatchMessageFromFrontend(const std::string &message,
                                   int view_id) override;
  void SendResponse(const std::string &message, int view_id) override;

  void runMessageLoopOnPause(const std::string &context_group_id) override;

 private:
  void SetQuickjsContext(
      int view_id,
      const std::shared_ptr<piper::QuickjsContextWrapper> &context);
  void CreateQuickjsDebugger(
      const std::shared_ptr<piper::QuickjsContextWrapper> &context);
  void RegisterSharedContextReleaseCallback(int view_id);

  void CreateInspector(int view_id,
                       lynx::piper::QuickjsContextWrapper *context);
  const std::unique_ptr<lepus_inspector::QJSInspector> &GetInspectorByGroupId(
      const std::string &group_id);
  void RemoveInspector(int view_id, bool shared_context_release = false);

  const std::weak_ptr<InspectorJavaScriptDebugger> &GetJSDebuggerByViewId(
      int view_id);
  void AddScriptManager(int view_id);
  const std::unique_ptr<ScriptManager> &GetScriptManagerByViewId(
      int view_id) override;
  void RemoveChannel(int view_id);
  const std::shared_ptr<Channel> &GetChannelByViewId(int view_id) override;

  void RemoveScript(int view_id);
  void RemoveConsoleMessage(int view_id);

  std::string MapGroupId(const std::string &group_id);
  void InsertViewIdToGroup(int view_id, const std::string &group_id);
  void RemoveViewIdFromGroup(int view_id);
  const std::set<int> &GetViewIdInGroup(const std::string &group_id);
  bool IsViewEnabled(int view_id);
  bool IsViewDestroyed(int view_id);

  void InsertRuntimeId(int runtime_id, int view_id);
  void RemoveRuntimeId(int view_id);
  int GetViewIdByRuntimeId(int runtime_id);

  std::vector<std::string> GetMessagePosterToChrome(const std::string &message,
                                                    int view_id);
  std::vector<std::pair<int, std::string>> GetMessagePostedToJSEngine(
      rapidjson::Value &message, int view_id);
  void SendMessageContextDestroyed(int view_id, int context_id);

  bool HandleMessageDebuggerEnableFromFrontend(
      int view_id, const std::string &mes,
      std::vector<std::pair<int, std::string>> &mes_vec);
  bool HandleMessageDebuggerDisableFromFrontend(
      int view_id, std::vector<std::pair<int, std::string>> &mes_vec);
  void HandleMessageRuntimeEnableFromFrontend(int view_id);

  void CreateWorkerTarget(int view_id);
  void DestroyWorkerTarget(int view_id);
  void AddWorkerSessionId(rapidjson::Document &message);
  void RemoveWorkerSessionId(rapidjson::Value &message);

  void RunOnJSThread(int view_id, base::closure closure);

  std::queue<int> destroyed_context_queue_;
  std::mutex destroyed_context_queue_mutex_;

  std::map<int, QJSDebugBundle> view_id_to_bundle_;
  std::map<std::string, std::unique_ptr<lepus_inspector::QJSInspector>>
      group_to_qjs_inspector_;
  std::map<std::string, std::set<int>> group_id_to_view_id_;
  std::map<int, int> runtime_id_to_view_id_;

  int need_disable_view_id_ = -2;
  bool profile_start_ = false;

  std::string worker_target_id_;
  std::string worker_session_id_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_QUICKJS_INSPECTOR_CLIENT_QUICKJS_IMPL_H
