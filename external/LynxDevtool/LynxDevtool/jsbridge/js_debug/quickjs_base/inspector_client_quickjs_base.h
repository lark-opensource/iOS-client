// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_QUICKJS_BASE_INSPECTOR_CLIENT_QUICKJS_BASE_H
#define LYNX_INSPECTOR_JS_DEBUG_QUICKJS_BASE_INSPECTOR_CLIENT_QUICKJS_BASE_H

#include <condition_variable>
#include <memory>
#include <mutex>
#include <string>

#include "jsbridge/js_debug/inspector_client.h"
#include "lepus/lepus_inspector.h"

namespace lynx {

namespace devtool {
class ScriptManager;

class Channel {
 public:
  Channel(){};
  virtual ~Channel() = default;

  void SetClient(const std::shared_ptr<InspectorClient> &sp);
  void DispatchProtocolMessage(const std::string &message);
  void SchedulePauseOnNextStatement(const std::string &reason);
  void CancelPauseOnNextStatement();

  void SendResponseToClient(const std::string &message, int view_id);

 protected:
  std::unique_ptr<lepus_inspector::LepusInspectorSession> session_;
  std::weak_ptr<InspectorClient> client_wp_;
};

class InspectorClientQuickJSBase
    : public InspectorClient,
      public lepus_inspector::LepusInspectorClient {
 public:
  InspectorClientQuickJSBase(ClientType type);

  virtual ~InspectorClientQuickJSBase() = default;

  void InsertJSDebugger(
      const std::shared_ptr<InspectorJavaScriptDebugger> &debugger, int view_id,
      const std::string &group_id) override {}
  void RemoveJSDebugger(int view_id) override {}
  void SetLepusDebugger(
      std::shared_ptr<InspectorLepusDebugger> debugger) override {}
  void SetViewDestroyed(bool destroyed, int view_id) override {}
  void SendMessageProfileEnabled(int view_id) override {}

  void SetLepusContext(
      const std::shared_ptr<lepus::Context> &context) override {}
  void SetJSRuntime(const std::shared_ptr<piper::Runtime> &runtime,
                    int view_id) override {}

  void ConnectFrontend(int view_id) override = 0;
  void DisconnectFrontend(int view_id) override = 0;
  void DisconnectFrontendOfSharedJSContext(
      const std::string &group_str) override {}
  void SetBreakpointWhenReload(int view_id) override;
  void DispatchMessageStop(int view_id) override;
  void DispatchMessageFromFrontend(const std::string &message,
                                   int view_id) override = 0;
  void DispatchMessageFromFrontendSync(const std::string &message,
                                       int view_id) override;
  void SendResponse(const std::string &message, int view_id) override = 0;

  void runMessageLoopOnPause(const std::string &context_group_id) override = 0;
  void quitMessageLoopOnPause() override;

  std::queue<std::string> getMessageFromFrontend() override {
    return std::queue<std::string>();
  }

 protected:
  virtual const std::unique_ptr<ScriptManager> &GetScriptManagerByViewId(
      int view_id) = 0;
  virtual const std::shared_ptr<Channel> &GetChannelByViewId(int view_id) = 0;

  void Pause();
  void QuitPause();

  void FlushMessageQueue();

  void SetStopAtEntry(bool stop_at_entry, int view_id) override;

  bool running_nested_loop_ = false;
  bool waiting_for_message_ = false;
  std::queue<std::pair<int, std::string>> message_queue_;

  std::mutex mutex_;
  std::mutex message_queue_mutex_;
  std::condition_variable cv_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_QUICKJS_BASE_INSPECTOR_CLIENT_QUICKJS_BASE_H
