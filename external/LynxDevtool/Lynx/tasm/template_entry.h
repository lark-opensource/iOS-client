//
// Created by bytedance on 2020-03-29.
//

#ifndef LYNX_TASM_TEMPLATE_ENTRY_H_
#define LYNX_TASM_TEMPLATE_ENTRY_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "base/log/logging.h"
#include "config/config.h"
#include "css/css_style_sheet_manager.h"
#include "jsbridge/java_script_debugger.h"
#include "jsbridge/lepus_context_observer.h"
#include "lepus/lepus_global.h"
#include "lepus/vm_context.h"
#include "tasm/base/element_template_info.h"
#include "tasm/binary_decoder/lynx_template_bundle.h"
#include "tasm/moulds.h"
#include "tasm/page_config.h"

namespace lynx {

namespace piper {
class NapiEnvironment;
}

namespace tasm {
class TemplateAssembler;
class TemplateBinaryReader;

struct TemplateBundle {
  TemplateBundle() = default;
  TemplateBundle(
      const std::string& name, const std::string& target_sdk_version,
      bool need_global_console, bool support_component_js,
      const lepus::Value& encoded_data, const lepus::Value& init_data,
      const std::unordered_map<lepus::String, lepus::String>& js_source,
      bool enable_circular_data_check, bool enable_attribute_timing_flag)
      : name(name),
        target_sdk_version(target_sdk_version),
        need_global_console(need_global_console),
        support_component_js(support_component_js),
        encoded_data(encoded_data),
        init_data(init_data),
        js_source(js_source),
        enable_circular_data_check(enable_circular_data_check),
        enable_attribute_timing_flag(enable_attribute_timing_flag) {}

  // move only
  TemplateBundle(const TemplateBundle&) = delete;
  TemplateBundle& operator=(const TemplateBundle&) = delete;
  TemplateBundle(TemplateBundle&&) = default;
  TemplateBundle& operator=(TemplateBundle&&) = default;

  std::string name;
  std::string target_sdk_version;
  bool need_global_console;
  bool support_component_js;
  lepus::Value encoded_data;
  lepus::Value init_data;
  std::unordered_map<lepus::String, lepus::String> js_source;
  bool enable_circular_data_check;
  bool enable_attribute_timing_flag;
};

// base class released after dirived class,
// ensure vm context released after lepus value
class VmContextHolder {
 public:
  explicit VmContextHolder(const std::shared_ptr<lepus::Context> vm_context)
      : vm_context_(vm_context) {}
  virtual ~VmContextHolder() = default;

 protected:
  std::shared_ptr<lepus::Context> vm_context_;
};

class TemplateEntry : public VmContextHolder, public CSSStyleSheetDelegate {
 public:
  TemplateEntry();

  // Caller have to take the ownership for constructed object.
  static std::unique_ptr<TemplateEntry> ConstructEntryWithNoTemplateAssembler(
      std::shared_ptr<lepus::Context> context,
      const std::string& targetSdkVersion);

  bool InitWithTemplateBundle(const std::shared_ptr<TemplateAssembler>& tasm,
                              const LynxTemplateBundle& template_bundle);

  void ConstructContext(TemplateAssembler* assembler, bool isLepusNGBinary);

  bool DoSerializeLepus(const std::shared_ptr<PageConfig>& page_config,
                        const LynxTemplateBundle& template_bundle);

  ~TemplateEntry() override;

  void SetStyleSheetManager(
      const std::shared_ptr<CSSStyleSheetManager>& style_sheet_manager) {
    style_sheet_manager_ = style_sheet_manager;
  }

  void SetPageMoulds(
      const std::unordered_map<int32_t, std::shared_ptr<PageMould>>&
          page_moulds) {
    page_moulds_ = page_moulds;
  }

  void SetComponentMoulds(
      const std::unordered_map<int32_t, std::shared_ptr<ComponentMould>>&
          component_moulds) {
    component_moulds_ = component_moulds;
  }

  void SetDynamicComponentMoulds(
      const std::unordered_map<int32_t, std::shared_ptr<DynamicComponentMould>>&
          dynamic_component_moulds) {
    dynamic_component_moulds_ = dynamic_component_moulds;
  }

  void SetDynamicComponentDeclarations(
      const std::unordered_map<std::string, std::string>&
          dynamic_component_declarations) {
    dynamic_component_declarations_ = dynamic_component_declarations;
  }

  void SetLepusInitData(const lepus::Value& value) { lepus_init_data_ = value; }

  // Get, Only for use, Can't be stored.
  std::shared_ptr<lepus::Context> GetVm() { return vm_context_; }
  std::shared_ptr<CSSStyleSheetManager> GetStyleSheetManager() {
    return style_sheet_manager_;
  }
  std::unordered_map<lepus::String, lepus::String>& GetJSSource() {
    return js_source_;
  }
  std::unordered_map<int32_t, std::shared_ptr<PageMould>>& page_moulds() {
    return page_moulds_;
  }
  std::unordered_map<int32_t, std::shared_ptr<DynamicComponentMould>>&
  dynamic_component_moulds() {
    return dynamic_component_moulds_;
  }

  std::unordered_map<int32_t, std::shared_ptr<ComponentMould>>&
  component_moulds() {
    return component_moulds_;
  }

  inline const std::unordered_map<std::string, int>& component_name_to_id() {
    return component_name_to_id_;
  }

  inline const std::unordered_map<std::string, std::string>
  dynamic_component_declarations() {
    return dynamic_component_declarations_;
  }

  std::string& GetName() { return name_; }

  void SetIsCard(bool is_card) { is_card_ = is_card; }

  const ElementTemplateInfo& GetElementTemplateInfo(const std::string& key);

  const StyleMap& GetParsedStyles(const std::string& key);

  const AirCompStylesMap& GetComponentParsedStyles(const std::string& path);

  void SetAirParsedStylesMap(const AirParsedStylesMap& map) {
    air_parsed_styles_map_ = map;
  }

  void SetInitData(const lepus::Value& init_data, const bool read_only) {
    init_data_ = read_only ? init_data : lepus::Value::Clone(init_data);
  }
  void SetSupportComponentJS(bool support) { support_component_js_ = support; }
  void SetNeedJSGlobalConsole(bool need) { need_global_console_ = need; }
  void SetJSSource(std::unordered_map<lepus::String, lepus::String> source) {
    js_source_ = std::move(source);
  }
  void SetVm(std::shared_ptr<lepus::Context> vm) { vm_context_ = vm; }
  void SetName(std::string name);

  void InitLepusDebugger(const std::shared_ptr<LepusContextObserver>& observer);

  void AddDynamicComponentDeclaration(const std::string& name,
                                      const std::string& path);
  void InvokeLepusBridge(const int32_t callback_id, const lepus::Value& data);

  void ReInit(TemplateAssembler* assembler);

  piper::NapiEnvironment* napi_environment();
  void AttachNapiEnvironment();
  void DetachNapiEnvironment();

  bool IsCompatibleWithRootEntry(const TemplateEntry& root, std::string& msg);
  inline const tasm::CompileOptions& compile_options() const {
    return compile_options_;
  }
  inline void set_compile_options(const tasm::CompileOptions& options) {
    compile_options_ = options;
  }
  void MarkAsyncRendered() { need_async_render_ = false; }
  bool NeedAsyncRender() { return need_async_render_; }
  void SetCircularDataCheck(bool enable_check) {
    enable_circular_data_check_ = enable_check;
  }
  void SetEnableAttributeTimingFlag(bool enable_attribute_timing_flag) {
    enable_attribute_timing_flag_ = enable_attribute_timing_flag;
  }
  void SetTemplateDebugUrl(const std::string& debug_url) {
    template_debug_url_ = debug_url;
  }
  void SetTemplateBinaryReader(std::unique_ptr<TemplateBinaryReader> reader);

  const std::string& GetTemplateDebugUrl() const { return template_debug_url_; }

  TemplateBundle CreateTemplateBundle();

  virtual bool DecodeCSSFragmentById(int32_t fragmentId) override;

  // Apply page_configs to LepusContext.
  bool ApplyConfigsToLepusContext(
      const std::shared_ptr<PageConfig>& page_config,
      const std::string& target_sdk_version);

  bool EnableReuseContext() {
    // EnableReuseContext should only be enabled In FiberArch Now.
    return !is_card_ && compile_options_.enable_fiber_arch_;
  }

  // Execute Binary Function
  bool Execute();

  void SetBinaryEvalResult(lepus::Value result) {
    binary_eval_result_ = result;
  }

  lepus::Value GetBinaryEvalResult() { return binary_eval_result_; }

 public:
  explicit TemplateEntry(std::shared_ptr<lepus::Context>& context,
                         const std::string& targetSdkVersion);

 private:
  void RegisterBuiltin(TemplateAssembler* assembler);
  void UpdateCSSConfig(const std::shared_ptr<PageConfig>& page_config);

  bool is_card_{true};

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manager_;

  std::unordered_map<int32_t, std::shared_ptr<PageMould>> page_moulds_;
  std::unordered_map<int32_t, std::shared_ptr<ComponentMould>>
      component_moulds_;
  std::unordered_map<int32_t, std::shared_ptr<DynamicComponentMould>>
      dynamic_component_moulds_;
  std::unordered_map<std::string, int32_t> component_name_to_id_;
  std::unordered_map<lepus::String, lepus::String> js_source_;
  std::unordered_map<std::string, std::string> dynamic_component_declarations_;

  std::string name_;
  // The variable 'lepus_init_data_' is applied for caching the initial data of
  // the top-level component/ card instance of the Lepus framework in fiber
  // mode, and synchronizing it with JS to prevent any potential breakage.
  lepus::Value lepus_init_data_{};
  lepus::Value init_data_{};  // cache the init template data
  bool need_global_console_ = false;
  bool support_component_js_ = false;
  bool need_async_render_ = true;
  bool enable_circular_data_check_ = false;
  bool enable_attribute_timing_flag_ = false;

  // ElementTemplate info map
  std::unordered_map<std::string, std::shared_ptr<ElementTemplateInfo>>
      element_template_infos_{};
  // ParsedStyles fields
  ParsedStyleMap parsed_styles_map_{};
  tasm::CompileOptions compile_options_{};
  std::string template_debug_url_;
  // Air ParsedStyles field
  AirParsedStylesMap air_parsed_styles_map_;

  // result of entry's lepus.js.
  // now is only used for dynamic component.
  lepus::Value binary_eval_result_{};

  std::unique_ptr<lynx::piper::JavaScriptDebuggerWrapper> debugger_;
  std::unique_ptr<TemplateBinaryReader> reader_;
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;

#if ENABLE_LEPUSNG_WORKLET
  std::unique_ptr<lynx::piper::NapiEnvironment> napi_environment_;
#endif
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_ENTRY_H_
