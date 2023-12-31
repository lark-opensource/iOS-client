// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_ENGINE_H_
#define LYNX_SHELL_LYNX_ENGINE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/no_destructor.h"
#include "config/config.h"
#include "jsbridge/runtime/template_delegate.h"
#include "jsbridge/runtime/update_data_type.h"
#include "shell/lynx_card_cache_data_manager.h"
#include "shell/tasm_operation_queue.h"
#include "tasm/page_config.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/react/list_node.h"
#include "tasm/react/prop_bundle.h"
#include "tasm/template_assembler.h"
#include "tasm/template_data.h"

namespace lynx {
namespace shell {

class LynxEngine {
 public:
  class Delegate : public tasm::ElementManager::Delegate,
                   public tasm::TemplateAssembler::Delegate {
   public:
    Delegate() = default;
    ~Delegate() override = default;

    virtual void Init() {}

    void NotifyJSUpdatePageData() { NotifyJSUpdatePageData(nullptr); }
    virtual void NotifyJSUpdatePageData(base::closure callback) = 0;

    virtual void Report(
        std::vector<std::unique_ptr<tasm::PropBundle>> stack) = 0;
  };

  explicit LynxEngine(
      const std::shared_ptr<tasm::TemplateAssembler>& tasm,
      std::unique_ptr<Delegate> delegate,
      const std::shared_ptr<LynxCardCacheDataManager>& card_cached_data_mgr)
      : tasm_(tasm),
        delegate_(std::move(delegate)),
        card_cached_data_mgr_(card_cached_data_mgr) {}
  ~LynxEngine();

  void Init();

  void LoadTemplate(const std::string& url, std::vector<uint8_t> source,
                    const std::shared_ptr<tasm::TemplateData>& template_data);

  void LoadTemplateBundle(
      const std::string& url, tasm::LynxTemplateBundle template_bundle,
      const std::shared_ptr<tasm::TemplateData>& template_data);

  void LoadSSRData(std::vector<uint8_t> source,
                   const std::shared_ptr<tasm::TemplateData>& template_data);

  void UpdateDataByParsedData(const std::shared_ptr<tasm::TemplateData>& data,
                              uint32_t native_update_data_order,
                              base::closure finished_callback = nullptr);

  void ResetDataByParsedData(const std::shared_ptr<tasm::TemplateData>& data,
                             uint32_t native_update_data_order);

  void ReloadTemplate(const std::shared_ptr<tasm::TemplateData>& data,
                      const lepus::Value& global_props,
                      uint32_t native_update_data_order);

  void UpdateConfig(const lepus::Value& config);

  void UpdateGlobalProps(const lepus::Value& global_props);

  void SetFontScale(float scale);

  void UpdateFontScale(float scale);

  void UpdateScreenMetrics(float width, float height, float scale);

  void UpdateViewport(float width, int32_t width_mode, float height,
                      int32_t height_mode, bool need_layout = true);

  void SyncFetchLayoutResult();

  void SendAirPageEvent(const std::string& name, const lepus_value& params);

  void SendCustomEvent(const std::string& name, int32_t tag,
                       const lepus::Value& params,
                       const std::string& params_name);

  void SendTouchEvent(const std::string& name, int32_t tag, float x, float y,
                      float client_x, float client_y, float page_x,
                      float page_y);

  void OnPseudoStatusChanged(int32_t id, int32_t pre_status,
                             int32_t current_status);

  void SendBubbleEvent(const std::string& name, int32_t tag,
                       lepus::DictionaryPtr dict);

  void SendInternalEvent(int32_t tag, int32_t event_id);

  void SendGlobalEventToLepus(const std::string& name,
                              const lepus_value& params);

  void TriggerEventBus(const std::string& name, const lepus_value& params);

  void LoadComponent(const std::string& url, std::vector<uint8_t> binary,
                     bool sync);

  void LoadComponentWithCallback(const std::string& url,
                                 std::vector<uint8_t> binary, bool sync,
                                 int32_t callback_id);

  std::unique_ptr<lepus_value> GetCurrentData();

  lepus::Value GetPageDataByKey(const std::vector<std::string>& keys);

  tasm::ListNode* GetListNode(int32_t tag);

  std::unordered_map<std::string, std::string> GetAllJsSource();

  void UpdateDataByJS(runtime::UpdateDataTask task);

  void UpdateBatchedDataByJS(std::vector<runtime::UpdateDataTask> tasks,
                             uint64_t update_task_id);

  void TriggerComponentEvent(const std::string& event_name,
                             const lepus::Value& msg);

  void TriggerLepusGlobalEvent(const std::string& event_name,
                               const lepus::Value& msg);
  void TriggerWorkletFunction(std::string component_id,
                              std::string worklet_module_name,
                              std::string method_name, lepus::Value args,
                              piper::ApiCallBack callback);

  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params);

  void InvokeLepusCallback(const int32_t callback_id,
                           const std::string& entry_name,
                           const lepus::Value& data);

  void InvokeLepusComponentCallback(const int64_t callback_id,
                                    const std::string& entry_name,
                                    const lepus::Value& data);

  void UpdateComponentData(runtime::UpdateDataTask task);

  void SelectComponent(const std::string& component_id,
                       const std::string& id_selector, const bool single,
                       piper::ApiCallBack callBack);

  void ElementAnimate(const std::string& component_id,
                      const std::string& id_selector, const lepus::Value& args);

  void UpdateCoreJS(std::string core_js);

  void GetComponentContextDataAsync(const std::string& component_id,
                                    const std::string& key,
                                    piper::ApiCallBack callBack);

  std::shared_ptr<tasm::TemplateAssembler> GetTasm();

  void HotModuleReplace(const lepus::Value& data, const std::string& message);
  void HotModuleReplaceWithHmrData(const std::vector<tasm::HmrData>& data,
                                   const std::string& message);

  void SetCSSVariables(const std::string& component_id,
                       const std::string& id_selector,
                       const lepus::Value& properties);

  void SetNativeProps(const tasm::NodeSelectRoot& root,
                      const tasm::NodeSelectOptions& options,
                      const lepus::Value& native_props);

  void ReloadFromJS(runtime::UpdateDataTask task);

  void SendDynamicComponentEvent(const std::string& url,
                                 const lepus::Value& err,
                                 const std::vector<uint32_t>& uid_list);

#if ENABLE_ARK_RECORDER
  void SetRecordID(int64_t record_id);
#endif

  void UpdateI18nResource(const std::string& key, const std::string& new_data);

  void Flush();

  // report all tracker events to native facade.
  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack);

  void InvokeUIMethod(const tasm::NodeSelectRoot& root,
                      const tasm::NodeSelectOptions& options,
                      const std::string& method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback);

  void GetPathInfo(const tasm::NodeSelectRoot& root,
                   const tasm::NodeSelectOptions& options,
                   piper::ApiCallBack call_back);

  void GetFields(const tasm::NodeSelectRoot& root,
                 const tasm::NodeSelectOptions& options,
                 const std::vector<std::string>& fields,
                 piper::ApiCallBack call_back);

  tasm::LynxGetUIResult GetLynxUI(const tasm::NodeSelectRoot& root,
                                  const tasm::NodeSelectOptions& options);

  // For Fiber
  void CallLepusMethod(const std::string& method_name, lepus::Value args,
                       const piper::ApiCallBack& callback,
                       uint64_t trace_flow_id);

  inline void SetOperationQueue(
      const std::shared_ptr<TASMOperationQueue>& tasm_operation_queue) {
    operation_queue_ = tasm_operation_queue;
  }

  void PreloadDynamicComponents(const std::vector<std::string>& urls);

  void InsertLynxTemplateBundle(const std::string& url,
                                lynx::tasm::LynxTemplateBundle bundle);

 private:
  std::shared_ptr<tasm::TemplateAssembler> tasm_;
  std::unique_ptr<Delegate> delegate_;
  std::shared_ptr<LynxCardCacheDataManager> card_cached_data_mgr_;
  // tasm thread and layout thread is same one
  // when strategy is {ALL_ON_UI, MOST_ON_TASM}
  std::shared_ptr<TASMOperationQueue> operation_queue_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_ENGINE_H_
