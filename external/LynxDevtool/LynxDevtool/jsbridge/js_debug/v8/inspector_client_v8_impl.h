// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_CLIENT_V8_IMPL_H
#define LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_CLIENT_V8_IMPL_H

#include <jsbridge/jsi/jsi.h>

#include <condition_variable>
#include <map>
#include <mutex>
#include <queue>
#include <set>

#include "base/closure.h"
#include "base/log/logging.h"
#include "base/thread/timed_task.h"
#include "jsbridge/js_debug/inspector_client.h"
#include "third_party/rapidjson/document.h"
#include "v8-inspector.h"
#include "v8.h"

namespace lynx {
namespace runtime {
class LynxRuntime;
}  // namespace runtime

namespace devtool {
class InspectorClient;
class InspectorJavaScriptDebugger;
class ScriptManager;

class ChannelImpl : public v8_inspector::V8Inspector::Channel {
 public:
  explicit ChannelImpl(v8_inspector::V8Inspector* inspector, int view_id,
                       int group_id);

  void SetClient(const std::shared_ptr<InspectorClient>& sp);
  bool DispatchProtocolMessage(const std::string& message);
  void SchedulePauseOnNextStatement(const std::string& reason);
  void CancelPauseOnNextStatement();

  void sendResponse(
      int callId, std::unique_ptr<v8_inspector::StringBuffer> message) override;
  void sendNotification(
      std::unique_ptr<v8_inspector::StringBuffer> message) override;
  void flushProtocolNotifications() override {}

 private:
  std::unique_ptr<v8_inspector::V8InspectorSession> session_;
  std::weak_ptr<InspectorClient> client_wp_;

  int view_id_;
  int group_id_;
};

struct JsDebugBundle {
  int view_id_ = -1;
  int runtime_id_ = -1;
  int group_id_ = -1;
  bool single_group_ = true;
  bool enabled_ = false;
  bool view_destroyed_ = false;
  std::weak_ptr<InspectorJavaScriptDebugger> js_debugger_;
  std::unique_ptr<ScriptManager> script_manager_;
  std::shared_ptr<ChannelImpl> channel_;
  v8::Persistent<v8::Context, v8::CopyablePersistentTraits<v8::Context>>
      context_;
  std::set<int> script_id_;
};

class InspectorClientV8Impl : public InspectorClient,
                              v8_inspector::V8InspectorClient {
 public:
  InspectorClientV8Impl(ClientType type);
  ~InspectorClientV8Impl();

  void InsertJSDebugger(
      const std::shared_ptr<InspectorJavaScriptDebugger>& debugger, int view_id,
      const std::string& group_id) override;
  void RemoveJSDebugger(int view_id) override;
  void SetLepusDebugger(
      std::shared_ptr<InspectorLepusDebugger> debugger) override {}

  void SetJSRuntime(const std::shared_ptr<piper::Runtime>& runtime,
                    int view_id) override;
  void SetLepusContext(
      const std::shared_ptr<lepus::Context>& context) override {}
  void SetViewDestroyed(bool destroyed, int view_id) override;
  void ConnectFrontend(int view_id) override;
  void DisconnectFrontend(int view_id) override;
  void DisconnectFrontendOfSharedJSContext(
      const std::string& group_str) override;
  void SetBreakpointWhenReload(int view_id) override;
  void DispatchMessageStop(int view_id) override;
  void DispatchMessageFromFrontend(const std::string& message,
                                   int view_id) override;
  void DispatchMessageFromFrontendSync(const std::string& message,
                                       int view_id) override;
  void SendResponse(const std::string& message, int view_id) override;
  void SendMessageProfileEnabled(int view_id) override;

  void runMessageLoopOnPause(int context_group_id) override;
  void quitMessageLoopOnPause() override;

  v8::Local<v8::Context> ensureDefaultContextInGroup(
      int contextGroupId) override;

  double currentTimeMS() override;
  void startRepeatingTimer(double interval, TimerCallback callback,
                           void* data) override;
  void cancelTimer(void* data) override;

 private:
  void CreateV8Inspector(int view_id);
  void ContextCreated(int view_id, v8::Local<v8::Context> context);
  void ContextDestroyed(int view_id, bool shared_context_release = false);

  const std::weak_ptr<InspectorJavaScriptDebugger>& GetJSDebuggerByViewId(
      int view_id);
  void AddScriptManager(int view_id);
  const std::unique_ptr<ScriptManager>& GetScriptManagerByViewId(int view_id);
  const std::shared_ptr<ChannelImpl>& AddChannel(int view_id);
  void RemoveChannel(int view_id);
  const std::shared_ptr<ChannelImpl>& GetChannelByViewId(int view_id);

  bool IsViewInSingleGroup(int view_id);
  bool IsViewDestroyed(int view_id);
  bool IsScriptViewDestroyed(const std::string& script_url);
  int GetScriptViewId(const std::string& script_url);

  void InsertScriptId(int view_id, int script_id);
  void RemoveScriptId(int view_id);
  const std::set<int>& GetScriptId(int view_id);
  void InsertInvalidScriptId(int view_id);
  bool GetScriptIdInvalid(int script_id);

  int MapGroupStrToNum(int view_id, const std::string& group_string);
  const std::string& MapGroupNumToStr(int group_id);
  void RemoveGroup(int group_id);
  void InsertViewId(int group_id, int view_id);
  void RemoveViewIdFromGroup(int group_id, int view_id);
  const std::set<int>& GetViewIdInGroup(int group_id);
  int GetViewCountOfGroup(int group_id);
  int GetViewIdOfDefaultGroupId(int group_id);
  void SetContextCreated(int group_id);
  void RemoveContextCreated(int group_id);
  bool GetContextCreated(int group_id);

  std::vector<std::string> GetMessagePosterToChrome(const std::string& message,
                                                    int view_id);
  std::vector<std::pair<int, std::string>> GetMessagePostedToJSEngine(
      const rapidjson::Value& message, int view_id);
  void SendMessageContextDestroyed(int view_id, int context_id);
  void SendMessageRemoveScripts(int remove_view_id);

  void CreateWorkerTarget(int view_id);
  void DestroyWorkerTarget(int view_id);
  void AddWorkerSessionId(rapidjson::Document& message);
  void RemoveWorkerSessionId(rapidjson::Value& message);

  void HandleMessageDebuggerActive(int view_id,
                                   const rapidjson::Value& message);
  bool HandleMessageDebuggerEnableFromFrontend(
      int view_id, const std::string& mes,
      std::vector<std::pair<int, std::string>>& mes_vec);
  bool HandleMessageDebuggerDisableFromFrontend(
      int view_id, const std::string& mes,
      std::vector<std::pair<int, std::string>>& mes_vec);
  void HandleMessageRuntimeEnableFromFrontend(int view_id);
  bool HandleMessageConsoleAPICalled(rapidjson::Document& message);
  void RemoveInvalidProperty(rapidjson::Value& message);
  void SetViewEnabled(const std::string& mes, int view_id);
  bool IsViewEnabled(int view_id);

  void InsertRuntimeId(int runtime_id, int view_id);
  void RemoveRuntimeId(int view_id);
  int GetViewIdByRuntimeId(int runtime_id);

  void Pause();
  void QuitPause();

  void FlushMessageQueue();
  void RunOnJSThread(int view_id, base::closure closure);

  void SetStopAtEntry(bool stop_at_entry, int view_id) override;

  v8::Isolate* isolate_;
  bool running_nested_loop_ = false;
  bool waiting_for_message_ = false;
  std::queue<std::pair<int, std::string>> message_queue_;
  std::queue<int> destroyed_context_id_;

  std::mutex mutex_;
  std::mutex message_queue_mutex_;
  std::mutex destroyed_context_queue_mutex_;
  std::condition_variable cv_;

  std::unique_ptr<v8_inspector::V8Inspector> inspector_;
  std::map<int, JsDebugBundle> view_id_to_bundle_;
  std::map<int, int> runtime_id_to_view_id_;

  std::map<std::string, int> group_string_to_number_;
  std::map<int, std::string> group_number_to_string_;
  std::map<int, std::set<int>> group_id_to_view_id_;
  std::set<int> group_context_created_;
  std::set<int> invalid_script_id_;

  int disable_view_id_ = -2;
  bool profile_start_ = false;

  std::string worker_target_id_;
  std::string worker_session_id_;

  std::unique_ptr<base::TimedTaskManager> timer_;
  std::unordered_map<void*, uint32_t> timed_task_ids_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_CLIENT_V8_IMPL_H
