#ifndef LYNX_JSBRIDGE_RUNTIME_TEMPLATE_DELEGATE_H_
#define LYNX_JSBRIDGE_RUNTIME_TEMPLATE_DELEGATE_H_
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/module_delegate.h"
#include "jsbridge/platform_value.h"
#include "jsbridge/runtime/update_data_type.h"
#include "lepus/lepus_global.h"
#include "shell/lynx_card_cache_data_op.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/react/prop_bundle.h"
#include "tasm/timing.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace runtime {

// just constructor and move
struct UpdateDataTask {
  UpdateDataTask(bool card, const std::string& component_id,
                 const lepus::Value& data, piper::ApiCallBack callback,
                 UpdateDataType type)
      : is_card_(card),
        component_id_(component_id),
        data_(data),
        callback_(callback),
        type_(std::move(type)) {}

  UpdateDataTask(const UpdateDataTask&) = delete;
  UpdateDataTask& operator=(const UpdateDataTask&) = delete;
  UpdateDataTask(UpdateDataTask&&) = default;
  UpdateDataTask& operator=(UpdateDataTask&&) = default;

  bool is_card_;
  std::string component_id_;
  lepus::Value data_;
  piper::ApiCallBack callback_;
  UpdateDataType type_;
};

class TemplateDelegate {
 public:
  TemplateDelegate() {}
  virtual ~TemplateDelegate() = default;

  virtual void UpdateDataByJS(UpdateDataTask task) = 0;
  virtual void UpdateBatchedDataByJS(std::vector<UpdateDataTask> tasks,
                                     uint64_t update_task_id) = 0;
  virtual std::vector<lynx::shell::CacheDataOp> FetchUpdatedCardData() = 0;
  virtual std::string GetJSSource(const std::string& entry_name,
                                  const std::string& name) = 0;
  virtual std::string GetLynxJSAsset(const std::string& name) = 0;

  virtual lepus::Value GetTasmEncodedData() = 0;
  virtual lepus::Value GetNativeInitData() = 0;
  virtual lepus::Value GetNativeCardConfigData() = 0;
  virtual bool GetEnableAttributeTimingFlag() const = 0;

  virtual lepus::Value GetInitGlobalProps() = 0;
  virtual void GetComponentContextDataAsync(const std::string& component_id,
                                            const std::string& key,
                                            piper::ApiCallBack callback) = 0;
  virtual bool LoadDynamicComponentFromJS(
      const std::string& url, const piper::ApiCallBack& callback) = 0;
  virtual void LoadScriptAsync(const std::string& url,
                               piper::ApiCallBack callback) = 0;

  virtual void OnRuntimeReady() = 0;
  virtual void OnErrorOccurred(int32_t error_code, const std::string& msg) = 0;
  virtual void OnModuleMethodInvoked(const std::string& module,
                                     const std::string& method,
                                     int32_t code) = 0;
  virtual void OnCoreJSUpdated(std::string core_js) = 0;

  // for component
  virtual void UpdateComponentData(UpdateDataTask task) = 0;
  virtual void SelectComponent(const std::string& component_id,
                               const std::string& id_selector,
                               const bool single,
                               piper::ApiCallBack callBack) = 0;

  // for SelectorQuery
  virtual void InvokeUIMethod(tasm::NodeSelectRoot root,
                              tasm::NodeSelectOptions options,
                              std::string method,
                              std::unique_ptr<piper::PlatformValue> params,
                              piper::ApiCallBack call_back) = 0;
  virtual void GetPathInfo(tasm::NodeSelectRoot root,
                           tasm::NodeSelectOptions options,
                           piper::ApiCallBack call_back) = 0;
  virtual void GetFields(tasm::NodeSelectRoot root,
                         tasm::NodeSelectOptions options,
                         std::vector<std::string> fields,
                         piper::ApiCallBack call_back) = 0;

  // for element.animate
  virtual void ElementAnimate(const std::string& component_id,
                              const std::string& id_selector,
                              const lepus::Value& args) = 0;
  virtual void TriggerComponentEvent(const std::string& event_name,
                                     const lepus::Value& msg) = 0;
  virtual void TriggerLepusGlobalEvent(const std::string& event_name,
                                       const lepus::Value& msg) = 0;
  virtual void TriggerWorkletFunction(std::string component_id,
                                      std::string worklet_module_name,
                                      std::string method_name,
                                      lepus::Value args,
                                      piper::ApiCallBack callback) = 0;
  virtual bool NeedGlobalConsole() = 0;
  virtual bool SupportComponentJS() = 0;
  virtual void RunOnJSThread(base::closure closure) = 0;
  virtual void SetTiming(tasm::Timing timing) = 0;
  // report all tracker events to native facade.
  virtual void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) = 0;
  virtual void FlushJSBTiming(piper::NativeModuleInfo timing) = 0;

  // for lepus event
  virtual void InvokeLepusComponentCallback(const int64_t callback_id,
                                            const std::string& entry_name,
                                            const lepus::Value& data) = 0;
  // for vsync
  virtual void AsyncRequestVSync(
      uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback,
      bool for_flush = false) = 0;

  virtual void SetCSSVariables(const std::string& component_id,
                               const std::string& id_selector,
                               const lepus::Value& properties) = 0;

  virtual void SetNativeProps(tasm::NodeSelectRoot root,
                              const tasm::NodeSelectOptions& options,
                              const lepus::Value& native_props) = 0;

  virtual void ReloadFromJS(UpdateDataTask task) = 0;

  virtual void AfterNotifyJSUpdatePageData(
      std::vector<base::closure> callbacks) = 0;

  // for ReactLynx
  virtual const std::string& GetTargetSDKVersion() = 0;

  // for Fiber
  virtual void CallLepusMethod(const std::string& method_name,
                               lepus::Value value,
                               const piper::ApiCallBack& callback,
                               uint64_t trace_flow_id) = 0;
};
}  // namespace runtime
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_RUNTIME_TEMPLATE_DELEGATE_H_
