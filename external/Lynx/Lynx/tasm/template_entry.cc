//
// Created by bytedance on 2020-03-29.
//

#include "tasm/template_entry.h"

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/quick_context.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/renderer.h"
#include "tasm/template_assembler.h"
#include "tasm/template_binary_reader.h"

#if ENABLE_LEPUSNG_WORKLET
#include "jsbridge/bindings/worklet/napi_loader_ui.h"
#include "jsbridge/napi/napi_runtime_proxy_quickjs.h"
#endif

namespace lynx {
namespace tasm {

TemplateEntry::TemplateEntry()
    : VmContextHolder(nullptr),
      style_sheet_manager_(std::make_shared<CSSStyleSheetManager>(this)) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateEntry::TemplateEntry");
}

TemplateEntry::TemplateEntry(std::shared_ptr<lepus::Context>& context,
                             const std::string& targetSdkVersion)
    : VmContextHolder(context),
      style_sheet_manager_(std::make_shared<CSSStyleSheetManager>(this)) {
#if !ENABLE_JUST_LEPUSNG
  if (vm_context_->IsVMContext()) {
    lepus::VMContext::Cast(vm_context_.get())->SetSdkVersion(targetSdkVersion);
  }
#endif

  vm_context_->Initialize();
}

void TemplateEntry::ConstructContext(TemplateAssembler* assembler,
                                     bool isLepusNGBinary) {
  vm_context_ = lepus::Context::CreateContext(isLepusNGBinary);

#if !ENABLE_JUST_LEPUSNG
  if (vm_context_ && vm_context_->IsVMContext()) {
    lepus::VMContext::Cast(vm_context_.get())
        ->SetSdkVersion(assembler->TargetSdkVersion());
  }
#endif

  if (vm_context_) {
    vm_context_->Initialize();
    RegisterBuiltin(assembler);
  }
}

std::unique_ptr<TemplateEntry>
TemplateEntry::ConstructEntryWithNoTemplateAssembler(
    std::shared_ptr<lepus::Context> context,
    const std::string& targetSdkVersion) {
  return std::make_unique<TemplateEntry>(context, targetSdkVersion);
}

bool TemplateEntry::InitWithTemplateBundle(
    const std::shared_ptr<TemplateAssembler>& tasm,
    const LynxTemplateBundle& template_bundle) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateEntry::InitWithTemplateBundle");
  // update compiler_options_
  set_compile_options(template_bundle.compile_options_);

  // set template debug url
  SetTemplateDebugUrl(compile_options_.template_debug_url_);
  bool is_card = template_bundle.app_type_ == APP_TYPE_CARD;

  // lazy construct lepus context.
  if (!vm_context_) {
    ConstructContext(tasm.get(), template_bundle.is_lepusng_binary_);
    if (is_card) {
      tasm->vm_to_template_entry_.insert(
          std::make_pair(vm_context_.get(), this));
      SetName(template_bundle.app_name_);
      vm_context_->set_name(DEFAULT_ENTRY_NAME);
    } else {
      vm_context_->set_name(GetName());
    }
  }

  if (is_card) {
    {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "InitLepusDebugger");
      tasm->InitLepusDebugger();
    }

    TRACE_EVENT(LYNX_TRACE_CATEGORY, "InitCardEnv");
    SetNeedJSGlobalConsole(template_bundle.need_console_);
    SetSupportComponentJS(template_bundle.support_component_js_);
    tasm->SetSupportComponentJS(support_component_js_);
    tasm->SetTargetSdkVersion(template_bundle.target_sdk_version_);
    // set page_config
    tasm->SetPageConfig(template_bundle.page_configs_);
    tasm->SetThemed(template_bundle.themed_.pageTransMaps);
  }

  UpdateCSSConfig(tasm->GetPageConfig());

  // set style sheet
  SetStyleSheetManager(template_bundle.css_style_manager_);

  // set page moulds.
  SetPageMoulds(template_bundle.page_moulds_);
  // set component_moulds
  SetComponentMoulds(template_bundle.component_moulds_);
  component_name_to_id_ = template_bundle.component_name_to_id_;
  // set js_source
  SetJSSource(template_bundle.js_sources_);

  SetCircularDataCheck(tasm->GetPageConfig()->GetGlobalCircularDataCheck());
  // set dynamic_component_moulds
  SetDynamicComponentMoulds(template_bundle.dynamic_component_moulds_);
  SetDynamicComponentDeclarations(
      template_bundle.dynamic_component_declarations_);
  // set lepus string
  uint32_t count = template_bundle.string_list_count_;
  vm_context_->string_table()->string_list.resize(count);
  for (size_t index = 0; index < count; index++) {
    vm_context_->string_table()->string_list[index] =
        template_bundle.string_list_[index];
  }

  // set element template info
  element_template_infos_ = template_bundle.element_template_infos_;

  // set parsed styles map
  parsed_styles_map_ = template_bundle.parsed_styles_map_;

  // set air parsed styels
  air_parsed_styles_map_ = template_bundle.air_parsed_styles_map_;

  return DoSerializeLepus(tasm->GetPageConfig(), template_bundle);
}

bool TemplateEntry::DoSerializeLepus(
    const std::shared_ptr<PageConfig>& page_config,
    const LynxTemplateBundle& template_bundle) {
  if (vm_context_->IsLepusNGContext()) {
    const auto& data = template_bundle.lepusng_code_;
    auto data_len = template_bundle.lepusng_code_len_;
    if (!lepus::QuickContext::Cast(vm_context_.get())
             ->DeSerialize(data.data(), data_len)) {
      return false;
    }
  } else {
#if !ENABLE_JUST_LEPUSNG
    lepus::VMContext::Cast(vm_context_.get())
        ->SetSdkVersion(template_bundle.target_sdk_version_);
    for (auto& global : template_bundle.lepus_root_global_) {
      lepus::VMContext::Cast(vm_context_.get())
          ->global_.Add(global.first, global.second);
    }
    lepus::VMContext::Cast(vm_context_.get())->root_function_ =
        template_bundle.lepus_root_function_;
    for (auto& top_var : template_bundle.lepus_top_variables_) {
      lepus::VMContext::Cast(vm_context_.get())
          ->top_level_variables_.insert(top_var);
    }
#else
    LOGE("just lepusng sdk just can run lepusng template.js");
    return false;
#endif
  }

  return ApplyConfigsToLepusContext(page_config,
                                    template_bundle.target_sdk_version_);
}

bool TemplateEntry::ApplyConfigsToLepusContext(
    const std::shared_ptr<PageConfig>& page_config,
    const std::string& target_sdk_version) {
  if (vm_context_->IsLepusNGContext()) {
    lepus::QuickContext::Cast(vm_context_.get())
        ->SetEnableStrictCheck(page_config->GetEnableLepusStrictCheck());
    lepus::QuickContext::Cast(vm_context_.get())
        ->SetStackSize(page_config->GetLepusQuickjsStackSize());
    if (Config::IsHigherOrEqual(target_sdk_version, LYNX_VERSION_2_5)) {
      lepus::QuickContext::Cast(vm_context_.get())
          ->SetTemplateDebugURL(GetTemplateDebugUrl());
    }

    if (compile_options_.lepusng_debuginfo_outside_) {
      lepus::QuickContext::Cast(vm_context_.get())->set_debuginfo_outside(true);
    }
    // TODO: only need to init napi environment when there is worklet code in
    // template.js
    if (page_config->GetLynxAirMode() !=
        CompileOptionAirMode::AIR_MODE_STRICT) {
      AttachNapiEnvironment();
    }
    return true;
  }

#if !ENABLE_JUST_LEPUSNG
  lepus::VMContext::Cast(vm_context_.get())
      ->SetEnableStrictCheck(page_config->GetEnableLepusStrictCheck());

  bool data_strict_mode;
  if (page_config->GetDSL() == PackageInstanceDSL::REACT) {
    // DataStrictMode default false For React DSL.
    data_strict_mode = false;
  } else {
    data_strict_mode = page_config->GetDataStrictMode();
  }
  lepus::VMContext::Cast(vm_context_.get())
      ->SetEnableTopVarStrictMode(data_strict_mode);

  lepus::VMContext::Cast(vm_context_.get())
      ->SetNullPropAsUndef(page_config->GetEnableLepusNullPropAsUndef());

  // save template_debug.json url to vm context
  lepus::VMContext::Cast(vm_context_.get())
      ->SetTemplateDebugURL(GetTemplateDebugUrl());
  return true;
#else
  LOGE("just lepusng sdk just can run lepusng template.js");
  return false;
#endif
  return true;
}

bool TemplateEntry::Execute() {
  if (is_card_ || !EnableReuseContext()) {
    return GetVm()->Execute();
  }
  // Binary is already executed while EvalBinary.
  return true;
}

void TemplateEntry::UpdateCSSConfig(
    const std::shared_ptr<PageConfig>& page_config) {
  if (page_config) {
    auto configs = CSSParserConfigs::GetCSSParserConfigsByComplierOptions(
        compile_options_);
    page_config->SetCSSParserConfigs(configs);
  }
}

TemplateEntry::~TemplateEntry() {
  DetachNapiEnvironment();
  style_sheet_manager_->SetThreadStopFlag(true);
}

void TemplateEntry::RegisterBuiltin(TemplateAssembler* assembler) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateEntry::TemplateEntry::Assembler");
  if (vm_context_->IsLepusNGContext()) {
    lepus::QuickContext* qctx = lepus::QuickContext::Cast(vm_context_.get());
    LEPUSValue self = LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, assembler);
    qctx->RegisterGlobalProperty("$kTemplateAssembler", self);
    Utils::RegisterNGBuiltin(vm_context_.get());
    Renderer::RegisterNGBuiltin(vm_context_.get(),
                                compile_options().arch_option_);
    return;
  }

#if !ENABLE_JUST_LEPUSNG
  lepus::Value self(assembler);
  lepus::VMContext::Cast(vm_context_.get())
      ->SetGlobalData("$kTemplateAssembler", self);
  Utils::RegisterBuiltin(vm_context_.get());
  Renderer::RegisterBuiltin(vm_context_.get(), compile_options().arch_option_);
#endif
}

const ElementTemplateInfo& TemplateEntry::GetElementTemplateInfo(
    const std::string& key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateEntry::GetTemplateInfo");
  auto iter = element_template_infos_.find(key);
  if (iter == element_template_infos_.end()) {
    auto info = reader_ ? reader_->DecodeElementTemplate(key)
                        : std::make_shared<ElementTemplateInfo>();
    auto res = element_template_infos_.insert({key, info});
    return *(res.first->second);
  }
  return *(iter->second);
}

const StyleMap& TemplateEntry::GetParsedStyles(const std::string& key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TemplateEntry::GetParsedStyles");
  if (reader_) {
    return reader_->GetParsedStyles(key);
  }
  auto iter = parsed_styles_map_.find(key);
  if (iter == parsed_styles_map_.end()) {
    auto res = parsed_styles_map_.emplace(key, std::make_shared<StyleMap>());
    return *(res.first->second);
  }
  return *(iter->second);
}

const AirCompStylesMap& TemplateEntry::GetComponentParsedStyles(
    const std::string& path) {
  return air_parsed_styles_map_[path];
}

void TemplateEntry::SetName(std::string name) {
  name_ = name;
  if (vm_context_) {
    vm_context_->set_name(name);
  }
}

void TemplateEntry::InitLepusDebugger(
    const std::shared_ptr<LepusContextObserver>& observer) {
#if OS_OSX
#else
  if (observer != nullptr) {
    debugger_.reset(reinterpret_cast<piper::JavaScriptDebuggerWrapper*>(
        observer->CreateJavascriptDebugger(template_debug_url_)));
  }
  if (debugger_ != nullptr && debugger_->debugger_ != nullptr) {
    debugger_->debugger_->InitWithContext(vm_context_);
  }
#endif
}

void TemplateEntry::AddDynamicComponentDeclaration(const std::string& name,
                                                   const std::string& path) {
  dynamic_component_declarations_[name] = path;
}

void TemplateEntry::ReInit(TemplateAssembler* assembler) {
  vm_context_->Initialize();
  RegisterBuiltin(assembler);
}

piper::NapiEnvironment* TemplateEntry::napi_environment() {
#if ENABLE_LEPUSNG_WORKLET
  return napi_environment_.get();
#else
  return nullptr;
#endif
}

void TemplateEntry::InvokeLepusBridge(const int32_t callback_id,
                                      const lepus::Value& data) {
#if ENABLE_LEPUSNG_WORKLET
  reinterpret_cast<lynx::worklet::NapiLoaderUI*>(napi_environment_->delegate())
      ->InvokeLepusBridge(callback_id, data);
#endif
}

void TemplateEntry::AttachNapiEnvironment() {
#if ENABLE_LEPUSNG_WORKLET
  if (vm_context_->IsLepusNGContext() && !napi_environment_) {
    lepus::QuickContext* qctx = lepus::QuickContext::Cast(vm_context_.get());
    napi_environment_ = std::make_unique<lynx::piper::NapiEnvironment>(
        std::make_unique<lynx::worklet::NapiLoaderUI>(qctx));
    auto proxy = lynx::piper::NapiRuntimeProxyQuickjs::Create(qctx->context());
    auto napi_proxy = std::unique_ptr<piper::NapiRuntimeProxy>(
        static_cast<piper::NapiRuntimeProxy*>(proxy.release()));
    napi_environment_->SetRuntimeProxy(std::move(napi_proxy));
    napi_environment_->Attach();
  }
#endif
}

void TemplateEntry::DetachNapiEnvironment() {
#if ENABLE_LEPUSNG_WORKLET
  if (vm_context_ && vm_context_->IsLepusNGContext() && napi_environment_) {
    napi_environment_->Detach();
  }
#endif
}

bool TemplateEntry::IsCompatibleWithRootEntry(const TemplateEntry& root,
                                              std::string& msg) {
  const auto& component_compile_option = compile_options();
  const auto& root_compile_options = root.compile_options();
  if (component_compile_option.radon_mode_ !=
      root_compile_options.radon_mode_) {
    msg = "DynamicComponent's radon mode is: " +
          std::to_string(component_compile_option.radon_mode_) +
          ", while the root's radon mode is: " +
          std::to_string(root_compile_options.radon_mode_);
    return false;
  }
  if (component_compile_option.front_end_dsl_ !=
      root_compile_options.front_end_dsl_) {
    msg = "DynamicComponent's dsl is: " +
          std::to_string(component_compile_option.front_end_dsl_) +
          ", while the root's dsl is: " +
          std::to_string(root_compile_options.front_end_dsl_);
    return false;
  }

  if (component_compile_option.arch_option_ !=
      root_compile_options.arch_option_) {
    msg = "DynamicComponent's ArchOption is: " +
          std::to_string(component_compile_option.arch_option_) +
          ", while the root's ArchOption is: " +
          std::to_string(root_compile_options.arch_option_);
    return false;
  }
  return true;
}

TemplateBundle TemplateEntry::CreateTemplateBundle() {
  // In fiber mode, 'page_moulds_' is always empty, and 'encoded_data' is stored
  // in 'lepus_init_data_'.
  lepus::Value encoded_data;
  if (compile_options().enable_fiber_arch_) {
    encoded_data = lepus_init_data_;
  } else {
    auto iter = page_moulds_.find(0);
    encoded_data =
        (iter == page_moulds_.end() ? lepus::Value() : iter->second->data());
  }

  return {name_,
          compile_options_.target_sdk_version_,
          need_global_console_,
          support_component_js_,
          lepus::Value::Clone(encoded_data),
          init_data_,
          js_source_,
          enable_circular_data_check_,
          enable_attribute_timing_flag_};
}

void TemplateEntry::SetTemplateBinaryReader(
    std::unique_ptr<TemplateBinaryReader> reader) {
  reader_ = std::move(reader);
}

bool TemplateEntry::DecodeCSSFragmentById(int32_t fragmentId) {
  if (reader_) {
    return reader_->DecodeCSSFragmentById(fragmentId);
  }
  return false;
}

}  // namespace tasm
}  // namespace lynx
