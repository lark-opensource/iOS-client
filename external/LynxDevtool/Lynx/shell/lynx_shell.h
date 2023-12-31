// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_SHELL_H_
#define LYNX_SHELL_LYNX_SHELL_H_

#include <array>
#include <atomic>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "jsbridge/module/module_delegate.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "jsbridge/runtime/lynx_runtime_observer.h"
#include "jsbridge/runtime/template_delegate.h"
#include "lepus/value.h"
#include "shell/dynamic_ui_operation_queue.h"
#include "shell/external_source_loader.h"
#include "shell/layout_mediator.h"
#include "shell/lynx_actor.h"
#include "shell/lynx_actor_specialization.h"
#include "shell/lynx_card_cache_data_manager.h"
#include "shell/lynx_engine.h"
#include "shell/native_facade.h"
#include "shell/tasm_mediator.h"
#include "shell/tasm_operation_queue.h"
#include "shell/thread_mode_auto_switch.h"
#include "tasm/lepus_api_actor/lepus_api_actor.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/template_data.h"
#include "third_party/krypton/glue/canvas_manager_interface.h"

namespace lynx {
namespace tasm {
class RadonNode;
class LynxTemplateBundle;
}  // namespace tasm

namespace air {
class AirModuleHandler;
}  // namespace air

namespace shell {
class VSyncMonitor;

struct ShellOption {
  bool enable_js_{true};
  bool enable_multi_tasm_thread_{true};
  bool enable_multi_layout_thread_{true};
  bool enable_auto_concurrency_{false};
};

// support create and destroy in any thread
class LynxShell {
 public:
  // TODO(heshan):now the init process is too ugly, will refactor,
  // create actors in LynxShell constructor, then set impl to actors
  // when init.
  template <typename U, typename V, typename W>
  static LynxShell* Create(
      U&& native_facade_creator, V&& lynx_engine_creator,
      W&& layout_context_creator, base::ThreadStrategyForRendering strategy,
      const std::shared_ptr<VSyncMonitor>& vsync_monitor,
      const std::function<void(const std::shared_ptr<LynxActor<LynxEngine>>&)>&
          on_engine_actor_created,
      const ShellOption& shell_option) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxShell::Create");

    // for auto concurrency, force using MULTI_THREADS by default.
    if (shell_option.enable_auto_concurrency_) {
      strategy = base::ThreadStrategyForRendering::MULTI_THREADS;
    }

    LynxShell* shell = new LynxShell(strategy, shell_option);
    shell->facade_actor_ = std::make_shared<LynxActor<NativeFacade>>(
        native_facade_creator(), shell->runners_.GetUITaskRunner());

    // create layout actor
    auto layout_mediator = std::make_unique<lynx::shell::LayoutMediator>(
        shell->tasm_operation_queue_);
    shell->layout_mediator_ = layout_mediator.get();
    shell->layout_actor_ = std::make_shared<LynxActor<tasm::LayoutContext>>(
        layout_context_creator(std::move(layout_mediator), shell->trace_id_),
        shell->runners_.GetLayoutTaskRunner());

    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY,
                      "LynxShell::Create::CreateEngineActor");
    // create engine actor
    auto tasm_mediator = std::make_unique<TasmMediator>(
        shell->facade_actor_, shell->card_cached_data_mgr_, vsync_monitor,
        shell->layout_actor_);
    shell->tasm_mediator_ = tasm_mediator.get();
    shell->engine_actor_ = std::make_shared<LynxActor<LynxEngine>>(
        lynx_engine_creator(std::move(tasm_mediator), shell->runners_,
                            shell->card_cached_data_mgr_, shell->trace_id_,
                            shell),
        shell->runners_.GetTASMTaskRunner());
    on_engine_actor_created(shell->engine_actor_);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    shell->tasm_mediator_->SetEngineActor(shell->engine_actor_);
    // after set shell members
    shell->engine_actor_->Impl()->SetOperationQueue(
        shell->tasm_operation_queue_);
    shell->layout_actor_->Impl()->SetRequestLayoutCallback(
        [layout_actor = shell->layout_actor_]() {
          layout_actor->Act([](auto& layout) { layout->Layout({}); });
        });
    auto tasm = shell->engine_actor_->Impl()->GetTasm();
    // @note(lipin): avoid crash when lynx_shell_unittest
    if (tasm != nullptr) {
      shell->ui_operation_queue_->SetErrorCallback(
          [facade_actor = shell->facade_actor_](int32_t error_code,
                                                const std::string& msg) {
            facade_actor->Act([error_code, msg](auto& facade) {
              facade->ReportError(error_code, msg);
            });
          });
      auto& element_manager = tasm->page_proxy()->element_manager();
      element_manager->painting_context()->impl()->SetUIOperationQueue(
          shell->ui_operation_queue_);
      element_manager->SetShadowNodeCreator(
          [weak_platform_layout_context =
               shell->layout_actor_->Impl()->GetWeakPlatformImpl()](
              int id, intptr_t layout_node_ptr, const std::string& tag,
              auto* props, const bool is_parent_inline_container) {
            auto platform_layout_context = weak_platform_layout_context.lock();
            if (platform_layout_context) {
              return platform_layout_context->CreateLayoutNode(
                  id, layout_node_ptr, tag, props, is_parent_inline_container);
            }
            return 0;
          });
      shell->layout_mediator_->Init(shell->engine_actor_, shell->facade_actor_,
                                    element_manager->node_manager(),
                                    element_manager->air_node_manager(),
                                    element_manager->catalyzer());
      shell->engine_actor_->Act([](auto& engine) { engine->Init(); });
    }
    return shell;
  }

  ~LynxShell();

  void InitRuntime(
      const std::string& group_id,
      const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
      const std::shared_ptr<lynx::piper::LynxModuleManager>& module_manager,
      const std::function<
          void(const std::shared_ptr<LynxActor<runtime::LynxRuntime>>&)>&
          on_runtime_actor_created,
      std::vector<std::string> preload_js_paths, bool force_reload_js_core,
      bool use_provider_js_env, std::shared_ptr<VSyncMonitor> vsync_monitor,
      std::unique_ptr<ExternalSourceLoader> external_source_loader,
      bool force_use_light_weight_js_engine = false,
      bool pending_js_task = false, bool enable_user_code_cache = false,
      const std::string& code_cache_source_url = "",
      bool enable_canvas_optimization = false);

  void InitRuntimeWithRuntimeDisabled(
      std::shared_ptr<VSyncMonitor> vsync_monitor);

  void StartJsRuntime();

  // TODO(heshan): will be deleted after ios platform ready
  void Destroy();

  // TODO(heshan): will be deleted after ios platform ready
  bool IsDestroyed();

  void LoadTemplate(const std::string& url, std::vector<uint8_t> source,
                    const std::shared_ptr<tasm::TemplateData>& template_data);

  void LoadTemplateBundle(
      const std::string& url, tasm::LynxTemplateBundle template_bundle,
      const std::shared_ptr<tasm::TemplateData>& template_data);

  void MarkDirty();

  void Flush();

  void LoadSSRData(std::vector<uint8_t> source,
                   const std::shared_ptr<tasm::TemplateData>& template_data);

  void LoadComponent(const std::string& url, std::vector<uint8_t> source,
                     int32_t callback_id);

  void UpdateData(const std::string& data);

  void SetLepusApiActorDarwin(

      const std::shared_ptr<tasm::LepusApiActor>& actor);

  void SetLepusApiActor(lynx::tasm::LepusApiActor* actor);

  void UpdateDataByParsedData(const std::shared_ptr<tasm::TemplateData>& data,
                              base::closure finished_callback = nullptr);

  void ResetDataByParsedData(const std::shared_ptr<tasm::TemplateData>& data);

  void ReloadTemplate(const std::shared_ptr<tasm::TemplateData>& data,
                      const lepus::Value& global_props = lepus::Value());

  void UpdateConfig(const lepus::Value& config);

  void UpdateGlobalProps(const lepus::Value& global_props);

  void UpdateScreenMetrics(float width, float height, float scale);

  void UpdateFontScale(float scale);

  void SetFontScale(float scale);

  void UpdateViewport(float width, int32_t width_mode, float height,
                      int32_t height_mode, bool need_layout = true);

  void TriggerLayout();

  void SyncFetchLayoutResult();

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

  void SendSsrGlobalEvent(const std::string& name, const lepus_value& params);

  void TriggerEventBus(const std::string& name, const lepus_value& params);

  // synchronous
  std::unique_ptr<lepus_value> GetCurrentData();

  const lepus::Value GetPageDataByKey(std::vector<std::string> keys);

  tasm::ListNode* GetListNode(int32_t tag);

  // list methods
  void RenderListChild(int32_t tag, uint32_t index, int64_t operation_id);

  void UpdateListChild(int32_t tag, uint32_t sign, uint32_t index,
                       int64_t operation_id);

  void RemoveListChild(int32_t tag, uint32_t sign);

  int32_t ObtainListChild(int32_t tag, uint32_t index, int64_t operation_id,
                          bool enable_reuse_notification);

  void RecycleListChild(int32_t tag, uint32_t sign);

  void AssembleListPlatformInfo(
      int32_t tag, base::MoveOnlyClosure<void, tasm::ListNode*> assembler);

  void LoadListNode(int32_t tag, uint32_t index, int64_t operationId,
                    bool enable_reuse_notification);

  void EnqueueListNode(int32_t tag, uint32_t component_tag);

  void OnEnterForeground();

  void OnEnterBackground();

  void UpdateI18nResource(const std::string& key, const std::string& new_data);

  // TODO(heshan):will be deleted, pass when ReportError
  std::unordered_map<std::string, std::string> GetAllJsSource();

  // TODO(heshan):will be deleted when js thread ready
  std::shared_ptr<tasm::TemplateAssembler> GetTasm();

  void SetLynxRuntimeObserver(
      const std::shared_ptr<runtime::LynxRuntimeObserver>& observer) {
    observer_ = observer;
  }

  int32_t GetTraceId() { return trace_id_; }

  std::shared_ptr<LynxActor<runtime::LynxRuntime>> GetRuntimeActor() {
    return runtime_actor_;
  }

  void HotModuleReplace(const lepus::Value& data, const std::string& message);
  void HotModuleReplaceWithHmrData(
      const std::vector<tasm::HmrData>& component_data,
      const std::string& message);

  void RunOnTasmThread(std::function<void(void)>&& task);
  void MarkDrawEndTimingIfNeeded();
  void UpdateDrawEndTimingState(bool need_draw_end, const std::string& flag);
  void MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                       const std::string& flag);
  void AddAttributeTimingFlagFromProps(const std::string& flag);

  tasm::LynxGetUIResult GetLynxUI(const tasm::NodeSelectRoot& root,
                                  const tasm::NodeSelectOptions& options);

  std::weak_ptr<canvas::ICanvasManager> GetCanvasManager() {
    return canvas_manager_;
  }

  void AdoptCanvasManager(
      std::shared_ptr<canvas::ICanvasManager> canvas_manager);

  /**
   * @brief get  thread strategy
   * @return one of ThreadStrategyForRendering
   */
  uint32_t ThreadStrategy();

  void PreloadDynamicComponents(std::vector<std::string> urls);

  void InitAirEnv(std::unique_ptr<air::AirModuleHandler> module_handler);

 private:
  explicit LynxShell(base::ThreadStrategyForRendering strategy,
                     const ShellOption& shell_option);

  void EnsureTemplateDataThreadSafe(
      const std::shared_ptr<tasm::TemplateData>& template_data);

  lepus::Value EnsureGlobalPropsThreadSafe(const lepus::Value& global_props);

  std::atomic_bool is_destroyed_{false};

  std::shared_ptr<LynxActor<NativeFacade>>
      facade_actor_;  // on platform UI runner

  std::shared_ptr<LynxActor<LynxEngine>> engine_actor_;  // on TASM runner

  std::shared_ptr<LynxActor<runtime::LynxRuntime>>
      runtime_actor_;  // on JS runner
  std::shared_ptr<LynxActor<tasm::LayoutContext>>
      layout_actor_;  // on Layout runner

  base::TaskRunnerManufactor runners_;

  // TODO(heshan):will move to delegate of LynxRuntime
  std::shared_ptr<runtime::LynxRuntimeObserver> observer_;

  const int32_t trace_id_;

  bool enable_runtime_ = true;

  std::shared_ptr<LynxCardCacheDataManager> card_cached_data_mgr_ =
      std::make_shared<LynxCardCacheDataManager>();
  std::shared_ptr<TASMOperationQueue> tasm_operation_queue_;
  std::shared_ptr<shell::DynamicUIOperationQueue> ui_operation_queue_;
  TasmMediator* tasm_mediator_;      // NOT OWNED
  LayoutMediator* layout_mediator_;  // NOT OWNED

  std::function<void(std::unique_ptr<runtime::LynxRuntime>&)>
      start_js_runtime_task_;

  std::shared_ptr<canvas::ICanvasManager> canvas_manager_;

  ThreadModeManager thread_mode_manager_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_SHELL_H_
