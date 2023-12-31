// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DEVTOOL_AGENT_BASE_H_
#define LYNX_INSPECTOR_DEVTOOL_AGENT_BASE_H_

#include <memory>

#include "base/closure.h"
#include "base/mouse_event.h"
#include "base/perf_collector.h"
#include "base/screen_metadata.h"
#include "inspector/style_sheet.h"
#include "jsbridge/bindings/console_message_postman.h"
#include "lepus/value.h"
#include "third_party/jsoncpp/include/json/json.h"

#if LYNX_ENABLE_TRACING
#include "base/trace_event/trace_controller.h"
#endif

namespace lynxdev {
namespace devtool {

// refer to chromium
constexpr int kLynxInspectorErrorCode = -32601;

class DevToolAgentBase : public std::enable_shared_from_this<DevToolAgentBase> {
 public:
  void DispatchMessage(const std::string& msg) {
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(msg, root, false)) {
      return;
    }
    DispatchJsonMessage(root);
  }

  virtual intptr_t GetLynxDevtoolFunction() { return 0; }

  virtual void DispatchJsonMessage(const Json::Value& msg) = 0;
  virtual void DispatchConsoleMessage(
      const lynx::piper::ConsoleMessage& message) = 0;
  virtual void Call(const std::string& function, const std::string& params) = 0;

  virtual void SendResponse(const std::string& data) = 0;
  virtual void SendJsonResponse(const Json::Value& data) = 0;
  virtual void SendResponseAsync(const Json::Value& data) = 0;
  virtual void SendResponseAsync(lynx::base::closure closure) = 0;
  virtual void PageReload(bool ignore_cache, std::string template_binary = "",
                          bool from_template_fragments = false,
                          int32_t template_size = 0) = 0;
  virtual void OnReceiveTemplateFragment(const std::string& data, bool eof) = 0;

  virtual void Navigate(const std::string& url) = 0;
#if LYNX_ENABLE_TRACING
  virtual lynx::base::tracing::TraceController* GetTraceController() = 0;
  virtual lynx::base::tracing::TracePlugin* GetFPSTracePlugin() = 0;
  virtual lynx::base::tracing::TracePlugin* GetFrameViewTracePlugin() = 0;
  virtual lynx::base::tracing::TracePlugin* GetInstanceTracePlugin() = 0;
#endif
  virtual lynx::base::PerfCollector::PerfMap* GetFirstPerfContainer() = 0;
  virtual void SetLynxEnv(const std::string& key, bool value) = 0;
  virtual void StartScreenCast(ScreenRequest request) = 0;
  virtual void StopScreenCast() = 0;
  virtual void RecordEnable(bool value) = 0;
  virtual void EmulateTouch(std::shared_ptr<lynxdev::devtool::MouseEvent>) = 0;
  virtual void DispatchMessageToJSEngine(const std::string& msg) = 0;
  virtual std::string GetSystemModelName() = 0;

  virtual void RunOnAgentThread(lynx::base::closure closure) = 0;

  virtual lynx::lepus::Value* GetLepusValueFromTemplateData() = 0;
  virtual std::string GetTemplateConfigInfo() = 0;
  virtual lynx::lepus::Value* GetTemplateApiDefaultProcessor() = 0;
  virtual std::unordered_map<std::string, lynx::lepus::Value>*
  GetTemplateApiProcessorMap() = 0;
  virtual std::string GetAppMemoryInfo() = 0;
  virtual std::string GetAllTimingInfo() = 0;
  virtual std::string GetLynxVersion() = 0;
  virtual void StartMemoryTracing() = 0;
  virtual void StopMemoryTracing() = 0;
  virtual void StartMemoryDump() = 0;

  virtual void ResponseError(int id, const std::string& error) = 0;
  virtual void ResponseOK(int id) = 0;
  virtual void ResetTreeRoot() = 0;

  virtual void EnableTraceMode(bool enable_trace_mode) = 0;

  virtual int FindUIIdForLocation(float x, float y, int uiSign) = 0;
  virtual std::string GetUINodeInfo(int id) = 0;
  virtual std::string GetLynxUITree() = 0;
  virtual int SetUIStyle(int id, std::string name, std::string content) = 0;

  virtual void SendOneshotScreenshot() = 0;

#if OS_OSX || OS_WIN
  virtual double GetScreenScaleFactor() = 0;
#endif
};

}  // namespace devtool
}  // namespace lynxdev

#endif
