// Copyright 2020 The Lynx Authors. All rights reserved.

#include "shell/lynx_shell.h"

#include "base/no_destructor.h"
#include "config/config.h"
#include "jsbridge/appbrand/app_brand_js_task_runner.h"
#include "jsbridge/module/lynx_module_manager.h"
#include "shell/lynx_runtime_actor_holder.h"
#include "shell/runtime_mediator.h"
#include "shell/tasm_operation_queue.h"
#include "shell/tasm_operation_queue_async.h"
#include "tasm/air/bridge/air_module_handler.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/recorder/recorder_controller.h"
#include "third_party/krypton/glue/lynx_canvas_runtime.h"

namespace lynx {
namespace shell {

namespace {

int32_t NextTraceId() {
  static base::NoDestructor<std::atomic<int32_t>> id{0};
  return (*id)++;
}

}  // namespace

LynxShell::LynxShell(base::ThreadStrategyForRendering strategy,
                     const ShellOption& shell_option)
    : runners_(strategy, shell_option.enable_multi_tasm_thread_,
               shell_option.enable_multi_layout_thread_),
      trace_id_(NextTraceId()),
      enable_runtime_(shell_option.enable_js_),
      tasm_operation_queue_(
          strategy == base::ThreadStrategyForRendering::ALL_ON_UI ||
                  strategy == base::ThreadStrategyForRendering::MOST_ON_TASM
              ? std::make_shared<TASMOperationQueue>()
              : std::make_shared<TASMOperationQueueAsync>()),
      ui_operation_queue_(
          std::make_shared<shell::DynamicUIOperationQueue>(strategy)) {
  LOGI("LynxShell create, this:" << this);

  if (shell_option.enable_auto_concurrency_) {
    thread_mode_manager_.ui_runner = runners_.GetUITaskRunner().get();
    thread_mode_manager_.engine_runner = runners_.GetTASMTaskRunner().get();
    thread_mode_manager_.queue = ui_operation_queue_.get();
  }
}

LynxShell::~LynxShell() {
  LOGI("LynxShell release, this:" << this);
  Destroy();
}

void LynxShell::Destroy() {
  if (is_destroyed_) {
    return;
  }
  LOGI("LynxShell Destroy, this:" << this);

  is_destroyed_ = true;

  facade_actor_->Act([](auto& facade) { facade = nullptr; });
  engine_actor_->Act([](auto& engine) { engine = nullptr; });
  layout_actor_->Act([](auto& layout) { layout = nullptr; });

  runtime_actor_->ActAsync([runtime_actor = runtime_actor_](auto& runtime) {
    if (runtime->TryToDestroy()) {
      runtime_actor->Act([](auto& runtime) { runtime = nullptr; });
    } else {
      // Hold LynxRuntime. It will be released when destroyed callback be
      // handled in LynxRuntime::CallJSCallback() or the delayed release
      // task time out.
      auto holder = LynxRuntimeActorHolder::GetInstance();
      holder->Hold(runtime_actor);
      holder->PostDelayedRelease(runtime->GetRuntimeId());
    }
  });
  ui_operation_queue_->Destroy();
}

void LynxShell::InitRuntimeWithRuntimeDisabled(
    std::shared_ptr<VSyncMonitor> vsync_monitor) {
  DCHECK(!enable_runtime_);
  runtime_actor_ = std::make_shared<LynxActor<runtime::LynxRuntime>>(
      nullptr, nullptr, enable_runtime_);
  vsync_monitor->set_runtime_actor(runtime_actor_);
  tasm_mediator_->SetRuntimeActor(runtime_actor_);
  layout_mediator_->SetRuntimeActor(runtime_actor_);
}

void LynxShell::InitRuntime(
    const std::string& group_id,
    const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
    const std::shared_ptr<lynx::piper::LynxModuleManager>& module_manager,
    const std::function<
        void(const std::shared_ptr<LynxActor<runtime::LynxRuntime>>&)>&
        on_runtime_actor_created,
    std::vector<std::string> preload_js_paths, bool force_reload_js_core,
    bool use_provider_js_env, std::shared_ptr<VSyncMonitor> vsync_monitor,
    std::unique_ptr<ExternalSourceLoader> external_source_loader,
    bool force_use_light_weight_js_engine, bool pending_js_task,
    bool enable_user_code_cache, const std::string& code_cache_source_url,
    bool enable_canvas_optimization) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxShell::InitRuntime");
#if ENABLE_ARK_RECORDER
  int64_t record_id = reinterpret_cast<int64_t>(this);
  engine_actor_->Act(
      [record_id](auto& engine) { engine->SetRecordID(record_id); });
  module_manager->SetRecordID(record_id);
  tasm::recorder::LynxViewInitRecorder::RecordThreadStrategy(
      static_cast<int32_t>(runners_.GetThreadStrategyForRendering()), record_id,
      enable_runtime_);
#endif
  if (!enable_runtime_) {
    InitRuntimeWithRuntimeDisabled(vsync_monitor);
    return;
  }
  fml::RefPtr<fml::TaskRunner> js_task_runner;
  if (use_provider_js_env) {
    js_task_runner =
        fml::MakeRefCounted<provider::piper::AppBrandJsTaskRunner>(group_id);
  } else {
    js_task_runner = runners_.GetJSTaskRunner();
  }
  auto delegate = std::make_unique<RuntimeMediator>(
      facade_actor_, engine_actor_, card_cached_data_mgr_, js_task_runner,
      std::move(external_source_loader), loader);
  delegate->set_vsync_monitor(vsync_monitor);
  tasm_mediator_->SetReceiver(delegate.get());
  auto runtime = std::make_unique<runtime::LynxRuntime>(
      group_id, use_provider_js_env, trace_id_, std::move(delegate),
      enable_user_code_cache, code_cache_source_url,
      enable_canvas_optimization);
  runtime_actor_ = std::make_shared<LynxActor<runtime::LynxRuntime>>(
      std::move(runtime), js_task_runner, enable_runtime_);
  vsync_monitor->set_runtime_actor(runtime_actor_);
  if (canvas_manager_) {
    auto canvas_runtime =
        std::make_unique<canvas::LynxCanvasRuntime>(runtime_actor_);
    auto canvas_runtime_actor =
        std::make_shared<LynxActor<canvas::CanvasRuntime>>(
            std::move(canvas_runtime), js_task_runner, true);
    runners_.StartGPUThread();
    canvas_manager_->Init(canvas_runtime_actor, js_task_runner,
                          runners_.GetGPUTaskRunner());
  }
  on_runtime_actor_created(runtime_actor_);
  tasm_mediator_->SetRuntimeActor(runtime_actor_);
  layout_mediator_->SetRuntimeActor(runtime_actor_);

  start_js_runtime_task_ =
      [loader, module_manager, preload_js_paths = std::move(preload_js_paths),
       observer = observer_, force_reload_js_core,
       force_use_light_weight_js_engine, vsync_monitor,
       canvas_runtime_observer = canvas_manager_](
          std::unique_ptr<runtime::LynxRuntime>& runtime) mutable {
        vsync_monitor->BindToCurrentThread();
        vsync_monitor->Init();
        runtime->Init(loader, module_manager, observer, canvas_runtime_observer,
                      std::move(preload_js_paths), force_reload_js_core,
                      force_use_light_weight_js_engine);
      };

  if (!pending_js_task) {
    runtime_actor_->ActAsync(std::move(start_js_runtime_task_));
  }
  if (observer_) {
    observer_->OnJsTaskRunnerReady(js_task_runner);
  }
}

void LynxShell::StartJsRuntime() {
  if (!is_destroyed_ && start_js_runtime_task_ != nullptr) {
    runtime_actor_->ActAsync(std::move(start_js_runtime_task_));
  }
}

bool LynxShell::IsDestroyed() { return is_destroyed_; }

void LynxShell::LoadTemplate(
    const std::string& url, std::vector<uint8_t> source,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(template_data);
  engine_actor_->Act(
      [url, source = std::move(source), template_data](auto& engine) mutable {
        engine->LoadTemplate(url, std::move(source), template_data);
      });
}

void LynxShell::LoadTemplateBundle(
    const std::string& url, tasm::LynxTemplateBundle template_bundle,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(template_data);
  engine_actor_->Act([url, template_bundle = std::move(template_bundle),
                      template_data](auto& engine) mutable {
    engine->LoadTemplateBundle(url, std::move(template_bundle), template_data);
  });
}

void LynxShell::MarkDirty() {
  if (is_destroyed_) {
    return;
  }
  ui_operation_queue_->MarkDirty();
}

void LynxShell::Flush() {
  if (is_destroyed_) {
    return;
  }
  ui_operation_queue_->Flush();
}

void LynxShell::LoadSSRData(
    std::vector<uint8_t> source,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(template_data);
  engine_actor_->Act(
      [source = std::move(source), template_data](auto& engine) mutable {
        engine->LoadSSRData(std::move(source), template_data);
      });
}

void LynxShell::LoadComponent(const std::string& url,
                              std::vector<uint8_t> source,
                              int32_t callback_id) {
  engine_actor_->Act(
      [url, source = std::move(source), callback_id](auto& engine) mutable {
        engine->LoadComponentWithCallback(url, std::move(source), true,
                                          callback_id);
      });
}

void LynxShell::SetLepusApiActorDarwin(
    const std::shared_ptr<tasm::LepusApiActor>& actor) {
  actor->SetEngineActor(engine_actor_);
}

void LynxShell::SetLepusApiActor(lynx::tasm::LepusApiActor* actor) {
  actor->SetEngineActor(engine_actor_);
}

void LynxShell::UpdateDataByParsedData(
    const std::shared_ptr<tasm::TemplateData>& data,
    base::closure finished_callback) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(data);
  auto order = ui_operation_queue_->UpdateNativeUpdateDataOrder();
  engine_actor_->Act([data, order,
                      finished_callback =
                          std::move(finished_callback)](auto& engine) mutable {
    engine->UpdateDataByParsedData(data, order, std::move(finished_callback));
  });
}

void LynxShell::ResetDataByParsedData(
    const std::shared_ptr<tasm::TemplateData>& data) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(data);
  auto order = ui_operation_queue_->UpdateNativeUpdateDataOrder();
  engine_actor_->Act([data, order](auto& engine) {
    engine->ResetDataByParsedData(data, order);
  });
}

void LynxShell::ReloadTemplate(const std::shared_ptr<tasm::TemplateData>& data,
                               const lepus::Value& global_props) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  EnsureTemplateDataThreadSafe(data);
  auto order = ui_operation_queue_->UpdateNativeUpdateDataOrder();
  engine_actor_->Act([data, global_props, order](auto& engine) {
    engine->ReloadTemplate(data, global_props, order);
  });
}

void LynxShell::UpdateConfig(const lepus::Value& config) {
  engine_actor_->Act([config](auto& engine) { engine->UpdateConfig(config); });
}

void LynxShell::UpdateGlobalProps(const lepus::Value& global_props) {
  auto global_props_thread_safe = EnsureGlobalPropsThreadSafe(global_props);
  engine_actor_->Act([global_props_thread_safe](auto& engine) {
    engine->UpdateGlobalProps(global_props_thread_safe);
  });
}

void LynxShell::UpdateViewport(float width, int32_t width_mode, float height,
                               int32_t height_mode, bool need_layout) {
#if ENABLE_ARK_RECORDER
  tasm::recorder::LynxViewInitRecorder::RecordViewPort(
      height_mode, width_mode, height, width, height, width,
      reinterpret_cast<int64_t>(this));
#endif
  engine_actor_->Act([width, width_mode, height, height_mode,
                      need_layout](auto& engine) {
    engine->UpdateViewport(width, width_mode, height, height_mode, need_layout);
  });
}

void LynxShell::TriggerLayout() {
  layout_actor_->Act([](auto& layout) { layout->Layout({}); });
}

void LynxShell::UpdateScreenMetrics(float width, float height, float scale) {
  engine_actor_->Act([width, height, scale](auto& engine) {
    engine->UpdateScreenMetrics(width, height, scale);
  });
}

void LynxShell::UpdateFontScale(float scale) {
  engine_actor_->Act([scale](auto& engine) { engine->UpdateFontScale(scale); });
}

void LynxShell::SetFontScale(float scale) {
  engine_actor_->Act([scale](auto& engine) { engine->SetFontScale(scale); });
}

void LynxShell::SyncFetchLayoutResult() {
  engine_actor_->Act([](auto& engine) { engine->SyncFetchLayoutResult(); });
}

void LynxShell::SendCustomEvent(const std::string& name, int32_t tag,
                                const lepus::Value& params,
                                const std::string& params_name) {
  engine_actor_->Act([name, tag, params, params_name](auto& engine) {
    engine->SendCustomEvent(name, tag, params, params_name);
  });
}

void LynxShell::SendTouchEvent(const std::string& name, int32_t tag, float x,
                               float y, float client_x, float client_y,
                               float page_x, float page_y) {
  engine_actor_->Act(
      [name, tag, x, y, client_x, client_y, page_x, page_y](auto& engine) {
        (void)engine->SendTouchEvent(name, tag, x, y, client_x, client_y,
                                     page_x, page_y);
      });
}

void LynxShell::OnPseudoStatusChanged(int32_t id, int32_t pre_status,
                                      int32_t current_status) {
  engine_actor_->Act([id, pre_status, current_status](auto& engine) {
    (void)engine->OnPseudoStatusChanged(id, pre_status, current_status);
  });
}

void LynxShell::SendBubbleEvent(const std::string& name, int32_t tag,
                                lepus::DictionaryPtr dict) {
  engine_actor_->Act([name, tag, &dict](auto& engine) {
    engine->SendBubbleEvent(name, tag, dict);
  });
}

void LynxShell::SendInternalEvent(int32_t tag, int32_t event_id) {
  engine_actor_->Act([tag, event_id](auto& engine) {
    engine->SendInternalEvent(tag, event_id);
  });
}

void LynxShell::SendSsrGlobalEvent(const std::string& name,
                                   const lepus_value& params) {
  runtime_actor_->ActAsync([name, params](auto& runtime) {
    runtime->SendSsrGlobalEvent(name, params);
  });
}

void LynxShell::SendGlobalEventToLepus(const std::string& name,
                                       const lepus_value& params) {
  engine_actor_->Act([name, params](auto& engine) {
    engine->SendGlobalEventToLepus(name, params);
  });
}

void LynxShell::TriggerEventBus(const std::string& name,
                                const lepus_value& params) {
  engine_actor_->Act(
      [name, params](auto& engine) { engine->TriggerEventBus(name, params); });
}

std::unique_ptr<lepus_value> LynxShell::GetCurrentData() {
  return engine_actor_->ActSync(
      [](auto& engine) { return engine->GetCurrentData(); });
}

const lepus::Value LynxShell::GetPageDataByKey(std::vector<std::string> keys) {
  return engine_actor_->ActSync([keys = std::move(keys)](auto& engine) mutable {
    return engine->GetPageDataByKey(std::move(keys));
  });
}

// TODO(heshan): change this method to be private
tasm::ListNode* LynxShell::GetListNode(int32_t tag) {
  // ensure on engine thread
  DCHECK(engine_actor_->CanRunNow());

  return engine_actor_->Impl()->GetListNode(tag);
}

void LynxShell::RenderListChild(int32_t tag, uint32_t index,
                                int64_t operation_id) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node != nullptr) {
    list_node->RenderComponentAtIndex(index, operation_id);
  }
}

void LynxShell::UpdateListChild(int32_t tag, uint32_t sign, uint32_t index,
                                int64_t operation_id) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node != nullptr) {
    list_node->UpdateComponent(sign, index, operation_id);
  }
}

void LynxShell::RemoveListChild(int32_t tag, uint32_t sign) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node != nullptr) {
    list_node->RemoveComponent(sign);
  }
}

int32_t LynxShell::ObtainListChild(int32_t tag, uint32_t index,
                                   int64_t operation_id,
                                   bool enable_reuse_notification) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node == nullptr) {
    return -1;
  }
  return list_node->ComponentAtIndex(index, operation_id,
                                     enable_reuse_notification);
}

void LynxShell::RecycleListChild(int32_t tag, uint32_t sign) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node != nullptr) {
    list_node->EnqueueComponent(sign);
  }
}

void LynxShell::AssembleListPlatformInfo(
    int32_t tag, base::MoveOnlyClosure<void, tasm::ListNode*> assembler) {
  ThreadModeAutoSwitch auto_switch(thread_mode_manager_);

  auto* list_node = GetListNode(tag);
  if (list_node != nullptr) {
    assembler(list_node);
  }
}

void LynxShell::LoadListNode(int32_t tag, uint32_t index, int64_t operationId,
                             bool enable_reuse_notification) {
  engine_actor_->ActAsync([tag, index, operationId,
                           enable_reuse_notification](auto& engine) {
    tasm::ListNode* listNode = engine->GetListNode(tag);
    listNode->ComponentAtIndex(index, operationId, enable_reuse_notification);
  });
}

void LynxShell::EnqueueListNode(int32_t tag, uint32_t component_tag) {
  engine_actor_->ActAsync([tag, component_tag](auto& engine) {
    tasm::ListNode* listNode = engine->GetListNode(tag);
    listNode->EnqueueComponent(component_tag);
  });
}

void LynxShell::OnEnterForeground() {
// TODO(liukeang): remove macro
#if ENABLE_AIR
  if (!enable_runtime_) {
    engine_actor_->Act([](auto& engine) {
      engine->SendAirPageEvent("onShow", lepus_value());
    });
    return;
  }
#endif
  runtime_actor_->ActAsync(
      [](auto& runtime) { runtime->OnAppEnterForeground(); });
}

void LynxShell::OnEnterBackground() {
#if ENABLE_AIR
  if (!enable_runtime_) {
    engine_actor_->Act([](auto& engine) {
      engine->SendAirPageEvent("onHide", lepus_value());
    });
    return;
  }
#endif
  runtime_actor_->ActAsync(
      [](auto& runtime) { runtime->OnAppEnterBackground(); });
}

void LynxShell::UpdateI18nResource(const std::string& key,
                                   const std::string& new_data) {
  engine_actor_->Act([key, new_data](auto& engine) {
    engine->UpdateI18nResource(key, new_data);
  });
}

std::unordered_map<std::string, std::string> LynxShell::GetAllJsSource() {
  return engine_actor_->ActSync(
      [](auto& engine) { return engine->GetAllJsSource(); });
}

std::shared_ptr<tasm::TemplateAssembler> LynxShell::GetTasm() {
  return engine_actor_->Impl()->GetTasm();
}

void LynxShell::HotModuleReplace(const lepus::Value& data,
                                 const std::string& message) {
  engine_actor_->Act([data, message](auto& engine) {
    engine->HotModuleReplace(data, message);
  });
}

void LynxShell::HotModuleReplaceWithHmrData(
    const std::vector<tasm::HmrData>& data, const std::string& message) {
  engine_actor_->Act([data, message](auto& engine) {
    engine->HotModuleReplaceWithHmrData(data, message);
  });
}

tasm::LynxGetUIResult LynxShell::GetLynxUI(
    const tasm::NodeSelectRoot& root, const tasm::NodeSelectOptions& options) {
  return engine_actor_->Impl()->GetLynxUI(root, options);
}

void LynxShell::RunOnTasmThread(std::function<void(void)>&& task) {
  engine_actor_->Act([task = std::move(task)](auto& engine) { task(); });
}

void LynxShell::AdoptCanvasManager(
    std::shared_ptr<canvas::ICanvasManager> canvas_manager) {
  canvas_manager_ = canvas_manager;
}

uint32_t LynxShell::ThreadStrategy() {
  return runners_.GetThreadStrategyForRendering();
}

void LynxShell::EnsureTemplateDataThreadSafe(
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  // need clone template data if consumed by tasm thread
  if (template_data != nullptr && !(engine_actor_->CanRunNow())) {
    template_data->CloneValue();
  }
}

lepus::Value LynxShell::EnsureGlobalPropsThreadSafe(
    const lepus::Value& global_props) {
  // need clone global props if consumed by tasm thread
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxShell::EnsureGlobalPropsThreadSafe");
  if (!(engine_actor_->CanRunNow())) {
    return lynx::lepus::Value::Clone(global_props);
  } else {
    return global_props;
  }
}

void LynxShell::PreloadDynamicComponents(std::vector<std::string> urls) {
  engine_actor_->Act([urls = std::move(urls)](auto& engine) {
    engine->PreloadDynamicComponents(urls);
  });
}

void LynxShell::MarkDrawEndTimingIfNeeded() {
  facade_actor_->Act([](auto& facade) { facade->MarkDrawEndTimingIfNeeded(); });
}
void LynxShell::UpdateDrawEndTimingState(bool need_draw_end,
                                         const std::string& flag) {
  facade_actor_->Act([need_draw_end, flag](auto& facade) {
    facade->UpdateDrawEndTimingState(need_draw_end, flag);
  });
}
void LynxShell::MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                                const std::string& flag) {
  facade_actor_->Act([key, flag](auto& facade) {
    facade->MarkUIOperationQueueFlushTiming(key, flag);
  });
}

void LynxShell::AddAttributeTimingFlagFromProps(const std::string& flag) {
  facade_actor_->Act(
      [flag](auto& facade) { facade->AddAttributeTimingFlagFromProps(flag); });
}

void LynxShell::InitAirEnv(
    std::unique_ptr<air::AirModuleHandler> module_handler) {
#if ENABLE_AIR
  module_handler->SetEngineActor(engine_actor_);
  // init air runtime
  tasm_mediator_->InitAirRuntime(module_handler);
#endif
}

}  // namespace shell
}  // namespace lynx
