// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/template_assembler.h"

#include <chrono>
#include <exception>
#include <limits>
#include <numeric>
#include <unordered_set>
#include <vector>

#include "base/json/json_util.h"
#include "base/log/logging.h"
#include "base/perf_collector.h"
#include "base/string/string_number_convert.h"
#include "base/tasm_constants.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_fragment.h"
#include "css/css_style_sheet_manager.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/module/lynx_module.h"
#include "lepus/array.h"
#include "lepus/binary_input_stream.h"
#include "lepus/builtin.h"
#include "lepus/json_parser.h"
#include "lepus/parser.h"
#include "lepus/value.h"
#include "lepus/vm_context.h"
#include "ssr/dom_reconstruct_utils.h"
#include "ssr/ssr_binary_reader.h"
#include "tasm/base/base_def.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/dynamic_component/dynamic_component_loader.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/lynx_view_data_manager.h"
#include "tasm/radon/base_component.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/radon_dispatch_option.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/radon/radon_node.h"
#include "tasm/radon/radon_page.h"
#include "tasm/recorder/recorder_controller.h"
#include "tasm/renderer.h"
#include "tasm/template_binary_reader.h"
#include "tasm/value_utils.h"

#if !ENABLE_CLI
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"
#include "tasm/react/painting_context.h"
#endif

#if ENABLE_AIR
#include "tasm/air/air_element/air_element.h"
#include "tasm/air/air_element/air_page_element.h"
#include "tasm/air/air_touch_event_handler.h"
#endif

#if ENABLE_LEPUSNG_WORKLET
#include "worklet/lepus_element.h"
#endif  // ENABLE_LEPUSNG_WORKLET

namespace lynx {
namespace tasm {

namespace {
std::string ConstructDecodeErrorMessage(bool is_card, const std::string& url,
                                        const std::string& error_msg = "") {
  constexpr char kDecodeError[] = "Decode error: ";
  std::string msg = kDecodeError + error_msg;
  if (!is_card) {
    constexpr char kDecodeErrorJoiner[] = ", type: dynamic component, url: ";
    msg.append(kDecodeErrorJoiner + url);
  }
  return msg;
}
}  // namespace

using base::PerfCollector;

const std::unordered_map<int, std::shared_ptr<PageMould>>&
TemplateAssembler::page_moulds() {
  return template_entries_[DEFAULT_ENTRY_NAME]->page_moulds();
}

lynx_thread_local(TemplateAssembler*) TemplateAssembler::curr_ = nullptr;

static lepus::String k_actual_first_screen("__isActualFirstScreen");

TemplateAssembler::PerfHandler::PerfHandler(
    std::weak_ptr<TemplateAssembler> tasm,
    fml::RefPtr<fml::TaskRunner> tasm_runner)
    : tasm_(tasm), tasm_runner_(tasm_runner) {}

void TemplateAssembler::PerfHandler::OnFirstLoadPerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  fml::TaskRunner::RunNowOrPostTask(tasm_runner_, [weak_tasm = tasm_, perf,
                                                   perf_timing]() {
    auto tasm = weak_tasm.lock();
    if (tasm && !tasm->destroyed()) {
      if (tasm->page_config_ && tasm->page_config_->GetDisablePerfCollector()) {
        return;
      }
      tasm->OnFirstLoadPerfReady(perf, perf_timing);
    }
  });
}

void TemplateAssembler::PerfHandler::OnUpdatePerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  fml::TaskRunner::RunNowOrPostTask(tasm_runner_, [weak_tasm = tasm_, perf,
                                                   perf_timing]() {
    auto tasm = weak_tasm.lock();
    if (tasm && !tasm->destroyed()) {
      // Disable "PerfCollector" callbacks according to page configuration.
      // default false;
      if (tasm->page_config_ && tasm->page_config_->GetDisablePerfCollector()) {
        return;
      }
      // calculate actual fmp
      if (tasm->actual_fmp_start_ > 0 &&
          tasm->actual_fmp_end_ > tasm->actual_fmp_start_) {
        std::unordered_map<int32_t, double> perf_t(perf);
        std::unordered_map<int32_t, std::string> perf_timing_t(perf_timing);
        double cost = tasm->actual_fmp_end_ - tasm->actual_fmp_start_;
        // once actual fmp
        tasm->actual_fmp_start_ = 0;
        // The date of the change is used as actual_fmp_index.
        int32_t actual_fmp_index = 20211216;
        perf_t[actual_fmp_index] = cost;
        perf_timing_t[actual_fmp_index] = std::to_string(tasm->actual_fmp_end_);
        tasm->OnUpdatePerfReady(perf_t, perf_timing_t);
      } else {
        tasm->OnUpdatePerfReady(perf, perf_timing);
      }
    }
  });
}

void TemplateAssembler::PerfHandler::OnDynamicComponentPerfReady(
    const std::unordered_map<std::string,
                             base::PerfCollector::DynamicComponentPerfInfo>&
        dynamic_component_perf) {
  if (dynamic_component_perf.empty()) {
    return;
  }

  fml::TaskRunner::RunNowOrPostTask(tasm_runner_, [weak_tasm = tasm_,
                                                   dynamic_component_perf]() {
    auto tasm = weak_tasm.lock();
    if (tasm && !tasm->destroyed()) {
      if (tasm->page_config_ && tasm->page_config_->GetDisablePerfCollector()) {
        return;
      }
      tasm->OnDynamicComponentPerfReady(dynamic_component_perf);
    }
  });
}

TemplateAssembler::Scope::Scope(TemplateAssembler* tasm) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateAssembler::Scope::Scope");
  if (tasm != nullptr && curr_ == nullptr) {
    curr_ = tasm;
    scoped_ = true;
    base::ErrorStorage::GetInstance().Reset();
  }
}

TemplateAssembler::Scope::~Scope() {
  if (scoped_) {
    auto& error = base::ErrorStorage::GetInstance().GetError();
    if (error != nullptr) {
      curr_->ReportError(error->error_code_, error->error_message_.c_str());
    }
    curr_ = nullptr;
    base::ErrorStorage::GetInstance().Reset();
  }
}

TemplateAssembler::TemplateAssembler(Delegate& delegate,
                                     std::unique_ptr<ElementManager> client,
                                     int32_t trace_id)
    : page_proxy_(std::move(client), &delegate),
      support_component_js_(false),
      target_sdk_version_("null"),
      template_loaded_(false),
      actual_fmp_start_(0),
      actual_fmp_end_(0),
      delegate_(delegate),
      touch_event_handler_(nullptr),
#if ENABLE_AIR
      air_touch_event_handler_(nullptr),
#endif
      has_load_page_(false),
      page_config_(nullptr),
      trace_id_(trace_id),
      destroyed_(false),
      perf_handler_(nullptr),
      is_loading_template_(false),
      font_scale_(1.0),
      component_loader_(nullptr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateAssembler::constructor");
  page_proxy_.element_manager()->SetTraceId(trace_id);
  auto card = std::make_shared<TemplateEntry>();
  template_entries_.insert({DEFAULT_ENTRY_NAME, card});
}

TemplateAssembler::~TemplateAssembler() {
  LOGI("TemplateAssembler::Release url:" << url_ << " this:" << this);
};

void TemplateAssembler::Init(fml::RefPtr<fml::TaskRunner> tasm_runner) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateAssembler::Init");
  std::weak_ptr<TemplateAssembler> wp(shared_from_this());
  perf_handler_ = std::make_shared<PerfHandler>(wp, tasm_runner);
  PerfCollector::GetInstance().RegisterReadyDelegate(trace_id_, perf_handler_);
}

void TemplateAssembler::UpdateGlobalProps(const lepus::Value& data,
                                          bool need_render) {
#if ENABLE_ARK_RECORDER
  tasm::recorder::TemplateAssemblerRecorder::RecordSetGlobalProps(data,
                                                                  record_id_);
#endif
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_UPDATE_GLOBAL_PROPS,
              "need render", need_render);
  global_props_ = data;
  // Update `__globalProps` for DynamicComponent.
  std::for_each(vm_to_template_entry_.begin(), vm_to_template_entry_.end(),
                [card_entry = this->FindEntry(DEFAULT_ENTRY_NAME).get(),
                 &global_props = this->global_props_](const auto& pair) {
                  if (pair.second != card_entry) {
                    pair.first->UpdateTopLevelVariable(kGlobalPropsKey,
                                                       global_props);
                  }
                });

  if (template_loaded_) {
    NotifyGlobalPropsChanged(data);
  }

  SetGlobalDataToContext(FindEntry(tasm::DEFAULT_ENTRY_NAME)->GetVm().get(),
                         data);
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    constexpr const static char* kUpdateGlobalProps = "updateGlobalProps";
    FindEntry(tasm::DEFAULT_ENTRY_NAME)
        ->GetVm()
        ->Call(kUpdateGlobalProps, {data});
  } else {
    need_render =
        need_render && template_loaded_ && !page_proxy_.IsServerSideRendering();
    page_proxy_.UpdateGlobalProps(global_props_, need_render);
  }
}

void TemplateAssembler::InitLepusDebugger() {
  auto card = template_entries_.find(DEFAULT_ENTRY_NAME);
  if (card != template_entries_.end()) {
    card->second->InitLepusDebugger(lepus_context_observer_);
  }
}

void TemplateAssembler::UpdateGlobalPropsWithDefaultProps() {
  if (page_proxy_.HasSSRRadonPage() &&
      !page_proxy_.GetDefaultGlobalProps().IsEmpty()) {
    if (global_props_.IsNil()) {
      UpdateGlobalProps(page_proxy_.GetDefaultGlobalProps());
    } else {
      for (const auto& [key, value] :
           *(page_proxy_.GetDefaultGlobalProps().Table())) {
        if (global_props_.GetProperty(key).IsEmpty()) {
          global_props_.SetProperty(key, value);
        }
      }
      UpdateGlobalProps(global_props_);
    }
  }
}

void TemplateAssembler::SetGlobalDataToContext(
    lepus::Context* context, const lepus::Value& global_props) {
  // In fiber mode, set globalData to context. Such that fe global variable can
  // get native data with this globalData.
  if (!page_config_ || !page_config_->GetEnableFiberArch()) {
    return;
  }

  constexpr const static char* kGlobalLynx = "lynx";
  lepus::Value global_lynx = lepus::Value(lepus::Dictionary::Create());
  global_lynx.SetProperty(kGlobalPropsKey, global_props);
  global_lynx.SetProperty(kSystemInfo, GenerateSystemInfo(nullptr));
  context->SetGlobalData(kGlobalLynx, global_lynx);
}

bool TemplateAssembler::OnLoadTemplate(
    const std::shared_ptr<TemplateData>& template_data) {
  // timing actions
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LOAD_TEMPLATE_START);

  // print log
  LOGI("start TemplateAssembler::LoadTemplate, url:"
       << url_ << " len: " << source_size_ << " this:" << this);

  // ssr timing actions
  if (page_proxy_.HasSSRRadonPage()) {
    PerfCollector::GetInstance().setHydrating(trace_id_);
  }

  // record source size
  PerfCollector::GetInstance().InsertDouble(
      trace_id_, PerfCollector::Perf::SOURCE_JS, source_size_);

  // check if is_loading_template_ == true, report error
  if (is_loading_template_) {
    ReportError(LYNX_ERROR_CODE_LOAD_TEMPLATE,
                "LoadTemplate in another loading process!!!");
    return false;
  }
  is_loading_template_ = true;

  // Before template load start, update global props
  UpdateGlobalPropsWithDefaultProps();

  // timing actions
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::FIRST_PAGE_LAYOUT);
  PerfCollector::GetInstance().StartRecord(trace_id_, PerfCollector::Perf::TTI);
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::TASM_FINISH_LOAD_TEMPLATE);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_TEMPLATE_START);

  actual_fmp_start_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                          std::chrono::system_clock::now().time_since_epoch())
                          .count();
  return true;
}

void TemplateAssembler::OnDecodeTemplate() {
  // timing actions
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::TASM_BINARY_DECODE);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::DECODE_BINARY_START);
  tasm::TimingCollector::Instance()->Mark(tasm::TimingKey::SETUP_DECODE_START);
}

void TemplateAssembler::DidDecodeTemplate(bool post_js) {
  if (component_loader_) {
    component_loader_->SetEnableLynxResourceService(
        page_config_->GetEnableLynxResourceServiceProvider());
  }

  // Ensure that only one page config is set.
  if (!page_proxy_.HasSSRRadonPage()) {
    SetPageConfigClient();
  }

  if (post_js) {
    OnJSPrepared(url_);
  }

  // if using leousNG, set gc threshold.
  if (page_config_->GetEnableLepusNG()) {
    FindEntry(tasm::DEFAULT_ENTRY_NAME)
        ->GetVm()
        ->SetGCThreshold(page_config_->GetLepusGCThreshold());
  }

  // timing actions
  tasm::TimingCollector::Instance()->Mark(tasm::TimingKey::SETUP_DECODE_END);

  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::TASM_BINARY_DECODE);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::DECODE_BINARY_END,
      PerfCollector::PerfStamp::RENDER_TEMPLATE_START);
}

void TemplateAssembler::OnVMExecute(lepus::Context* context) {
  // register global props and SystemInfo to context.
  SetGlobalDataToContext(context, global_props_);

  // timing actions
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::TASM_END_DECODE_FINISH_LOAD_TEMPLATE);
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LEPUS_EXECUTE_START);
}

void TemplateAssembler::DidVMExecute() {
  // timing actions
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LEPUS_EXECUTE_END);

  // Radon info can be know only after Vm->Execute()
  SetPageConfigRadonMode();

  // Ensure that only one page config is set
  if (!page_proxy_.HasSSRRadonPage()) {
    OnPageConfigDecoded(page_config_);
  }
}

/**
 * The purpose of this function is to merge cache_data into init data when
 * loadTemplate. There are two requirements:
 * 1. The merge must be done in the order of the input data.
 * 2. Different template_data may have different processors and must be handled
 * separately, but submitting to Lepus is a time-consuming process.
 * Therefore, the final decision is: Merge adjacent template_data that hold the
 * same processor, and then submit it to Lepus in order.
 */
bool TemplateAssembler::ProcessInitData(
    const std::shared_ptr<TemplateData>& init_template_data,
    lepus::Value& result) {
  // early return if there is no cache data
  if (cache_data_.empty()) {
    return ProcessTemplateData(init_template_data, result, true);
  }

  bool read_only = true;
  result = lepus::Value::CreateObject();
  bool handle_template_data = false;

  /**
   * data with the same processor will be merged firstly, and then processed by
   * lepus. Return whether input template_data could be early merged.
   */
  auto early_merge = [&read_only](auto& dict, const auto& template_data,
                                  const std::string& processor_name) -> bool {
    if (!template_data) {
      return true;
    }
    if (template_data->PreprocessorName() == processor_name) {
      read_only = read_only && template_data->IsReadOnly();
      lepus::Value::MergeValue(dict, template_data->GetValue());
      return true;
    }
    return false;
  };

  /**
   * data with the different processors will be processed firstly, and then
   * merged with init_data
   */
  auto process_and_merge = [&result, this](const auto& templated_data,
                                           bool is_first_screen) {
    auto data = lepus::Value();
    this->ProcessTemplateData(templated_data, data, is_first_screen);
    lepus::Value::MergeValue(result, data);
  };

  /**
   * adjacent data with the same processor can be put together and handed over
   * to lepus for processing, which can save a lot of time
   */
  for (auto cache = cache_data_.begin(); cache != cache_data_.end();) {
    const std::string& processor_name = (*cache)->PreprocessorName();
    auto dict = lepus::Value(lepus::Dictionary::Create());

    // merge adjacent data with the same processor
    while (cache != cache_data_.end() &&
           early_merge(dict, *cache, processor_name)) {
      ++cache;
    }

    // if the iteration is complete, try to merge with init template_data
    if (cache == cache_data_.end()) {
      handle_template_data =
          early_merge(dict, init_template_data, processor_name);
    }

    // submit to lepus engine
    process_and_merge(
        std::make_shared<TemplateData>(dict, false, processor_name),
        handle_template_data);
  }

  // if init template_data has not been processed, that is, template_data has a
  // different processor from the previous data, it is processed separately
  if (!handle_template_data) {
    read_only = read_only && init_template_data->IsReadOnly();
    process_and_merge(init_template_data, true);
  }

  return read_only;
}

lepus::Value TemplateAssembler::OnRenderTemplate(
    const std::shared_ptr<TemplateData>& template_data,
    const std::shared_ptr<TemplateEntry>& card, bool post_js) {
  // If global_props_ not nil, update global_props_ to page_proxy_.
  if (!global_props_.IsNil()) {
    page_proxy_.UpdateGlobalProps(global_props_, false);
  }

  // Get init data. If init data not empty, set init data to template entry.
  lepus::Value data;
  bool read_only = ProcessInitData(template_data, data);

  // If data is not empty, set data to card's init data.
  // If data is empty, let data be dict to call
  // page_proxy_.UpdateInLoadTemplate.
  if (!data.IsEmpty()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "card->SetInitData");
    if (!EnableLynxAir()) {
      card->SetInitData(data, read_only && !UseLepusNG());
    }
  } else {
    data = lepus::Value(lepus::Dictionary::Create());
  }

  // Before render element, execute screen metrics override.
  page_proxy_.ExecuteScreenMetricsOverrideWhenTemplateIsLoaded();

  // If need post js, call OnJSPrepared.
  if (post_js) {
    OnJSPrepared(url_);
  }

  return data;
}

void TemplateAssembler::RenderTemplate(
    const std::shared_ptr<TemplateEntry>& card, lepus::Value& data) {
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    RenderTemplateForFiber(card, data);
  } else if (EnableLynxAir()) {
    RenderTemplateForAir(card, data);
  } else {
    page_proxy_.UpdateInLoadTemplate(data);
  }
}

void TemplateAssembler::UpdateTemplate(
    const lepus::Value& data, const UpdatePageOption& update_page_option) {
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    constexpr const static char* kUpdatePage = "updatePage";
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_LEPUS_UPDATE_PAGE_START);
    FindEntry(tasm::DEFAULT_ENTRY_NAME)
        ->GetVm()
        ->Call(kUpdatePage, {data, update_page_option.ToLepusValue()});
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_LEPUS_UPDATE_PAGE_END);
  } else {
    if (UpdateGlobalDataInternal(data, update_page_option)) {
      delegate_.OnDataUpdated();
    }
  }
}

void TemplateAssembler::RenderTemplateForFiber(
    const std::shared_ptr<TemplateEntry>& card, const lepus::Value& data) {
  constexpr const static char* kRenderPage = "renderPage";
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_CREATE_VDOM_START);
  card->GetVm()->Call(kRenderPage, {data});
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_CREATE_VDOM_END);
  PipelineOptions options;
  options.has_patched = true;
  options.is_first_screen = true;
  page_proxy()
      ->element_manager()
      ->painting_context()
      ->MarkUIOperationQueueFlushTiming(
          tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_START, "");
  page_proxy()->element_manager()->OnPatchFinishForFiber(options);
}

void TemplateAssembler::RenderTemplateForAir(
    const std::shared_ptr<TemplateEntry>& card, const lepus::Value& data) {
#if ENABLE_AIR
  const auto page_ptr = AirLepusRef::Create(
      page_proxy()->element_manager()->air_node_manager()->Get(
          page_proxy()->element_manager()->AirRoot()->impl_id()));
  UpdatePageOption update_options;
  update_options.update_first_time = true;
  page_proxy()->element_manager()->AirRoot()->UpdatePageData(data,
                                                             update_options);
  page_proxy()
      ->element_manager()
      ->painting_context()
      ->MarkUIOperationQueueFlushTiming(
          tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_START, "");

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_RENDER_PAGE_START_AIR);

  if (card->compile_options().radon_mode_ ==
      CompileOptionRadonMode::RADON_MODE_RADON) {
    lepus::Value p1(page_ptr);
    card->GetVm()->Call("$createPage0", {p1});
    card->GetVm()->Call("$updatePage0", {p1});
  } else {
    std::vector<lepus::Value> params;
    params.emplace_back(lepus::Value(page_ptr));
    params.emplace_back(lepus::Value(true));
    params.emplace_back(
        lepus::Value(page_proxy()->element_manager()->AirRoot()->GetData()));
    lepus::Value ret = card->GetVm()->Call("$renderPage0", params);
    // In some cases, some element may fail to execute the flush operation due
    // to exceptions in the execution of lepus code. As a result, layout and
    // other operations are not necessary.
    bool lepus_success = ret.IsBool() && ret.Bool();
    if (!lepus_success) {
      return;
    }
  }
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_RENDER_PAGE_END_AIR);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_VITALS, "OnPatchFinishInnerForAir");
  PipelineOptions options;
  options.is_first_screen = true;
  // trigger onTimingSetup
  options.has_patched = true;
  EnsureAirTouchEventHandler();
  page_proxy()->element_manager()->OnPatchFinishInnerForAir(options);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
#endif
}

void TemplateAssembler::DidRenderTemplate() {
  // ssr actions
  if (page_proxy_.HasSSRRadonPage()) {
    page_proxy_.HydrateOnFirstScreenIfPossible();
    delegate_.OnSSRHydrateFinished(url_);
  }

  // timing actions
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::RENDER_TEMPLATE_END);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_TEMPLATE_END);
  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::TASM_END_DECODE_FINISH_LOAD_TEMPLATE);
  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::TASM_FINISH_LOAD_TEMPLATE);

  // reset flag
  template_loaded_ = true;
}

void TemplateAssembler::DidLoadTemplate() {
  // exec callback
  delegate_.OnNativeAppReady();
  delegate_.OnTemplateLoaded(url_);
  SendFontScaleChanged(font_scale_);
  delegate_.OnTasmFinishByNative();

  // reset flag
  is_loading_template_ = false;

  // print log
  LOGI("end TemplateAssembler::LoadTemplate, url:" << url_
                                                   << " len: " << source_size_);

  // timing actions
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LOAD_TEMPLATE_END);
}

void TemplateAssembler::LoadTemplateBundle(
    const std::string& url, LynxTemplateBundle template_bundle,
    const std::shared_ptr<TemplateData>& template_data) {
  // TODO (nihao.royal) add testbench for LoadTemplateBundle.
  source_size_ = template_bundle.total_size_;
  url_ = url;
  LoadTemplateInternal(
      url, template_data,
      [this, template_bundle = std::move(template_bundle)](
          const std::shared_ptr<TemplateEntry>& card_entry) mutable {
        return card_entry->InitWithTemplateBundle(shared_from_this(),
                                                  std::move(template_bundle));
      });
  ClearCacheData();
}

void TemplateAssembler::LoadTemplate(
    const std::string& url, std::vector<uint8_t> source,
    const std::shared_ptr<TemplateData>& template_data) {
#if ENABLE_ARK_RECORDER
  // test-bench actions
  tasm::recorder::TemplateAssemblerRecorder::RecordLoadTemplate(
      url, source, template_data, record_id_);
  auto& client = page_proxy_.element_manager();
  if (client != nullptr) {
    client->SetRecordId(record_id_);
  }
#endif
  source_size_ = source.size();
  url_ = url;
  LoadTemplateInternal(
      url, template_data,
      [this, source = std::move(source)](
          const std::shared_ptr<TemplateEntry>& card_entry) mutable {
        return FromBinary(card_entry, std::move(source));
      });
  ClearCacheData();
}

// LoadTemplate function will execute the following functions in sequence
// 1. OnLoadTemplate
// 2. OnDecodeTemplate
// 3. Decode
// 4. DidDecodeTemplate
// 5. OnVMExecute
// 6. VMExecute
// 7. DidVMExecute
// 8. OnRenderTemplate
// 9. RenderTemplate
// 10. DidRenderTemplate
// 11. DidLoadTemplate
void TemplateAssembler::LoadTemplateInternal(
    const std::string& url, const std::shared_ptr<TemplateData>& template_data,
    base::MoveOnlyClosure<bool, const std::shared_ptr<TemplateEntry>&>
        entry_initializer) {
  // Trace LoadTemplate
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_LOAD_TEMPLATE,
              [&url](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("url");
                debug->set_string_value(url);
              });

  Scope scope(this);

  // Before exec load template, do some preparation
  // 1. exec timing actions
  // 2. exec test-bench actions
  // 3. print log
  // 4. update global props
  if (!OnLoadTemplate(template_data)) {
    LOGE("OnLoadTemplate check failed");
    return;
  }

  // Get page template entry
  auto card = FindEntry(DEFAULT_ENTRY_NAME);

  // In radon/radon-diff mode, if template_data == nullptr &&
  // global_props_.IsNil() && page_proxy_.GetDefaultPageData().IsEmpty(), the
  // data processor will not be executed. Thus, in this case, Card's init data
  // must be nil. JS source can be posted to JS before vm's execution.
  bool js_posted_before_vm = template_data == nullptr &&
                             global_props_.IsNil() &&
                             page_proxy_.GetDefaultPageData().IsEmpty();
  {
    // Trace Decode
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_DECODE);

    // Before exec decode template, do some preparation. Only timing actions
    // now.
    OnDecodeTemplate();

    if (!entry_initializer(card)) {
      LOGE("Decoding template failed");
      return;
    }

    // After decode template, exec some aftercare
    // 1. ssr actions
    // 2. if need js_posted_before_vm, post js(if in air strict mode, js rntime
    // is not enabled, no need to post js)
    // 3. timing actions
    DidDecodeTemplate(js_posted_before_vm && !EnableLynxAir());
  }

  {
    // Trace VM Execute
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_VM_EXECUTE);

    // Before vm execute template, do some preparation. Only timing actions now.
    OnVMExecute(card->GetVm().get());

    // Get VM & exec VM.
    if (!card->GetVm()->Execute()) {
      ReportError(LYNX_ERROR_CODE_LOAD_TEMPLATE, "vm execute failed");
      return;
    }

    // After VM Execute, exec some aftercare
    // 1. timing actions
    // 2. set radon info
    // 3. ssr actions
    DidVMExecute();
  }

  {
    // Trace DOM ready
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_DOM_READY);

    // Before render template, do some preparation.
    // 1. update global props if needed
    // 2. get init data to render template
    // 3. execute screen metrics override
    // 4. post js if needed(if in air strict mode, js rntime is not enabled, no
    // need to post js)
    auto data = OnRenderTemplate(template_data, card,
                                 !js_posted_before_vm && !EnableLynxAir());

    // render template
    RenderTemplate(card, data);

    // After render template, exec some aftercare
    // 1. ssr actions
    // 2. timing actions
    // 3. reset flag
    DidRenderTemplate();
  }
  // After load template, exec some aftercare
  // 1. exec callback
  // 2. print log
  // 3. reset flag
  // 4. timing actions
  DidLoadTemplate();
}

void TemplateAssembler::ReloadTemplate(
    const std::shared_ptr<TemplateData>& template_data,
    UpdatePageOption& update_page_option) {
#if ENABLE_ARK_RECORDER
  // test-bench actions
  tasm::recorder::TemplateAssemblerRecorder::RecordReloadTemplate(template_data,
                                                                  record_id_);
#endif
  Scope scope(this);
  if (is_loading_template_) {
    ReportError(LYNX_ERROR_CODE_LOAD_TEMPLATE,
                "ReloadTemplate in another loading process!!!");
    return;
  }
  // print log
  LOGI("start TemplateAssembler::ReloadTemplate, url:"
       << url_ << " len: " << source_size_ << " this:" << this);

  is_loading_template_ = true;
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_RELOAD_TEMPLATE,
              [&](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("url");
                debug->set_string_value(url_);
              });
  // Befor template load start.
  UpdateGlobalPropsWithDefaultProps();
  auto card = FindEntry(DEFAULT_ENTRY_NAME);
  if (card && card->GetVm()) {
    card->GetVm()->CleanClosuresInCycleReference();
  }
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::FIRST_PAGE_LAYOUT);
  PerfCollector::GetInstance().StartRecord(trace_id_, PerfCollector::Perf::TTI);

  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::TASM_FINISH_LOAD_TEMPLATE);

  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_TEMPLATE_START);
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LOAD_TEMPLATE_START);

  // actual_fmp_start_ and actual_fmp_end_ should be reset.
  actual_fmp_start_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                          std::chrono::system_clock::now().time_since_epoch())
                          .count();
  actual_fmp_end_ = 0;

  // No need to decode and set page config here.

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_DOM_READY);

  lepus::Value data;
  bool read_only = ProcessTemplateData(template_data, data, true);

  // destroy old components
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    if (card && card->GetVm()) {
      constexpr const static char* kRemoveComponents = "removeComponents";
      card->GetVm()->Call(kRemoveComponents, {});
    }
  } else {
    page_proxy_.RemoveOldComponentBeforeReload();
  }

  // destroy card and create card
  read_only = read_only && !UseLepusNG();
  delegate_.OnJSAppReload(read_only ? data : lepus::Value::ShallowCopy(data));

  // update data
  update_page_option.from_native = true;
  update_page_option.reload_template = true;

  if (page_config_ && page_config_->GetEnableFiberArch()) {
    if (card && card->GetVm()) {
      constexpr const static char* kUpdatePage = "updatePage";
      card->GetVm()->Call(kUpdatePage,
                          {data, update_page_option.ToLepusValue()});
    }
  } else {
    UpdateGlobalDataInternal(data, update_page_option);
  }

  // Here no need to call delegate_.OnDataUpdated();
  // Because this update is like a new template loaded, but not a update.

  if (page_proxy_.HasSSRRadonPage()) {
    page_proxy_.HydrateOnFirstScreenIfPossible();
    delegate_.OnSSRHydrateFinished(url_);
  }
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LOAD_TEMPLATE_END);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::RENDER_TEMPLATE_END);

  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_TEMPLATE_END);

  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::TASM_END_DECODE_FINISH_LOAD_TEMPLATE);

  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::TASM_FINISH_LOAD_TEMPLATE);
  template_loaded_ = true;
  if (!card->GetName().empty()) {
    delegate_.OnNativeAppReady();
  }

  delegate_.OnTemplateLoaded(url_);
  SendFontScaleChanged(font_scale_);
  delegate_.OnTasmFinishByNative();
  is_loading_template_ = false;
  LOGI("end TemplateAssembler::ReloadTemplate");
}

void TemplateAssembler::ReloadTemplate(
    const std::shared_ptr<TemplateData>& template_data,
    const lepus::Value& global_props, UpdatePageOption& update_page_option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS,
              LYNX_TRACE_EVENT_RELOAD_TEMPLATE_WITH_GLOBAL_PROPS);
  if (!global_props.IsNil()) {
    UpdateGlobalProps(global_props, false);
  }
  ReloadTemplate(template_data, update_page_option);
}

void TemplateAssembler::ReloadFromJS(const runtime::UpdateDataTask& task) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_RELOAD_FROM_JS);
  Scope scope(this);
  LOGI("Lynx ReloadFromJS. url: " << url_);

  // get default entry
  const auto& card = FindEntry(tasm::DEFAULT_ENTRY_NAME);
  if (card && card->GetVm()) {
    card->GetVm()->CleanClosuresInCycleReference();
  }

  // destroy old components
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    if (card && card->GetVm()) {
      card->GetVm()->Call(kRemoveComponents, {});
    }
  } else {
    // trigger old components's unmount lifecycle;
    page_proxy_.RemoveOldComponentBeforeReload();
  }

  // destroy card and create card instance
  delegate_.OnJSAppReload(lepus::Value::ShallowCopy(task.data_));

  UpdatePageOption update_page_option;
  update_page_option.reload_from_js = true;
  update_page_option.reload_template = true;

  // update template
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    if (card && card->GetVm()) {
      card->GetVm()->Call(kUpdatePage,
                          {task.data_, update_page_option.ToLepusValue()});
    }
  } else {
    UpdateGlobalDataInternal(task.data_, update_page_option);
  }

  SendFontScaleChanged(font_scale_);
}

void TemplateAssembler::LoadComponentWithCallback(const std::string& url,
                                                  std::vector<uint8_t> source,
                                                  bool sync,
                                                  int32_t callback_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_LOAD_COMPONENT,
              [sync, url](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("LoadComponentWithCallback");
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("sync");
                debug->set_string_value(std::to_string(sync));
                auto* url_debug = ctx.event()->add_debug_annotations();
                url_debug->set_name("url");
                url_debug->set_string_value(url);
              });
#if ENABLE_ARK_RECORDER
  tasm::recorder::TemplateAssemblerRecorder::RecordLoadComponentWithCallback(
      url, source, sync, callback_id, record_id_);
#endif  // ENABLE_ARK_RECORDER
  LOGI("TemplateAssembler::LoadComponentWithCallback: "
       << url << " sync: " << sync << " callback_id: " << callback_id);
  PerfCollector::GetInstance().RecordDynamicComponentRequireMode(trace_id_, url,
                                                                 sync);
  PerfCollector::GetInstance().RecordDynamicComponentBinarySize(trace_id_, url,
                                                                source.size());

  std::shared_ptr<TemplateEntry> component_entry = FindTemplateEntry(url);
  if (!component_entry) {
    // if the dynamic component is first loaded, then need to build
    // templateEntry for it.
    // If returns null, this means the decoding or executing of the dynamic
    // component is failed.
    component_entry = BuildComponentEntryInternal(
        url,
        [this, &url,
         &source](const std::shared_ptr<TemplateEntry>& entry) -> bool {
          // Mark DynamicComponent Begin Decode.
          PerfCollector::GetInstance().StartRecordDynamicComponentPerf(
              this->trace_id_, url,
              PerfCollector::DynamicComponentPerfTag::
                  DYNAMIC_COMPONENT_DECODE_TIME);

          if (!this->FromBinary(entry, std::move(source), false)) {
            return false;
          }

          // Mark DynamicComponent End Decode.
          PerfCollector::GetInstance().EndRecordDynamicComponentPerf(
              this->trace_id_, url,
              PerfCollector::DynamicComponentPerfTag::
                  DYNAMIC_COMPONENT_DECODE_TIME);

          return true;
        });
  }

  lepus::Value callback_msg;
  if (component_entry) {
    // decode success
    callback_msg = RadonDynamicComponent::ConstructSuccessLoadInfo(url, false);
  } else {
    // decode fail
    std::string err_msg = ConstructDecodeErrorMessage(false, url);

    callback_msg = RadonDynamicComponent::ConstructFailLoadInfo(
        url, LYNX_ERROR_CODE_DYNAMIC_COMPONENT_DECODE_FAIL, err_msg);

    if (callback_id < 0) {
      // trigger dynamic component event
      TriggerDynamicComponentEvent(
          RadonDynamicComponent::ConstructErrMsg(
              url, LYNX_ERROR_CODE_DYNAMIC_COMPONENT_DECODE_FAIL, err_msg,
              sync),
          sync, component_loader_->GetRequiringComponent(),
          [self = this, &url,
           &loader = component_loader_](const lepus::Value& msg) {
            self->SendDynamicComponentEvent(url, msg,
                                            loader->GetRequireList(url));
          });
    }
  }

  InvokeLoadComponentCallback(callback_id, callback_msg);
  // if async loaded and callback_id is -1, which means the component is loaded
  // async and needs to be rendered.
  bool need_render = !sync && callback_id < 0;
  DidComponentLoaded(component_entry, url, need_render);
}

void TemplateAssembler::InvokeLoadComponentCallback(int32_t callback_id,
                                                    const lepus::Value& value) {
  if (callback_id >= 0) {
    delegate_.CallJSApiCallbackWithValue(piper::ApiCallBack(callback_id),
                                         value);
  }
}

void TemplateAssembler::DidComponentLoaded(
    const std::shared_ptr<TemplateEntry>& component_entry,
    const std::string& url, bool need_render) {
  bool is_fiber = page_config_->GetEnableFiberArch();
  if (is_fiber) {
    // Fiber does nothing now.
    return;
  }
  if (component_entry != nullptr) {
    component_entry->GetVm()->UpdateTopLevelVariable(kGlobalPropsKey,
                                                     global_props_);
    component_entry->GetVm()->UpdateTopLevelVariable(
        kSystemInfo, GenerateSystemInfo(nullptr));
    if (need_render && component_entry->NeedAsyncRender()) {
      if (!component_loader_) {
        ReportError(LYNX_ERROR_CODE_DYNAMIC_COMPONENT_LOAD_FAIL,
                    "component loader missing");
        return;
      }
      page_proxy()->ForceUpdateInLoadDynamicComponent(
          url, this, component_loader_->GetRequireList(url));
      component_entry->MarkAsyncRendered();
      page_proxy()->element_manager()->painting_context()->Flush();
    }
  }
}

std::shared_ptr<TemplateEntry> TemplateAssembler::BuildComponentEntryInternal(
    const std::string& url,
    const base::MoveOnlyClosure<bool, const std::shared_ptr<TemplateEntry>&>&
        entry_initializer) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_BUILD_ENTRY);
  std::shared_ptr<TemplateEntry> component_entry =
      std::make_shared<TemplateEntry>();
  component_entry->SetIsCard(false);
  component_entry->SetName(url);
  if (!entry_initializer(component_entry)) {
    return nullptr;
  }

  // Check whether the dynamic component is compatible with the page. When
  // the dsl of the dynamic component is different with the dsl of the page,
  // or the mode of the dynamic component is different with the mode of the
  // page, an error will be reported.
  std::string error;
  if (!component_entry->IsCompatibleWithRootEntry(
          *(FindEntry(DEFAULT_ENTRY_NAME)), error)) {
    LOGE(
        "DynamicComponent is incompatible with Root Page, DynamicComponent's "
        "url is: "
        << url);
    ReportError(LYNX_ERROR_CODE_DYNAMIC_COMPONENT_LOAD_FAIL, error);
    return nullptr;
  }

  template_entries_.insert({url, component_entry});
  if (!component_entry->GetVm()) {
    LOGE("DynamicComponent's context is null, url is: " << url);
    return nullptr;
  }
  vm_to_template_entry_.insert(
      {component_entry->GetVm().get(), component_entry.get()});

  OnDynamicJSSourcePrepared(url);
  if (!component_entry->Execute()) {
    ReportError(LYNX_ERROR_CODE_DYNAMIC_COMPONENT_LOAD_FAIL,
                "vm execute failed");
    return nullptr;
  }

  return component_entry;
}

void TemplateAssembler::SetPageConfigRadonMode() const {
  if (!page_config_) {
    return;
  }
  if (page_proxy_.IsRadonDiff()) {
    page_config_->SetRadonMode("RadonDiff");
  } else {
    page_config_->SetRadonMode("Radon");
  }
}

void TemplateAssembler::SetPageConfig(
    const std::shared_ptr<PageConfig>& config) {
  if (config) {
    page_config_ = config;
    // the remove_css_parser_log has been updated in DecodeHeader, should not be
    // updated here, so we need to skip this swich.
    auto parser_config = config->GetCSSParserConfigs();
    page_config_->SetCSSParserConfigs(parser_config);
    // pass page config to android/iOS side after VM->Execute()
    // see `SetPageConfig` called by `LoadTemplate/LoadComponent`
    // in template_assembler.cc
  }
}

void TemplateAssembler::ReportError(int32_t error_code,
                                    const std::string& msg) {
  if (!msg.empty()) {
    delegate_.OnErrorOccurred(error_code, msg);
  }
}

// call JS function to format error message and report
void TemplateAssembler::ReportLepusNGError(int32_t error_code,
                                           const std::string& msg) {
  if (msg.empty()) {
    return;
  }
  auto arguments = lepus::CArray::Create();
  arguments->push_back(lepus_value(lepus::StringImpl::Create(msg)));
  arguments->push_back(lepus::Value(error_code));
  delegate_.CallJSFunction(kReporter, kSendError, lepus::Value(arguments));
}

void TemplateAssembler::SetSourceMapRelease(
    const lepus::Value& source_map_release) {
  if (!(source_map_release.GetProperty("name").IsString())) {
    LOGI(
        "TemplateAssembler::SetSourceMapRelease, can't found Error, name is "
        "undefined");
    return;
  }
  if (!(source_map_release.GetProperty("stack").IsString())) {
    LOGI(
        "TemplateAssembler::SetSourceMapRelease, can't found Error, stack is "
        "undefined");
    return;
  }
  if (!(source_map_release.GetProperty("message").IsString())) {
    LOGI(
        "TemplateAssembler::SetSourceMapRelease, can't found Error, message is "
        "undefined");
    return;
  }

  // because "stack", "name", "message" is stored in prototype of Error Object,
  // so we must get value and put it into lepus value manually
  auto error_obj = lepus::Value(lepus::Dictionary::Create());
  error_obj.SetProperty(lepus::String("stack"),
                        lepus_value(source_map_release.GetProperty("stack")));
  error_obj.SetProperty(lepus::String("name"),
                        lepus_value(source_map_release.GetProperty("name")));
  error_obj.SetProperty(lepus::String("message"),
                        lepus_value(source_map_release.GetProperty("message")));
  auto arguments = lepus::CArray::Create();
  arguments->push_back(error_obj);
  delegate_.CallJSFunction("Reporter", "setSourceMapRelease",
                           lepus::Value(arguments));
}

std::unique_ptr<lepus::Value> TemplateAssembler::GetCurrentData() {
  // If enbale fiber arch, get data from lepus runtime, otherwise, get data from
  // page_proxy.
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    auto default_entry = FindEntry(tasm::DEFAULT_ENTRY_NAME);
    if (default_entry && default_entry->GetVm()) {
      // If getCurrentData is executed, call the getPageData function of
      // LepusRuntime without passing any parameters to get all data from the
      // page.
      return std::make_unique<lepus::Value>(
          lepus::Value::Clone(default_entry->GetVm()->Call(kGetPageData, {})));
    }
    return nullptr;
  }
  return page_proxy()->GetData();
}

lepus::Value TemplateAssembler::GetPageDataByKey(
    const std::vector<std::string>& keys) {
  // If enbale fiber arch, get data from lepus runtime, otherwise, get data from
  // page_proxy.
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    auto default_entry = FindEntry(tasm::DEFAULT_ENTRY_NAME);
    if (default_entry && default_entry->GetVm()) {
      // When executing getPageDataByKey, still call the getPageData function of
      // LepusRuntime, but pass in the keys converted to lepus::Array as a
      // parameter to obtain the data corresponding to these keys.
      auto ary = lepus::CArray::Create();
      for (const auto& key : keys) {
        ary->push_back(lepus::Value(key));
      }
      return lepus::Value::Clone(
          default_entry->GetVm()->Call(kGetPageData, {lepus::Value(ary)}));
    }
    return lepus::Value();
  }
  return page_proxy()->GetDataByKey(keys);
}

void TemplateAssembler::UpdateComponentData(
    const runtime::UpdateDataTask& task) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_UPDATE_COMPONENT_DATA_BY_JS,
              [update_data_type = static_cast<uint32_t>(task.type_)](
                  lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("update_data_type");
                debug->set_string_value(std::to_string(update_data_type));
              });
  Scope scope(this);
  LOGI("TemplateAssembler::UpdateComponentData. this:"
       << this << " url:" << url_
       << " update_data_type:" << static_cast<uint32_t>(task.type_));
  lepus_value v = task.data_.GetProperty(k_actual_first_screen);
  if (v.IsTrue()) {
    PerfCollector::GetInstance().StartRecord(trace_id_,
                                             PerfCollector::Perf::RENDER_PAGE);
    PerfCollector::GetInstance().StartRecord(
        trace_id_, PerfCollector::Perf::DIFF_SAME_ROOT);
    PerfCollector::GetInstance().RecordPerfTime(
        trace_id_, PerfCollector::PerfStamp::UPDATE_PAGE_START);
    page_proxy_.UpdateComponentData(task.component_id_, task.data_);

    PerfCollector::GetInstance().EndRecord(trace_id_,
                                           PerfCollector::Perf::DIFF_SAME_ROOT);
    if (actual_fmp_end_ == 0) {
      actual_fmp_end_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::system_clock::now().time_since_epoch())
                            .count();
    }
    PerfCollector::GetInstance().RecordPerfTime(
        trace_id_, PerfCollector::PerfStamp::UPDATE_PAGE_END);
    PerfCollector::GetInstance().EndRecord(trace_id_,
                                           PerfCollector::Perf::RENDER_PAGE);
  } else {
    page_proxy_.UpdateComponentData(task.component_id_, task.data_);
  }

  delegate_.CallJSApiCallback(task.callback_);
}

void TemplateAssembler::SelectComponent(const std::string& component_id,
                                        const std::string& id_selector,
                                        const bool single,
                                        piper::ApiCallBack callback) {
  std::vector<std::string> target_comp_ids =
      page_proxy_.SelectComponent(component_id, id_selector, single);
  auto array = lepus::CArray::Create();
  for (const auto& comp_id : target_comp_ids) {
    array->push_back(lepus::Value(lepus::StringImpl::Create(comp_id)));
  }
  delegate_.CallJSApiCallbackWithValue(callback, lepus::Value(array));
}

void TemplateAssembler::ElementAnimate(const std::string& component_id,
                                       const std::string& id_selector,
                                       const lepus::Value& args) {
  NodeSelectRoot root = NodeSelectRoot::ByComponentId(component_id);
  NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                            id_selector);
  options.only_current_component = false;
  auto elements = page_proxy_.SelectElements(root, options);
  if (elements.empty() || elements[0] == nullptr) {
    return;
  }
  elements[0]->Animate(args);
}

void TemplateAssembler::GetComponentContextDataAsync(
    const std::string& component_id, const std::string& key,
    piper::ApiCallBack callback) {
  lepus::Value ctx_value =
      page_proxy_.GetComponentContextDataByKey(component_id, key);
  delegate_.CallJSApiCallbackWithValue(callback, ctx_value);
}

lepus::Value TemplateAssembler::TriggerLepusBridge(
    const std::string& method_name, const lepus::Value& msg) {
  LOGV("LepusLynx TriggerLepusBridge triggered in template assembler"
       << method_name << " this:" << this);
  return delegate_.TriggerLepusMethod(method_name, msg);
}

void TemplateAssembler::TriggerLepusBridgeAsync(const std::string& method_name,
                                                const lepus::Value& arguments) {
  LOGV("LepusLynx TriggerLepusBridge Async triggered in template assembler"
       << method_name << " this:" << this);
  delegate_.TriggerLepusMethodAsync(method_name, arguments);
}

void TemplateAssembler::InvokeLepusCallback(const int32_t callback_id,
                                            const std::string& entry_name,
                                            const lepus::Value& data) {
  const auto& current_entry = FindEntry(entry_name);
  current_entry->InvokeLepusBridge(callback_id, data);
}

void TemplateAssembler::InvokeLepusComponentCallback(
    const int64_t callback_id, const std::string& entry_name,
    const lepus::Value& data) {
  touch_event_handler_->HandleJSCallbackLepusEvent(callback_id, this, data);
}

void TemplateAssembler::TriggerComponentEvent(const std::string& event_name,
                                              const lepus::Value& msg) {
  if (!template_loaded_) {
    return;
  }
  if (!EnableLynxAir()) {
    EnsureTouchEventHandler();
    touch_event_handler_->HandleTriggerComponentEvent(this, event_name, msg);
  }
#if ENABLE_AIR
  else {
    EnsureAirTouchEventHandler();
    air_touch_event_handler_->TriggerComponentEvent(this, event_name, msg);
  }
#endif
}

void TemplateAssembler::CallJSFunctionInLepusEvent(const int64_t component_id,
                                                   const std::string& name,
                                                   const lepus::Value& params) {
  if (!template_loaded_) {
    return;
  }
  EnsureTouchEventHandler();
  touch_event_handler_->CallJSFunctionInLepusEvent(component_id, name, params);
}

void TemplateAssembler::TriggerLepusGlobalEvent(const std::string& event_name,
                                                const lepus::Value& msg) {
  if (!template_loaded_) {
    return;
  }
  SendGlobalEventToLepus(event_name, std::move(msg));
  LOGI("TemplateAssembler TriggerLepusGlobalEvent event" << event_name
                                                         << " this:" << this);
}

void TemplateAssembler::TriggerWorkletFunction(std::string component_id,
                                               std::string worklet_module_name,
                                               std::string method_name,
                                               lepus::Value args,
                                               piper::ApiCallBack callback) {
#if ENABLE_LEPUSNG_WORKLET
  if (!template_loaded_) {
    return;
  }

  int comp_id = 0;
  BaseComponent* component;
  if (component_id.empty() || component_id == PAGE_ID) {
    component = page_proxy()->Page();
  } else if (!base::StringToInt(component_id, &comp_id, 10)) {
    ReportError(LYNX_ERROR_CODE_WORKLET_MODULE_EXCEPTION,
                "Component_id error, make sure component_id is either 'card' "
                "or of int type, now it is" +
                    component_id);
    return;
  } else {
    component = page_proxy()->ComponentWithId(comp_id);
  }
  std::optional<lepus::Value> call_result =
      worklet::LepusElement::TriggerWorkletFunction(
          this, component, worklet_module_name, method_name, args);

  if (call_result.has_value()) {
    delegate_.CallJSApiCallbackWithValue(callback, *call_result);
  }
#endif  // ENABLE_LEPUSNG_WORKLET
}

void TemplateAssembler::Destroy() {
  LOGI("TemplateAssembler::Destroy url:" << url_ << " this:" << this);
  destroyed_ = true;
  PerfCollector::GetInstance().UnRegisterReadyDelegate(trace_id_);
}

void TemplateAssembler::GetDecodedJSSource(
    std::unordered_map<std::string, std::string>& js_source) {
  for (const auto& entry : template_entries()) {
    auto& src = entry.second->GetJSSource();
    for (auto const& item : src) {
      js_source.emplace(item.first.str(), item.second.str());
    }
  }
}

const std::shared_ptr<TemplateEntry>& TemplateAssembler::FindEntry(
    const std::string& entry_name) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateAssembler::FindEntry");
  auto entry = template_entries_.find(entry_name);
  LynxFatal(entry != template_entries_.end(), LYNX_ERROR_CODE_RUNTIME_ENTRY,
            "Lynx Must registered card or component which name is:%s",
            entry_name.c_str());
  return entry->second;
}

TemplateEntry* TemplateAssembler::FindEntry(lepus::Context* context) {
  auto entry = vm_to_template_entry_.find(context);
  LynxFatal(
      entry != vm_to_template_entry_.end(), LYNX_ERROR_CODE_RUNTIME_ENTRY,
      "Lynx Must registered card or component, vm context can not be found");
  return entry->second;
}

void TemplateAssembler::SendBubbleEvent(const std::string& name, int tag,
                                        lepus::DictionaryPtr dict) {
  if (!template_loaded_) {
    LOGI("Lynx SendBubbleEvent failed, template_loaded_=false"
         << " this:" << this);
    return;
  }
  if (destroyed()) {
    LOGI("Lynx SendBubbleEvent failed, destroyed=true"
         << " this:" << this);
    return;
  }
  EnsureTouchEventHandler();

  touch_event_handler_->HandleBubbleEvent(
      this, template_entries_[DEFAULT_ENTRY_NAME]->GetName(), name, tag, dict);
}

void TemplateAssembler::SendInternalEvent(int tag, int event_id) {
  static const int NEED_VALIDATE = 0x0;
  switch (event_id) {
    case NEED_VALIDATE:
      OnNodeFailedToRender(tag);
      break;
    default:
      break;
  }
}

void TemplateAssembler::OnNodeFailedToRender(int tag) {
#if !ENABLE_CLI
  auto& client = page_proxy_.element_manager();
  if (client != nullptr) {
    client->OnNodeFailedToRender(tag);
    page_proxy_.SetInvalidated(true);
  } else {
    LOGE("client is nullptr");
  }
#endif
}

void TemplateAssembler::SendCustomEvent(std::string name, int tag,
                                        const lepus::Value& params,
                                        std::string pname) {
#if ENABLE_ARK_RECORDER
  if (page_proxy()->element_manager()->root()) {
    tasm::recorder::TemplateAssemblerRecorder::RecordCustomEvent(
        name, tag, page_proxy()->element_manager()->root()->impl_id(), params,
        pname, record_id_);
  }
#endif
  if (destroyed()) {
    LOGI("Lynx SendCustomEvent failed, destroyed=true"
         << " this:" << this);
    return;
  }
#if ENABLE_RENDERKIT
  // NOTE(hanhaoshen) Hack renderkit for x-overlay. send event to js global
  // event channel.
  auto arguments = lepus::CArray::Create();
  // name
  arguments->push_back(lepus_value(lepus::StringImpl::Create(name)));
  // params
  arguments->push_back(params);
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));
#endif
  if (!EnableLynxAir()) {
    EnsureTouchEventHandler();
    touch_event_handler_->HandleCustomEvent(this, name, tag, params, pname);
  }
#if ENABLE_AIR
  else {
    EnsureAirTouchEventHandler();
    air_touch_event_handler_->HandleCustomEvent(this, name, tag, params, pname);
  }
#endif
}

void TemplateAssembler::SendAirComponentEvent(const std::string& event_name,
                                              const int component_id,
                                              const lepus::Value& params,
                                              const std::string& param_name) {
#if ENABLE_AIR
  if (EnableLynxAir()) {
    EnsureAirTouchEventHandler();
    air_touch_event_handler_->SendComponentEvent(this, event_name, component_id,
                                                 params, param_name);
  }
#endif
}

void TemplateAssembler::OnPseudoStatusChanged(int32_t id, uint32_t pre_status,
                                              uint32_t current_status) {
  DCHECK(pre_status >= 0 &&
         pre_status <= std::numeric_limits<PseudoState>::max());
  DCHECK(current_status >= 0 &&
         current_status <= std::numeric_limits<PseudoState>::max());
  EnsureTouchEventHandler();
  touch_event_handler_->HandlePseudoStatusChanged(
      id, static_cast<PseudoState>(pre_status),
      static_cast<PseudoState>(current_status));
}

void TemplateAssembler::SendTouchEvent(std::string name, int tag, float x,
                                       float y, float client_x, float client_y,
                                       float page_x, float page_y) {
  if (!template_loaded_) {
    LOGI("Lynx SendTouchEvent failed, template_loaded_=false"
         << " this:" << this);
    return;
  }
  if (destroyed()) {
    LOGI("Lynx SendTouchEvent failed, destroyed=true"
         << " this:" << this);
    return;
  }
  if (!EnableLynxAir()) {
    EnsureTouchEventHandler();
    touch_event_handler_->HandleTouchEvent(
        this, template_entries_[DEFAULT_ENTRY_NAME]->GetName(), name, tag, x, y,
        client_x, client_y, page_x, page_y);
#if ENABLE_ARK_RECORDER
    tasm::recorder::TemplateAssemblerRecorder::RecordTouchEvent(
        name, tag, page_proxy()->element_manager()->root()->impl_id(), x, y,
        client_x, client_y, page_x, page_y, record_id_);
#endif
  }
#if ENABLE_AIR
  else {
    EnsureAirTouchEventHandler();
    air_touch_event_handler_->HandleTouchEvent(
        this, template_entries_[DEFAULT_ENTRY_NAME]->GetName(), name, tag, x, y,
        client_x, client_y, page_x, page_y);
  }
#endif
}

void TemplateAssembler::UpdateDataByPreParsedData(
    const std::shared_ptr<TemplateData>& template_data,
    const UpdatePageOption& update_page_option,
    base::closure finished_callback) {
#if ENABLE_ARK_RECORDER
  tasm::recorder::TemplateAssemblerRecorder::RecordUpdateDataByPreParsedData(
      template_data, update_page_option, record_id_);
#endif
  if (template_data == nullptr || destroyed()) {
    return;
  }

  // template_loaded_ is also true before loadTemplate after
  // RenderPageWithSSRData, but the template is not actually loaded.
  bool has_load_template = template_loaded_ && !page_proxy_.HasSSRRadonPage();

  LOGI("TemplateAssembler::UpdateDataByPreParsedData url:"
       << url_ << " this:" << this
       << " reset:" << update_page_option.reset_page_data
       << " state:" << (has_load_template ? "before" : "after")
       << " loadTemplate enablePreUpdateData:"
       << this->enable_pre_update_data_);

  if (has_load_template) {
    uint64_t update_data_trigger = base::CurrentSystemTimeMilliseconds();

    lepus::Value data;
    ProcessTemplateData(template_data, data, false);
    std::string timing_flag = tasm::GetTimingFlag(data);
    tasm::TimingCollector::Scope<Delegate> scope(&delegate_, timing_flag);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_SET_STATE_TRIGGER, update_data_trigger);

    UpdateTemplate(data, update_page_option);

    // When use lepusNG, should clone unconditionally.
    bool read_only = template_data->IsReadOnly() && !UseLepusNG();
    OnDataUpdatedByNative(data, read_only, update_page_option.reset_page_data,
                          std::move(finished_callback));
  } else if (enable_pre_update_data_) {
    if (!update_page_option.reset_page_data) {
      cache_data_.emplace_back(template_data);
    }
  }

  delegate_.OnTasmFinishByNative();
}

bool TemplateAssembler::UpdateConfig(const lepus::Value& config,
                                     bool noticeDelegate) {
#if ENABLE_ARK_RECORDER
  tasm::recorder::TemplateAssemblerRecorder::RecordUpdateConfig(
      config, noticeDelegate, record_id_);
#endif
  if (destroyed()) {
    return false;
  }
  if (noticeDelegate) {
    // must be called before page update, so that the theme in native should
    // be updated before page theme callback function runs
    delegate_.OnConfigUpdated(config);
  }
  lepus::Value configToJS;
  if (page_proxy_.UpdateConfig(config, configToJS, true)) {
    delegate_.OnCardConfigDataChanged(configToJS);
    return true;
  }
  return false;
}

void TemplateAssembler::UpdateDataByJS(const runtime::UpdateDataTask& task) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_UPDATE_DATA_BY_JS,
              [update_data_type = static_cast<uint32_t>(task.type_)](
                  lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("update_data_type");
                debug->set_string_value(std::to_string(update_data_type));
              });

  LOGI("TemplateAssembler::UpdateDataByJS this:"
       << this << " url:" << url_
       << " update_data_type:" << static_cast<uint32_t>(task.type_));
  if (task.data_.IsObject()) {
    auto table = task.data_.Table();
    if (table->Contains(CARD_CONFIG_STR)) {
      UpdateConfig(table->GetValue(CARD_CONFIG_STR), true);
      return;
    }
  }
  UpdatePageOption update_page_option;
  update_page_option.from_native = false;
  if (UpdateGlobalDataInternal(task.data_, update_page_option)) {
    // data.value_.Table()->dump();
    delegate_.OnDataUpdated();
  }
}

bool TemplateAssembler::FromBinary(const std::shared_ptr<TemplateEntry>& entry,
                                   std::vector<uint8_t> source, bool is_card,
                                   bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_FROM_BINARY);

  auto ReportDecodeError = [this](bool is_card,
                                  const std::shared_ptr<TemplateEntry>& entry,
                                  const std::string& error_msg) {
    this->ReportError(
        is_card ? LYNX_ERROR_CODE_LOAD_TEMPLATE
                : LYNX_ERROR_CODE_DYNAMIC_COMPONENT_DECODE_FAIL,
        ConstructDecodeErrorMessage(is_card, entry->GetName(), error_msg));
  };

  if (source.empty()) {
    constexpr char kEmptyTemplate[] =
        "the tasm file size is 0. Maybe the phone is not connected to wifi. ";
    ReportDecodeError(is_card, entry, kEmptyTemplate);
    return false;
  }

  auto input_stream =
      std::make_unique<lepus::ByteArrayInputStream>(std::move(source));

  auto reader = std::make_unique<TemplateBinaryReader>(this, entry.get(),
                                                       std::move(input_stream));
  reader->SetIsCard(is_card);
  bool result = false;
  if (is_hmr) {
    result = reader->DecodeForHMR();
  } else {
    result = reader->Decode();
  }
  if (!result) {
    ReportDecodeError(is_card, entry, reader->error_message_);
    return false;
  }

  if (!is_card) {
    delegate_.OnComponentDecoded(entry->CreateTemplateBundle());
  }
  entry->SetTemplateBinaryReader(std::move(reader));
  return result;
}

bool TemplateAssembler::UpdateGlobalDataInternal(
    const lepus_value& value, const UpdatePageOption& update_page_option) {
  Scope scope(this);

  if (!value.IsObject()) {
    return false;
  }

  PerfCollector::GetInstance().StartRecord(trace_id_,
                                           PerfCollector::Perf::RENDER_PAGE);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::UPDATE_PAGE_START);
  bool result = page_proxy_.UpdateGlobalDataInternal(value, update_page_option);
  lepus_value v = value.GetProperty(k_actual_first_screen);
  if (v.IsTrue()) {
    if (actual_fmp_end_ == 0) {
      actual_fmp_end_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::system_clock::now().time_since_epoch())
                            .count();
    }
  }
  PerfCollector::GetInstance().EndRecord(trace_id_,
                                         PerfCollector::Perf::RENDER_PAGE);

  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::UPDATE_PAGE_END);
  return result;
}

void TemplateAssembler::OnDataUpdatedByNative(const lepus_value& value,
                                              const bool read_only,
                                              const bool reset,
                                              base::closure callback) {
  delegate_.OnDataUpdatedByNative(value, read_only, reset, std::move(callback));
}

void TemplateAssembler::NotifyGlobalPropsChanged(const lepus::Value& value) {
  delegate_.NotifyGlobalPropsUpdated(value);
}

void TemplateAssembler::EnsureTouchEventHandler() {
  if (touch_event_handler_ == nullptr) {
    auto& client = page_proxy_.element_manager();
    if (client != nullptr) {
      touch_event_handler_ = std::make_unique<TouchEventHandler>(
          client->node_manager(), delegate_, support_component_js_,
          UseLepusNG(), target_sdk_version_);
    } else {
      LynxInfo(LYNX_ERROR_CODE_EVENT, "differentiator client is nullptr");
    }
  }
}

void TemplateAssembler::EnsureAirTouchEventHandler() {
#if ENABLE_AIR
  if (!air_touch_event_handler_) {
    if (page_proxy_.element_manager()) {
      air_touch_event_handler_ = std::make_unique<AirTouchEventHandler>(
          page_proxy_.element_manager()->air_node_manager());
    } else {
      LynxInfo(LYNX_ERROR_CODE_EVENT, "element_manager is nullptr");
    }
  }
#endif
}

void TemplateAssembler::OnFirstLoadPerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  delegate_.OnFirstLoadPerfReady(perf, perf_timing);
  // Send onFirstLoadPerfReady to front-end
  auto arguments = lepus::CArray::Create();
  auto params = lepus::CArray::Create();
  auto dic = lepus::Dictionary::Create();
  for (int i = static_cast<int>(base::PerfCollector::Perf::TASM_BINARY_DECODE);
       i < static_cast<int>(base::PerfCollector::Perf::BOTH_SEP) &&
       (i != static_cast<int>(base::PerfCollector::Perf::FIRST_SEP));
       i++) {
    auto iter = perf.find(i);
    if (iter != perf.end()) {
      dic->SetValue(base::PerfCollector::ToString(
                        static_cast<base::PerfCollector::Perf>(i)),
                    lepus_value(iter->second));
    }
  }

  // for ssr
  for (int i = static_cast<int>(base::PerfCollector::Perf::SSR_START_SEP);
       i < static_cast<int>(base::PerfCollector::Perf::SSR_END_SEP); i++) {
    auto iter = perf.find(i);
    if (iter != perf.end()) {
      dic->SetValue(base::PerfCollector::ToString(
                        static_cast<base::PerfCollector::Perf>(i)),
                    lepus_value(iter->second));
    }
  }
  // for ssr end

#if ENABLE_RENDERKIT
  for (int i = static_cast<int>(base::PerfCollector::Perf::RK_LAYOUT);
       i < static_cast<int>(base::PerfCollector::Perf::RK_RASTER); i++) {
    auto iter = perf.find(i);
    if (iter != perf.end()) {
      dic->SetValue(base::PerfCollector::ToString(
                        static_cast<base::PerfCollector::Perf>(i)),
                    lepus_value(iter->second));
    }
  }
#endif

  auto timing = lepus::Dictionary::Create();
  for (int i = static_cast<int>(base::PerfCollector::PerfStamp::INIT_START);
       i <= static_cast<int>(base::PerfCollector::PerfStamp::UPDATE_PAGE_END);
       i++) {
    auto iter = perf_timing.find(i);
    if (iter != perf_timing.end()) {
      timing->SetValue(
          base::PerfCollector::ToString(
              static_cast<base::PerfCollector::PerfStamp>(i)),
          lepus_value(static_cast<int64_t>(atoll(iter->second.c_str()))));
    }
  }

#if ENABLE_RENDERKIT
  for (int i =
           static_cast<int>(base::PerfCollector::PerfStamp::RK_LAYOUT_START);
       i <= static_cast<int>(base::PerfCollector::PerfStamp::RK_RASTER_END);
       i++) {
    auto iter = perf_timing.find(i);
    if (iter != perf_timing.end()) {
      timing->SetValue(
          base::PerfCollector::ToString(
              static_cast<base::PerfCollector::PerfStamp>(i)),
          lepus_value(static_cast<int64_t>(atoll(iter->second.c_str()))));
    }
  }
#endif

  dic->SetValue("timing", lepus_value(timing));

  params->push_back(lepus_value(dic));
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onFirstLoadPerfReady")));
  // params
  arguments->push_back(lepus_value(params));
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));
}

void TemplateAssembler::OnFontScaleChanged(float scale) {
  if (scale == font_scale_) {
    return;
  }
  font_scale_ = scale;
  SendFontScaleChanged(font_scale_);
}

void TemplateAssembler::SendFontScaleChanged(float scale) {
  // SendFontScaleChanged to front-end
  auto arguments = lepus::CArray::Create();
  auto params = lepus::CArray::Create();
  auto dic = lepus::Dictionary::Create();
  dic->SetValue("scale", lepus_value(scale));

  params->push_back(lepus_value(dic));
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onFontScaleChanged")));
  // params
  arguments->push_back(lepus_value(params));
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));
}

void TemplateAssembler::SendGlobalEvent(const std::string& name,
                                        const lepus::Value& info) {
  delegate_.SendGlobalEvent(name, info);
}

void TemplateAssembler::SetFontScale(float scale) {
  LOGI("TemplateAssembler::SetFontScale:" << scale);
  font_scale_ = scale;
}

void TemplateAssembler::UpdateViewport(float width, int32_t width_mode,
                                       float height, int32_t height_mode) {
  Scope scope(this);
  page_proxy_.element_manager()->OnUpdateViewport(width, width_mode, height,
                                                  height_mode, true);
}

void TemplateAssembler::OnUpdatePerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  delegate_.OnUpdatePerfReady(perf, perf_timing);
}

void TemplateAssembler::OnDynamicComponentPerfReady(
    const std::unordered_map<std::string,
                             base::PerfCollector::DynamicComponentPerfInfo>&
        dynamic_component_perf) {
  delegate_.OnDynamicComponentPerfReady(dynamic_component_perf);

  /**
   * construct perf event message:
   * -url
   *   |-sync: bool
   *   |-sync_require: bool (compatible with old formats)
   *   |-size: int
   *   |-decode_time: string
   *   |-require_time: bool
   *   └ timing
   *     |-decode_start_time: int
   *     |-decode_end_time: int
   *     |-require_start_time: int
   *     └ require_end_time: int
   */
  auto dict = lepus::Dictionary::Create();
  for (const auto& item : dynamic_component_perf) {
    static const auto& attach_perf_info = [](lepus::Dictionary& val,
                                             auto& map) {
      for (const auto& pair : map) {
        val.SetValue(
            PerfCollector::DynamicComponentPerfInfo::GetName(pair.first),
            lepus::Value(pair.second));
      }
    };

    /**
     * info:
     * |-sync: bool
     * |-sync_require: bool (compatible with old formats)
     * |-size: int
     * |- ...perf info
     */
    auto sync = lepus::Value(item.second.sync_require());
    auto info = lepus::Dictionary::Create({
        {lepus::String(RadonDynamicComponent::kSync), sync},
        {lepus::String(item.second.sync_require_key()), sync},
        {lepus::String(item.second.size_key()),
         lepus::Value(item.second.size())},
    });
    attach_perf_info(*info, item.second.perf_time());

    auto timing = lepus::Dictionary::Create();
    attach_perf_info(*timing, item.second.perf_time_stamps());
    info->SetValue(item.second.perf_time_stamps_key(), lepus::Value(timing));

    dict->SetValue(item.first.c_str(), lepus::Value(info));
  }

  // trigger fe-event
  auto arguments = lepus::CArray::Create();
  arguments->push_back(lepus::Value("onDynamicComponentPerf"));
  arguments->push_back(lepus::Value(dict));
  delegate_.CallJSFunction("GlobalEventEmitter", "trigger",
                           lepus::Value(arguments));
}

std::string TemplateAssembler::GetTargetUrl(const std::string& current,
                                            const std::string& target) {
  // Use target component name to get target url. If not found, use target
  // name as target url.
  std::string url = target;
  const auto& current_entry = FindEntry(current);
  const auto& declarations = current_entry->dynamic_component_declarations();
  const auto& target_iter = declarations.find(target);
  if (target_iter != declarations.end()) {
    url = target_iter->second;
  }
  return url;
}

std::shared_ptr<TemplateEntry> TemplateAssembler::RequireTemplateEntry(
    RadonDynamicComponent* dynamic_component, const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_REQUIRE_TEMPLATE_ENTRY,
              [url](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("url");
                debug->set_string_value(url);
              });
#if ENABLE_ARK_RECORDER
  // To record every template require for dynamic component
  tasm::recorder::RecordRequireTemplateScope scope(this, url, record_id_);
#endif  // ENABLE_ARK_RECORDER
  LOGI("LoadDynamicComponent RequireTemplate: " << url);
  auto entry = FindTemplateEntry(url);

  // if not found target entry, try to look up preloaded bundles
  if (entry == nullptr) {
    LOGI("RequireTemplate: Check preloaded bundles: " << url);
    entry = BuildTemplateEntryFromPreload(url);
  }

  // if still failed, try to send a request
  if (entry == nullptr) {
    LOGI("RequireTemplate: Request Template: " << url);
    entry = RequestTemplateEntryInternal(url, dynamic_component);
  }

  return entry;
}

std::shared_ptr<TemplateEntry> TemplateAssembler::BuildTemplateEntryFromPreload(
    const std::string& url) {
  auto preload_bundle = preload_template_bundles_.find(url);
  if (preload_bundle != preload_template_bundles_.end()) {
    LOGI("LoadDynamicComponent Find Entry from Preload: " << url);
    auto entry = BuildComponentEntryInternal(
        url,
        [this, &bundle = preload_bundle->second](
            const std::shared_ptr<TemplateEntry>& entry) -> bool {
          entry->InitWithTemplateBundle(this->shared_from_this(), bundle);
          this->delegate_.OnComponentDecoded(entry->CreateTemplateBundle());
          return true;
        });
    preload_template_bundles_.erase(preload_bundle);
    DidComponentLoaded(entry, url, false);
    return entry;
  }
  return nullptr;
}

std::shared_ptr<TemplateEntry> TemplateAssembler::RequestTemplateEntryInternal(
    const std::string& url, RadonDynamicComponent* dynamic_component) {
  /**
   * There could be three situations in which a request is sent.
   * 1. A sync request is sent, so results are immediately available
   * 2. An async request is sent, so no result is available
   * 3. No request is sent, because the previous request with the same url has
   * not yet been called back
   */
  if (component_loader_) {
    DynamicComponentLoader::RequireScope scope{component_loader_,
                                               dynamic_component};
    // TODO(zhoupeng): no need to pass dynamic_component pointer any more
    if (component_loader_->RequireTemplateCollected(dynamic_component, url,
                                                    trace_id_)) {
      // situation 1 or 2, need to check the entry map again
      auto entry = FindTemplateEntry(url);
      if (entry != nullptr) {
        // situation 1, return the result
        return entry;
      }
    }
    // situation 2 or 3, make a mark
    component_loader_->MarkNeedLoadComponent(dynamic_component, url);
  }
  return nullptr;
}

std::shared_ptr<TemplateEntry> TemplateAssembler::QueryComponent(
    const std::string& url) {
  LOGI("QueryComponent from LEPUS: " << url);
  // check if the dynamic-component is already loaded.
  auto entry = FindTemplateEntry(url);
  if (entry == nullptr && component_loader_ != nullptr) {
    component_loader_->RequireTemplate(nullptr, url, trace_id_);
  }
  // check if the dynamic-component is loaded success.
  return FindTemplateEntry(url);
}

std::shared_ptr<TemplateEntry> TemplateAssembler::FindTemplateEntry(
    const std::string& url) {
  auto entry_iter = template_entries_.find(url);
  return entry_iter == template_entries_.end() ? nullptr : entry_iter->second;
}

void TemplateAssembler::PreloadDynamicComponents(
    const std::vector<std::string>& urls) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_PRELOAD,
              "Preload urls",
              std::accumulate(urls.cbegin(), urls.cend(), std::string(", ")));
  if (component_loader_) {
    component_loader_->PreloadTemplates(urls);
  }
}

void TemplateAssembler::InsertLynxTemplateBundle(const std::string& url,
                                                 LynxTemplateBundle&& bundle) {
  /**
   * Currently, preload_template_bundles_ is used to store preloaded template
   * entries which will eventually be loaded into template_entries_. So existing
   * items in template_entries_ do not need to be inserted.
   */
  if (template_entries_.find(url) == template_entries_.end()) {
    preload_template_bundles_.emplace(url, std::move(bundle));
  }
}

void TemplateAssembler::OnDynamicJSSourcePrepared(
    const std::string& component_url) {
  delegate_.OnDynamicJSSourcePrepared(component_url);
}

void TemplateAssembler::PrintMsgToJS(const std::string& level,
                                     const std::string& msg) {
  delegate_.PrintMsgToJS(level, msg);
  // Post msg to devtool when using LynxAir, which doesn't have js runtime.
  if (lepus_context_observer_) {
    lepus_context_observer_->OnConsoleMessage(level, msg);
  }
}

lepus::Value TemplateAssembler::ProcessorDataWithName(
    const lepus::Value& input, const std::string& functionName) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_DATA_PROCESSOR,
              [&functionName](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("processor_name");
                debug->set_string_value(functionName);
              });
  lepus::Value closure;
  auto isBuildInProcessor = [](const std::string& name) {
    static const std::unordered_set<std::string> protected_processor_names = {
        REACT_PRE_PROCESS_LIFECYCLE, REACT_ERROR_PROCESS_LIFECYCLE,
        REACT_SHOULD_COMPONENT_UPDATE, REACT_SHOULD_COMPONENT_UPDATE_KEY};
    return protected_processor_names.find(name) !=
           protected_processor_names.end();
  };
  if (functionName.empty()) {
    // Use default preprocessor
    closure = default_processor_;
  } else if (isBuildInProcessor(functionName)) {
    ReportError(
        LYNX_ERROR_CODE_UPDATE,
        "built-in function cannot be called as user registered processor: " +
            functionName);
  } else {
    closure = processor_with_name_[functionName];
  }
  if (closure.IsNil()) return input;
  std::vector<lepus::Value> inputs;
  inputs.push_back(input);

  lepus::Value env = lepus::Value(lepus::Dictionary::Create());
  env.SetProperty(kGlobalPropsKey, global_props_);
  env.SetProperty(kSystemInfo, GenerateSystemInfo(nullptr));
  inputs.push_back(env);
  auto card = FindEntry(DEFAULT_ENTRY_NAME);
  lepus::Value dict = card->GetVm()->CallWithClosure(closure, inputs);
  return dict;
}

void TemplateAssembler::OnJSPrepared(const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "TemplateAssembler::OnJSPrepared");
  auto card = FindEntry(DEFAULT_ENTRY_NAME);
  // TODO(heshan):merge OnCardDecoded && OnJSSourcePrepared
  delegate_.OnCardDecoded(card->CreateTemplateBundle(),
                          lepus::Value::Clone(global_props_));
  delegate_.OnJSSourcePrepared(card->GetName(), GetPageDSL(),
                               GetBundleModuleMode(), url);
}

bool TemplateAssembler::InnerTranslateResourceForTheme(
    std::string& ret, const std::string& res_id, const std::string& theme_key,
    bool isFinalFallback) {
  DCHECK(page_proxy_.themed().hasTransConfig &&
         page_proxy_.themed().currentTransMap && !res_id.empty());
  auto& mapRef = page_proxy_.themed().currentTransMap;
  auto mapSize = mapRef->size();
  for (unsigned int i = 0; i < mapSize; ++i) {
    auto& transMap = mapRef->at(i);
    auto targetRes =
        (isFinalFallback ? transMap.curFallbackRes_ : transMap.currentRes_);
    if (targetRes == nullptr) continue;
    if (!theme_key.empty()) {
      if (transMap.name_ != theme_key) {
        continue;
      }
    }
    auto resVal = targetRes->find(res_id);
    if (resVal == targetRes->end()) continue;
    ret = resVal->second;
    return true;
  }
  return false;
}

lepus::Value TemplateAssembler::GetI18nResources(
    const lepus::Value& locale, const lepus::Value& channel,
    const lepus::Value& fallback_url) {
  if (!locale.IsString()) {
    LOGE("GetI18NResources locale must be string");
    return lepus::Value();
  }
  if (!channel.IsString()) {
    LOGE("GetI18NResources channel must be string");
    return lepus::Value();
  }
  if (channel.IsEmpty()) {
    LOGE("GetI18NResources channel must not empty");
    return lepus::Value();
  }
  std::string channelVal;
  channelVal.append(channel.String()->str()).append("__");
  updateLocale(locale, channel);
  channelVal.append(locale_);
  return i18n.GetData(this, channelVal, fallback_url.String()->str());
}

void TemplateAssembler::updateLocale(const lepus::Value& locale,
                                     const lepus::Value& channel) {
  if (!locale.String()->empty()) {
    locale_ = locale.String()->c_str();
  }
}

void TemplateAssembler::OnI18nResourceChanged(const std::string& new_data) {
  // step1: change getI18Resource return val
  delegate_.OnI18nResourceChanged(new_data);
  // step2: Send onI18nResourceReady to front-end
  auto arguments = lepus::CArray::Create();
  auto params = lepus::CArray::Create();
  auto dic = lepus::Dictionary::Create();
  params->push_back(lepus_value(dic));
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onI18nResourceReady")));
  // params
  arguments->push_back(lepus_value(params));
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));
}

void TemplateAssembler::OnI18nResourceFailed() {
  auto arguments = lepus::CArray::Create();
  auto params = lepus::CArray::Create();
  auto dic = lepus::Dictionary::Create();
  params->push_back(lepus_value(dic));
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onI18nResourceFailed")));
  // params
  arguments->push_back(lepus_value(params));
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));
}

void TemplateAssembler::UpdateI18nResource(const std::string& key,
                                           const std::string& new_data) {
  if (new_data.empty()) {
    OnI18nResourceFailed();
    return;
  }
  if (!i18n.UpdateData(key, new_data)) {  // check if sync return
    auto param = lepus::Dictionary::Create();
    param->SetValue("locale", lepus::Value(lepus::StringImpl::Create(locale_)));
    SendGlobalEventToLepus("i18nResourceReady", lepus::Value(param));
  }
  OnI18nResourceChanged(new_data);
}

void TemplateAssembler::ReFlushPage() {
  // Case: i18n may call ReFlushPage while loadingTemplate, this may cause
  // render twice.
  if (is_loading_template_) {
    return;
  }
  page_proxy_.ForceUpdate();
}

void TemplateAssembler::FilterI18nResource(const lepus::Value& channel,
                                           const lepus::Value& locale,
                                           const lepus::Value& reserve_keys) {
  if (!locale.IsString()) {
    LOGE("FilterI18nResource, locale must be string");
    return;
  }
  if (!channel.IsString()) {
    LOGE("FilterI18nResource, channel must be string");
    return;
  }
  if (!reserve_keys.IsArrayOrJSArray()) {
    LOGE("FilterI18nResource, reserveKeys must be array");
    return;
  }
  std::string channelVal;
  channelVal.append(channel.String()->str()).append("__");
  channelVal.append(locale.String()->c_str());
  i18n.SetChannelConfig(channelVal, reserve_keys);
}

void TemplateAssembler::OnPageConfigDecoded(
    const std::shared_ptr<PageConfig>& config) {
  delegate_.OnPageConfigDecoded(config);
}

bool TemplateAssembler::UseLepusNG() {
  if (!page_proxy()->HasSSRRadonPage()) {
    auto context = FindEntry(DEFAULT_ENTRY_NAME)->GetVm();
    return context ? context->IsLepusNGContext() : true;
  } else {
    return default_use_lepus_ng_;
  }
}

void TemplateAssembler::HotModuleReplace(const lepus::Value& data,
                                         const std::string& message) {
#if ENABLE_HMR
  std::vector<HmrData> components_format_data;
  if (data.GetProperty("data").IsArray()) {
    auto array = data.GetProperty("data").Array();
    // convert "uint8_t[]" of every component to "std::vector<uint8_t>" for
    // decode
    for (uint32_t i = 0; i < array->size(); ++i) {
      auto single_data = array->get(i);
      const std::string url = single_data.GetProperty("url").String()->c_str();
      // default use updateUrl as download url for template
      const std::string update_url =
          single_data.GetProperty("updateUrl").String()->c_str();
      size_t len = single_data.GetProperty("template").ByteArray()->GetLength();
      std::unique_ptr<uint8_t[]> template_js =
          single_data.GetProperty("template").ByteArray()->MovePtr();

      if (len > 0) {
        std::vector<uint8_t> template_binary(len);
        std::memcpy(template_binary.data(), template_js.get(), len);
        components_format_data.emplace_back(url, update_url, template_binary);
      }
    }
    HotModuleReplaceInternal(std::move(components_format_data), message);
  }
#endif
}

void TemplateAssembler::HotModuleReplaceInternal(
    const std::vector<HmrData>& component_data, const std::string& message) {
#if ENABLE_HMR
  auto json_document = base::strToJson(message.c_str());
  if (!(json_document.HasMember("components") &&
        json_document["components"].IsArray())) {
    return;
  }
  // get data info from json object
  const rapidjson::Value& params_array = json_document["components"];
  for (uint32_t i = 0; i < params_array.Size(); i++) {
    if (!(params_array[i].HasMember("data") &&
          params_array[i]["data"].IsObject())) {
      continue;
    }

    const rapidjson::Value& component_param = params_array[i]["data"];

    std::vector<uint8_t> source;
    const std::string url = component_param["url"].IsString()
                                ? component_param["url"].GetString()
                                : "";
    for (uint32_t k = 0; k < component_data.size(); k++) {
      if (url == component_data.at(i).template_url) {
        source = component_data.at(i).template_bin_data;
        break;
      }
    }

    if (source.size() <= 1) {
      // look up next "template.js"
      LOGI("[HMR] the 'template.js' of " << url << " is error");
      continue;
    }

    const std::string component_type = component_param["type"].IsString()
                                           ? component_param["type"].GetString()
                                           : "card";
    bool is_card = component_type ==
                   "card";  // judge whether "card" or "dynamic-component"

    const std::string new_entry = is_card ? DEFAULT_ENTRY_NAME : url;
    auto card = FindEntry(new_entry);

    bool is_full_reload = !component_param["isFullReload"].IsBool() ||
                          component_param["isFullReload"].GetBool();
    if (is_full_reload && !is_card) {
      // for dynamic component
      template_entries_.erase(url);
      ReFlushPage();
    } else {
      // partial decode "template.js"
      if (!FromBinary(card, std::move(source), is_card, true)) {
        LOGE("Decoding template failed");
        return;
      }

      bool is_style_update = component_param["isStyleUpdate"].IsBool() &&
                             component_param["isStyleUpdate"].GetBool();
      if (is_style_update) {
        HmrUpdatePageStyle(card);
      }

      HmrUpdateLepusAndJSSource(
          component_param,
          card);  // update lepus and js runtime with new source code

      // if update_components is null, then return;
      if (!(component_param.HasMember("updateComponents") &&
            component_param["updateComponents"].IsArray() &&
            component_param["updateComponents"].Size() > 0)) {
        return;
      }
      HmrExecuteUpdate(component_param, is_card, url);
    }
  }
#endif
}

// save component state and properties and don't trigger component
// lifecycle, extract all the instantiated component information(component name,
// component id and component tid) form component_map
void TemplateAssembler::HmrExecuteUpdate(
    const rapidjson::Value& component_param, const bool& is_card,
    const std::string& url) {
#if ENABLE_HMR
  const std::string new_entry = is_card ? DEFAULT_ENTRY_NAME : url;
  auto card = FindEntry(new_entry);
  LightComponentInfo component_map_info = HmrExtractComponentInfo();
  const rapidjson::Value& update_components =
      component_param["updateComponents"];
  // only update necessary Component
  for (uint32_t k = 0; k < update_components.Size(); k++) {
    const rapidjson::Value& updated_component = update_components[k];
    if (!updated_component.IsObject()) {
      continue;
    }
    const bool is_entry = updated_component["isEntry"].IsBool() &&
                          updated_component["isEntry"].GetBool();
    const std::string component_name =
        is_entry && !is_card
            ? url
            : updated_component["name"]
                  .GetString();  // when entry is dynamic_component, use url
                                 // as component_name
    const std::string component_type = updated_component["type"].GetString();
    ComponentUpdateType component_update_type =
        component_type.compare("component-update") == 0
            ? ComponentUpdateType::Update
            : ComponentUpdateType::Rerender;
    // set dispatch Option for update
    DispatchOption dispatch_option(&page_proxy_);
    PipelineOptions pipeline_options;
    pipeline_options.timing_flag = tasm::GetTimingFlag(lepus::Value());
    pipeline_options.has_patched = dispatch_option.has_patched_;
    switch (component_update_type) {
      case ComponentUpdateType::Rerender: {
        dispatch_option.force_diff_entire_tree_ = true;
        dispatch_option.force_update_this_component = true;
        dispatch_option.use_new_component_data_ = true;
        dispatch_option.refresh_lifecycle_ = true;
        break;
      }
      case ComponentUpdateType::Update: {
        dispatch_option.component_update_by_hmr_ = true;
        dispatch_option.force_update_this_component = true;
        break;
      }
      default:
        break;
    }

    if (component_map_info.find(component_name) != component_map_info.end()) {
      // for components
      std::vector<int> component_ids;
      int tid;
      std::tie(component_ids, tid) = component_map_info.at(component_name);
      // for component whose component_name is same but own different
      // component_id
      lepus::Value initial_data = lepus::Value();

      switch (component_update_type) {
        case ComponentUpdateType::Rerender: {
          // use latest initialData from new component_moulds
          if (is_card) {
            auto cm_it = component_moulds(new_entry).find(tid);
            if (cm_it == component_moulds(new_entry).end()) {
              LOGI("[HMR] can not execute update or rerender of '"
                   << component_name);
              continue;
            }
            initial_data = cm_it->second.get()->data();
          } else {
            auto cm_it = dynamic_component_moulds(new_entry).find(tid);
            if (cm_it == dynamic_component_moulds(new_entry).end()) {
              LOGI("[HMR] can not execute update or rerender of '"
                   << component_name);
              continue;
            }
            initial_data = cm_it->second.get()->data();
          }
          break;
        }
        case ComponentUpdateType::Update: {
          initial_data = lepus::Value();  // use empty data
          break;
        }
        default:
          break;
      }

      for (auto id : component_ids) {
        RadonComponent* component = page_proxy_.GetComponentMap().at(id);
        if (!is_card) {
          // replace VMContext
          static_cast<RadonDynamicComponent*>(component)->SetContext(this);
        }
        component->UpdateRadonComponent(
            BaseComponent::RenderType::UpdateByNative, lepus::Value(),
            initial_data, dispatch_option);
        page_proxy_.element_manager()->OnPatchFinishFromRadon(
            dispatch_option.has_patched_, pipeline_options);
        // reset "has_patched_" to false
        dispatch_option.has_patched_ = false;
      }
    } else if (component_name == card->GetName()) {
      // for radon page
      switch (component_update_type) {
        case ComponentUpdateType::Rerender: {
          // use latest initialData
          UpdatePageOption update_page_option;
          update_page_option.reload_template = true;
          auto page_it = page_moulds().find(page_proxy_.Page()->tid());
          if (page_it == page_moulds().end()) {
            ReportError(
                LYNX_ERROR_CODE_HMR_LEPUS_UPDATE,
                "[HMR] can not execute update or rerender of page, because "
                "page can't be find in page_moulds");
            return;
          }
          page_proxy_.Page()->UpdatePage(page_it->second.get()->data(),
                                         update_page_option);
          break;
        }
        case ComponentUpdateType::Update: {
          page_proxy_.Page()->Refresh(dispatch_option);
          break;
        }
        default:
          break;
      }
      page_proxy_.element_manager()->OnPatchFinishFromRadon(
          dispatch_option.has_patched_, pipeline_options);
      dispatch_option.has_patched_ = false;
    } else {
      ReportError(LYNX_ERROR_CODE_HMR_LEPUS_UPDATE,
                  "[HMR] can not execute update or rerender of '" +
                      component_name + "' !");
    }
  }
#endif
}

void TemplateAssembler::HmrUpdateLepusAndJSSource(
    const rapidjson::Value& component_param,
    const std::shared_ptr<TemplateEntry>& entry) {
#if ENABLE_HMR
  const std::string lepus_source_code =
      component_param["updateLepusJs"].IsString()
          ? component_param["updateLepusJs"].GetString()
          : "console.warning('[HMR]: lepus source code is empty')";
  const std::string js_source_code =
      component_param["updateJs"].IsString()
          ? component_param["updateJs"].GetString()
          : "console.warning('[HMR]: js source code is empty'";
  // execute lepusNG HMR code
  if (entry->GetVm()->IsLepusNGContext()) {
    entry->GetVm()->Compile(lepus_source_code);
    entry->GetVm()->Execute();
  } else if (entry->GetVm()->IsVMContext()) {
    ReportError(LYNX_ERROR_CODE_HMR_LEPUS_UPDATE,
                "HMR is work only under lepusNG!");
  }

  // execute js HMR code
  delegate_.HmrEvalJsCode(js_source_code);
#endif
}

LightComponentInfo TemplateAssembler::HmrExtractComponentInfo() {
  std::unordered_map<std::string, std::tuple<std::vector<int>, int32_t>>
      component_map_info;
#if ENABLE_HMR
  for ([[maybe_unused]] const auto& [key, component] :
       page_proxy_.GetComponentMap()) {
    std::string component_name = component->name().str();
    int componentId = component->ComponentId();
    if (component_map_info.find(component_name) != component_map_info.end()) {
      std::vector<int> component_ids =
          std::get<0>(component_map_info.at(component_name));
      component_ids.push_back(componentId);
    } else {
      std::vector<int> component_ids = {componentId};
      std::tuple component_info =
          std::make_tuple(component_ids, component->tid());
      component_map_info.insert({component_name, std::move(component_info)});
    }
  }
#endif
  return component_map_info;
}

void TemplateAssembler::HmrUpdatePageStyle(
    const std::shared_ptr<TemplateEntry>& entry) {
#if ENABLE_HMR
  // code style form template.js and update all the style
  // set new style sheet to Page and Component
  auto component_map = page_proxy()->GetComponentMap();
  entry->GetStyleSheetManager()->ResetPageAndComponentFragments();

  // for page style update
  auto* page = page_proxy()->Page();
  auto new_page_intrinsic_style_sheet =
      entry->GetStyleSheetManager()->GetCSSStyleSheetForPage(page->GetCSSId());
  page->ClearStyleSheetAndVariables();
  page->SetIntrinsicStyleSheet(new_page_intrinsic_style_sheet);

  // for component style update
  for ([[maybe_unused]] const auto& [key, component] : component_map) {
    component->ClearStyleSheetAndVariables();
    // generate new style sheet
    auto new_intrinsic_style_sheet =
        entry->GetStyleSheetManager()->GetCSSStyleSheetForComponent(
            component->GetCSSId());
    component->SetIntrinsicStyleSheet(new_intrinsic_style_sheet);
  }

  DispatchOption dispatch_option(&page_proxy_);
  dispatch_option.ignore_component_lifecycle_ = true;
  dispatch_option.ignore_cached_style_ = true;
  RadonPage* radon_page = page_proxy_.Page();
  // only update style for whole page, just a light diff
  radon_page->RefreshWithNewStyle(dispatch_option);
#endif
}

void TemplateAssembler::SetCSSVariables(const std::string& component_id,
                                        const std::string& id_selector,
                                        const lepus::Value& properties) {
  page_proxy()->SetCSSVariables(component_id, id_selector, properties);
}

void TemplateAssembler::SetNativeProps(const NodeSelectRoot& root,
                                       const tasm::NodeSelectOptions& options,
                                       const lepus::Value& native_props) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_SET_NATIVE_PROPS,
              [&native_props](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("setNativeProps");
                /* Concatenate all the keys in updating data */
                std::string ss;
                ForEachLepusValue(native_props, [&ss](const lepus::Value& key,
                                                      const lepus::Value& val) {
                  ss.append(key.String()->str())
                      .append(" , ")
                      .append(val.String()->str())
                      .append("\n");
                });
                debug->set_string_value(ss);
              });
  auto elements = page_proxy_.SelectElements(root, options);
  for (auto ele : elements) {
    if (ele != nullptr) {
      ele->SetNativeProps(native_props);
    }
  }
}

void TemplateAssembler::SendDynamicComponentEvent(
    const std::string& url, const lepus::Value& err,
    const std::vector<int>& impl_id_list) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SendDynamicComponentEvent");
  auto param = lepus::CArray::Create();
  param->push_back(err);
  auto arguments = lepus::CArray::Create();
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onDynamicComponentEvent")));
  // params
  arguments->push_back(lepus::Value(param));
  // for backward compatible (@nihao.royal)
  delegate_.CallJSFunction("GlobalEventEmitter", "emit",
                           lepus_value(arguments));

  // trigger `bindEvent`
  EnsureTouchEventHandler();

  std::for_each(impl_id_list.begin(), impl_id_list.end(),
                [this, &err](const int impl_id) {
                  touch_event_handler_->HandleCustomEvent(
                      this, RadonDynamicComponent::kEventFail, impl_id, err,
                      RadonDynamicComponent::kDetail);
                });
}

void TemplateAssembler::SendDynamicComponentEvent(const std::string& url,
                                                  const lepus::Value& err,
                                                  int tag) {
  SendDynamicComponentEvent(url, err,
                            std::vector<int>{
                                tag,
                            });
}

// TODO(zhoupeng): At present, the name of this method is no longer appropriate.
// Rename it later.
void TemplateAssembler::SendDynamicComponentEvent(
    const std::string& url, const lepus::Value& err,
    const std::vector<uint32_t>& uid_list) {
  std::vector<int> impl_ids;
  page_proxy_.OnFailInLoadDynamicComponent(uid_list, impl_ids);
  SendDynamicComponentEvent(url, err, impl_ids);
}

void TemplateAssembler::TriggerDynamicComponentEvent(
    const lepus::Value& msg, bool sync, RadonDynamicComponent* component,
    base::MoveOnlyClosure<void, const lepus::Value&> async_event_handler) {
  if (!sync) {
    async_event_handler(msg);
  } else if (component) {
    component->SetDynamicComponentState(DynamicCompState::STATE_FAIL, msg);
  }
}

#if ENABLE_ARK_RECORDER
void TemplateAssembler::SetRecordID(int64_t record_id) {
  record_id_ = record_id;
}
int64_t TemplateAssembler::GetRecordID() const { return record_id_; }
#endif

void TemplateAssembler::SetLepusEventListener(const std::string& name,
                                              const lepus::Value& listener) {
  lepus_event_listeners_[name] = listener;
}

void TemplateAssembler::RemoveLepusEventListener(const std::string& name) {
  auto iter = lepus_event_listeners_.find(name);
  if (iter != lepus_event_listeners_.end()) {
    lepus_event_listeners_.erase(iter);
  }
}

void TemplateAssembler::SendGlobalEventToLepus(const std::string& name,
                                               const lepus_value& params) {
  auto iter = lepus_event_listeners_.find(name);
  if (iter == lepus_event_listeners_.end() || !iter->second.IsCallable()) {
    return;
  }
  lepus::Value closure = iter->second;
  TriggerLepusClosure(closure, params);
}

void TemplateAssembler::TriggerEventBus(const std::string& name,
                                        const lepus_value& params) {
  if (!UseLepusNG()) {
    return;
  }
  std::vector<lepus::Value> params_vec;
  params_vec.emplace_back(lepus::StringImpl::Create("GlobalEventEmitter"));
  params_vec.emplace_back(lepus::StringImpl::Create("toggle"));
  params_vec.emplace_back(lepus::StringImpl::Create(name));
  params_vec.push_back(params);
  for (auto it : template_entries_) {
    if (it.second->GetVm()) {
      it.second->GetVm()->Call("callLepusModuleMethod", params_vec);
    }
  }
}

void TemplateAssembler::RenderToBinary(
    base::MoveOnlyClosure<void, RadonNode*, tasm::TemplateAssembler*>
        binarizer) {
  page_proxy_.RenderToBinary(binarizer, this);
}

bool TemplateAssembler::ProcessTemplateData(
    const std::shared_ptr<TemplateData>& template_data, lepus::Value& data,
    bool is_first_screen) {
  if (page_config_ && page_config_->GetEnableFiberArch()) {
    return ProcessTemplateDataForFiber(template_data, data, is_first_screen);
  } else {
    return ProcessTemplateDataForRadon(template_data, data, is_first_screen);
  }
}

bool TemplateAssembler::ProcessTemplateDataForFiber(
    const std::shared_ptr<TemplateData>& template_data, lepus::Value& data,
    bool is_first_screen) {
  // Call processData function with template data and processor name. If the
  // result is object, let data be the result. Otherwise, let data be template
  // data.
  constexpr const static char* kProcessData = "processData";
  const auto& res =
      FindEntry(tasm::DEFAULT_ENTRY_NAME)
          ->GetVm()
          ->Call(kProcessData,
                 {template_data ? template_data->GetValue() : lepus::Value(),
                  template_data
                      ? lepus::Value(template_data->PreprocessorName().c_str())
                      : lepus::Value("")});
  if (res.IsObject()) {
    data = res;
  } else if (template_data) {
    data = template_data->GetValue();
  }
  return template_data ? template_data->IsReadOnly() : false;
}

bool TemplateAssembler::ProcessTemplateDataForRadon(
    const std::shared_ptr<TemplateData>& template_data, lepus::Value& data,
    bool is_first_screen) {
  bool read_only = false;
  std::string processor_name;
  if (template_data != nullptr || global_props_.IsObject() ||
      !page_proxy_.GetDefaultPageData().IsEmpty()) {
    if (template_data != nullptr) {
      data = template_data->GetValue();
      processor_name = template_data->PreprocessorName();
      read_only = template_data->IsReadOnly();
    } else {
      data = lepus::Value::CreateObject();
    }

    if (!page_proxy_.GetDefaultPageData().IsEmpty()) {
      if (data.IsEmpty()) {
        data = lepus::Value::CreateObject();
      }
      ForEachLepusValue(
          page_proxy_.GetDefaultPageData(),
          [&data](const lepus::Value& key, const lepus::Value& value) {
            if (data.GetProperty(key.String()).IsEmpty()) {
              data.SetProperty(key.String(), value);
            }
          });
    }
    if (page_proxy_.HasSSRRadonPage()) {
      // TODO(zhixuan): Support diff global props for ssr.
      page_proxy_.DiffHydrationData(data);
    }

    // Only exec the following code on first screen.
    if (!page_proxy_.GetEnableRemoveComponentExtraData() &&
        global_props_.IsObject() && is_first_screen) {
      // Backward Compatible, should be deleted later. (@nihao.royal)
      // globalProps should be visited through the second param in DataProcessor
      data.SetProperty(kGlobalPropsKey, global_props_);
    }
    data = ProcessorDataWithName(data, processor_name);
  }
  return read_only;
}

void TemplateAssembler::RenderPageWithSSRData(
    std::vector<uint8_t> ssr_byte_array,
    const std::shared_ptr<TemplateData>& template_data) {
#if ENABLE_ARK_RECORDER
  tasm::recorder::TemplateAssemblerRecorder::RecordLoadTemplate(
      "", ssr_byte_array, template_data, record_id_, false);
  auto& client = page_proxy_.element_manager();
  if (client != nullptr) {
    client->SetRecordId(record_id_);
  }
#endif

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_RENDER_PAGE_START_SSR);

  Scope scope(this);
  page_proxy_.ResetHydrateInfo();

  PerfCollector::GetInstance().InsertDouble(
      trace_id_, PerfCollector::Perf::SSR_SOURCE_SIZE, ssr_byte_array.size());

  lepus::Value ssr_out_value;

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_DECODE_START_SSR);
  if (!ssr::DecodeSSRData(std::move(ssr_byte_array), &ssr_out_value)) {
    LynxWarning(false, LYNX_ERROR_CODE_SSR_DECODE, "SSR data corrupted.");
    return;
  }
  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_DECODE_END_SSR);

  ssr::CheckSSRkApiVersion(ssr_out_value);
  auto page_status = ssr::RetrievePageConfig(ssr_out_value);
  ResetPageConfigWithSSRData(page_status);

  PerfCollector::GetInstance().StartRecord(trace_id_,
                                           PerfCollector::Perf::SSR_FMP);
  lepus::Value data(lepus::Dictionary::Create());
  ProcessTemplateData(template_data, data, true);
  page_proxy_.RenderWithSSRData(ssr_out_value, data, trace_id_);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "SSR script process");
  lepus::Value ssr_script_ori = ssr::RetrieveScript(ssr_out_value);
  lepus::Value ssr_script_res =
      ssr::ProcessSsrScriptIfNeeded(ssr_script_ori, data);
  std::string ssr_script = ssr_script_res.ToString();
  delegate_.OnSsrScriptReady(std::move(ssr_script));
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  template_loaded_ = true;

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_RENDER_PAGE_END_SSR);
}

void TemplateAssembler::ResetPageConfigWithSSRData(lepus::Value page_status) {
  support_component_js_ = ssr::RetrieveSupportComponentJS(page_status);
  target_sdk_version_ = ssr::RetrieveTargetSdkVersion(page_status);
  default_use_lepus_ng_ = ssr::RetrieveLepusNGSwitch(page_status);

  // reconstruct page config.
  auto page_config = ssr::RetrieveLynxPageConfig(page_status);
  SetPageConfig(page_config);
  SetPageConfigClient();
  OnPageConfigDecoded(page_config);
}

Themed& TemplateAssembler::Themed() { return page_proxy_.themed(); }

void TemplateAssembler::SetThemed(
    const Themed::PageTransMaps& page_trans_maps) {
  if (!page_trans_maps.empty()) {
    Themed().reset();
    Themed().pageTransMaps = page_trans_maps;
    Themed().hasTransConfig = true;
  }
}

// For fiber
void TemplateAssembler::CallLepusMethod(const std::string& method_name,
                                        lepus::Value args,
                                        const piper::ApiCallBack& callback,
                                        uint64_t trace_flow_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateAssembler::CallLepusMethod",
              [&](perfetto::EventContext ctx) {
                ctx.event()->add_flow_ids(callback.trace_flow_id());
                ctx.event()->add_terminating_flow_ids(trace_flow_id);
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("methodName");
                debug->set_string_value(method_name);
              });

  Scope scope(this);
  LOGI("TemplateAssembler::CallLepusMethod. this:"
       << this << " url:" << url_ << " method name: " << method_name);

  context(tasm::DEFAULT_ENTRY_NAME)->Call(method_name, {std::move(args)});
  if (callback.IsValid()) {
    delegate_.CallJSApiCallback(callback);
  }
}

lepus::Value TemplateAssembler::TriggerLepusClosure(
    const lepus::Value& closure, const lepus::Value& params) {
  auto card = FindEntry(DEFAULT_ENTRY_NAME);
  std::vector<lepus::Value> params_vec;
  if (params.IsArrayOrJSArray()) {
    size_t size = params.Array()->size();
    for (size_t i = 0; i < size; ++i) {
      params_vec.push_back(params.GetProperty(static_cast<int>(i)));
    }
  } else {
    params_vec.push_back(params);
  }
  return card->GetVm()->CallWithClosure(closure, params_vec);
}

void TemplateAssembler::SendAirPageEvent(const std::string& event,
                                         const lepus::Value& value) {
#if ENABLE_AIR
  if (EnableLynxAir()) {
    EnsureAirTouchEventHandler();
    air_touch_event_handler_->SendPageEvent(this, event, value);
  }
#endif
}

lepus::Value TemplateAssembler::TriggerBridgeSync(
    const std::string& method_name, const lynx::lepus::Value& arguments) {
  return delegate_.TriggerBridgeSync(method_name, arguments);
}

void TemplateAssembler::TriggerBridgeAsync(
    lepus::Context* context, const std::string& method_name,
    const lynx::lepus::Value& arguments,
    std::unique_ptr<lepus::Value> callback_closure) {
  delegate_.TriggerBridgeAsync(context, method_name, arguments,
                               std::move(callback_closure));
}

uint32_t TemplateAssembler::SetTimeOut(lepus::Context* context,
                                       std::unique_ptr<lepus::Value> closure,
                                       int64_t delay_time) {
  return delegate_.SetTimeOut(context, std::move(closure), delay_time);
}

uint32_t TemplateAssembler::SetTimeInterval(
    lepus::Context* context, std::unique_ptr<lepus::Value> closure,
    int64_t interval_time) {
  return delegate_.SetTimeInterval(context, std::move(closure), interval_time);
}

void TemplateAssembler::RemoveTimeTask(uint32_t task_id) {
  delegate_.RemoveTimeTask(task_id);
}

void TemplateAssembler::InvokeAirCallback(int64_t id,
                                          const std::string& entry_name,
                                          const lepus::Value& data) {
  delegate_.InvokeAirCallback(id, entry_name, data);
}

}  // namespace tasm
}  // namespace lynx
