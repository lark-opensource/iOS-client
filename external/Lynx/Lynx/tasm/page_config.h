// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_PAGE_CONFIG_H_
#define LYNX_TASM_PAGE_CONFIG_H_

#include <ostream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>

#include "css/parser/css_parser_configs.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"
#include "starlight/types/layout_configs.h"
#include "tasm/compile_options.h"
#include "tasm/config.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/generator/version.h"
#include "tasm/react/dynamic_css_configs.h"

namespace lynx {
namespace tasm {
enum TernaryBool { TRUE_VALUE, FALSE_VALUE, UNDEFINE_VALUE };

/**
 * EntryConfig provide an independent config for entry.
 * Usually, a dynamic component / card corresponds to an entry.
 */
class EntryConfig {
 public:
  EntryConfig() = default;
  virtual ~EntryConfig() = default;

  // layout configs
  inline const starlight::LayoutConfigs& GetLayoutConfigs() {
    return layout_configs_;
  }

  // default display linear
  inline void SetDefaultDisplayLinear(bool is_linear) {
    default_display_linear_ = is_linear;
    layout_configs_.default_display_linear_ = is_linear;
  }
  inline bool GetDefaultDisplayLinear() { return default_display_linear_; }

 protected:
  starlight::LayoutConfigs layout_configs_;

 private:
  bool default_display_linear_{false};
};

/**
 * PageConfig hold overall configs of a page.
 */
class PageConfig final : public EntryConfig {
 public:
  // 为了兼容之前老的逻辑，如果index.json没定义"flatten"，默认打开
  // 兼容旧逻辑，默认开启auto-expose.
  PageConfig()
      : page_flatten(true),
        dsl_(PackageInstanceDSL::TT),
        enable_auto_show_hide(true),
        bundle_module_mode_(PackageInstanceBundleModuleMode::EVAL_REQUIRE_MODE),
        enable_async_display_(true),
        enable_view_receive_touch_(false),
        enable_lepus_strict_check_(false),
        enable_event_through_(false),
        need_remove_component_element_(false){};

  ~PageConfig() override = default;

  std::unordered_map<std::string, std::string> GetPageConfigMap() {
    std::unordered_map<std::string, std::string> map;
    map.insert({"page_flatten", page_flatten ? "true" : "false"});
    map.insert({"target_sdk_version", target_sdk_version_});
    map.insert({"radon_mode", radon_mode_});
    map.insert({"enable_lepus_ng", enable_lepus_ng_ ? "true" : "false"});
    map.insert({"react_version", react_version_});
    map.insert({"enable_css_parser", enable_css_parser_ ? "true" : "false"});
    map.insert({"absetting_disable_css_lazy_decode",
                absetting_disable_css_lazy_decode_});
    if (!trial_options_.IsNil() && trial_options_.Table()->size() != 0) {
      auto trial_options_table = trial_options_.Table();
      map.insert({"user", trial_options_table->begin()
                              ->second.Table()
                              ->GetValue("username")
                              .String()
                              ->c_str()});
      map.insert({"git", trial_options_table->begin()
                             ->second.Table()
                             ->GetValue("git")
                             .String()
                             ->c_str()});
      map.insert({"file_path", trial_options_table->begin()
                                   ->second.Table()
                                   ->GetValue("entry")
                                   .String()
                                   ->c_str()});
      for (auto& feature : *trial_options_table) {
        map.insert({feature.first.c_str(), "true"});
      }
    }
    return map;
  }

  inline void SetVersion(const std::string& version) { page_version = version; }

  inline std::string GetVersion() { return page_version; }

  inline void SetGlobalFlattern(bool flattern) { page_flatten = flattern; }

  inline void SetEnableA11yIDMutationObserver(bool enable) {
    enable_a11y_mutation_observer = enable;
  }

  inline void SetEnableA11y(bool enable) { enable_a11y = enable; }

  inline void SetGlobalImplicit(bool implicit) { page_implicit = implicit; }

  inline bool GetGlobalFlattern() { return page_flatten; }

  inline bool GetEnableA11yIDMutationObserver() {
    return enable_a11y_mutation_observer;
  }

  inline bool GetEnableA11y() { return enable_a11y; }

  inline bool GetGlobalImplicit() { return page_implicit; }

  inline void SetDSL(PackageInstanceDSL dsl) { dsl_ = dsl; }

  inline void SetAutoExpose(bool enable) { enable_auto_show_hide = enable; }

  inline void SetDataStrictMode(bool strict) { data_strict_mode = strict; }

  inline void SetAbsoluteInContentBound(bool enable) {
    layout_configs_.is_absolute_in_content_bound_ = enable;
  }

  inline bool GetAbsoluteInContentBound() {
    return layout_configs_.is_absolute_in_content_bound_;
  }

  inline void SetQuirksMode(bool enable) {
    if (css_align_with_legacy_w3c_ || !enable) {
      layout_configs_.SetQuirksMode(kQuirksModeDisableVersion);
    } else {
      layout_configs_.SetQuirksMode(kQuirksModeEnableVersion);
    }
  }
  inline bool GetQuirksMode() const {
    return layout_configs_.IsFullQuirksMode();
  }

  inline void SetQuirksModeByString(const std::string& version) {
    if (css_align_with_legacy_w3c_) {
      layout_configs_.SetQuirksMode(kQuirksModeDisableVersion);
    } else {
      layout_configs_.SetQuirksMode(version);
    }
  }
  inline tasm::Version GetQuirksModeVersion() const {
    return layout_configs_.GetQuirksMode();
  }

  inline bool GetAutoExpose() { return enable_auto_show_hide; }

  inline bool GetDataStrictMode() { return data_strict_mode; }

  inline void SetDefaultOverflowVisible(bool is_visible) {
    default_overflow_visible_ = is_visible;
  }

  inline bool GetDefaultOverflowVisible() { return default_overflow_visible_; }

  inline const tasm::DynamicCSSConfigs& GetDynamicCSSConfigs() {
    return css_configs_;
  }

  inline PackageInstanceDSL GetDSL() { return dsl_; }

  inline void SetBundleModuleMode(
      PackageInstanceBundleModuleMode bundle_module_mode) {
    bundle_module_mode_ = bundle_module_mode;
  }

  inline PackageInstanceBundleModuleMode GetBundleModuleMode() {
    return bundle_module_mode_;
  }

  inline void SetEnableAsyncDisplay(bool enable) {
    enable_async_display_ = enable;
  }

  inline bool GetEnableAsyncDisplay() { return enable_async_display_; }

  inline void SetEnableImageDownsampling(bool enable) {
    enable_image_downsampling_ = enable;
  }

  inline bool GetEnableImageDownsampling() {
    return enable_image_downsampling_;
  }

  inline void SetEnableNewImage(bool enable) { enable_New_Image_ = enable; }

  inline bool GetEnableNewImage() { return enable_New_Image_; }

  inline void SetTrailNewImage(bool enable) { trail_New_Image_ = enable; }

  inline bool GetTrailNewImage() { return trail_New_Image_; }

  inline void SetEnableTextLanguageAlignment(bool enable) {
    enable_text_language_alignment_ = enable;
  }

  inline bool GetEnableTextLanguageAlignment() {
    return enable_text_language_alignment_;
  }
  inline void SetEnableXTextLayoutReused(bool enable) {
    enable_x_text_layout_reused_ = enable;
  }
  inline bool GetEnableXTextLayoutReused() {
    return enable_x_text_layout_reused_;
  }

  inline void SetRedBoxImageSizeWarningThreshold(uint32_t threshold) {
    red_box_image_size_warning_threshold_ = threshold;
  }

  inline uint32_t GetRedBoxImageSizeWarningThreshold() {
    return red_box_image_size_warning_threshold_;
  }

  inline void SetEnableTextNonContiguousLayout(bool enable) {
    enable_text_non_contiguous_layout_ = enable;
  }

  inline bool GetEnableTextNonContiguousLayout() {
    return enable_text_non_contiguous_layout_;
  }

  inline void SetEnableViewReceiveTouch(bool enable) {
    enable_view_receive_touch_ = enable;
  }

  inline bool GetEnableViewReceiveTouch() { return enable_view_receive_touch_; }

  inline void SetEnableLepusStrictCheck(bool enable) {
    enable_lepus_strict_check_ = enable;
  }

  inline void SetLepusQuickjsStackSize(uint32_t stack_size) {
    lepus_quickjs_stack_size_ = stack_size;
  }

  inline void SetEnableLepusNullPropAsUndef(bool enable) {
    enable_lepus_null_prop_as_undef_ = enable;
  }

  inline void SetFontScaleSpOnly(bool font_scale) {
    layout_configs_.font_scale_sp_only_ = font_scale;
  }

  inline bool GetFontScaleSpOnly() {
    return layout_configs_.font_scale_sp_only_;
  }

  bool GetEnableLepusStrictCheck() { return enable_lepus_strict_check_; }

  bool GetLepusQuickjsStackSize() { return lepus_quickjs_stack_size_; }

  bool GetEnableLepusNullPropAsUndef() {
    return enable_lepus_null_prop_as_undef_;
  }

  void SetEnableEventThrough(bool enable) { enable_event_through_ = enable; }

  bool GetEnableEventThrough() { return enable_event_through_; }

  void SetEnableSimultaneousTap(bool enable) {
    enable_simultaneous_tap_ = enable;
  }

  bool GetEnableSimultaneousTap() { return enable_simultaneous_tap_; }

  void SetEnableTouchRefactor(bool enable) { enable_touch_refactor_ = enable; }

  bool GetEnableTouchRefactor() { return enable_touch_refactor_; }

  void SetEnableEndGestureAtLastFingerUp(bool enable) {
    enable_end_gesture_at_last_finger_up_ = enable;
  }

  bool GetEnableEndGestureAtLastFingerUp() {
    return enable_end_gesture_at_last_finger_up_;
  }

  void SetRemoveComponentElement(bool need) {
    need_remove_component_element_ = need;
  }
  bool GetRemoveComponentElement() const {
    return need_remove_component_element_;
  }

  void SetStrictPropType(bool enable) { strict_prop_type_ = enable; }
  bool GetStrictPropType() const { return strict_prop_type_; }

  void SetEnableCSSInheritance(bool enable) {
    css_configs_.enable_css_inheritance_ = enable;
  }

  bool GetEnableCSSInheritance() {
    return css_configs_.enable_css_inheritance_;
  }

  void SetCustomCSSInheritList(std::unordered_set<CSSPropertyID>&& list) {
    css_configs_.custom_inherit_list_ =
        std::forward<std::unordered_set<CSSPropertyID>>(list);
  }

  const std::unordered_set<CSSPropertyID>& GetCustomCSSInheritList() {
    return css_configs_.custom_inherit_list_;
  }

  void SetEnableNewLayoutOnly(bool enable) { enable_new_layout_only_ = enable; }
  bool GetEnableNewLayoutOnly() const { return enable_new_layout_only_; }

  bool GetCSSAlignWithLegacyW3C() const { return css_align_with_legacy_w3c_; }
  void SetCSSAlignWithLegacyW3C(bool val) {
    css_align_with_legacy_w3c_ = val;
    layout_configs_.css_align_with_legacy_w3c_ = val;
    if (val) {
      layout_configs_.SetQuirksMode(kQuirksModeDisableVersion);
    }
  }

  // TODO(liting.src): just a workaround to leave below APIs for ssr
  bool GetEnableLocalAsset() const { return false; }
  void SetEnableLocalAsset(bool val) {}

  bool GetEnableComponentLifecycleAlignWebview() {
    return enable_component_lifecycle_align_webview_;
  }
  void SetEnableComponentLifecycleAlignWebview(bool val) {
    enable_component_lifecycle_align_webview_ = val;
  }

  void SetUseNewImage(TernaryBool enable) { use_new_image = enable; }
  TernaryBool GetUseNewImage() const { return use_new_image; }

  void SetAsyncRedirectUrl(bool async) { async_redirect_url = async; }
  bool GetAsyncRedirectUrl() const { return async_redirect_url; }

  void SetSyncImageAttach(bool enable) { sync_image_attach = enable; }
  bool GetSyncImageAttach() const { return sync_image_attach; }

  void SetUseImagePostProcessor(bool enable) {
    use_image_post_processor_ = enable;
  }
  bool GetUseImagePostProcessor() const { return use_image_post_processor_; }

  inline void SetCliVersion(const std::string& cli_version) {
    cli_version_ = cli_version;
  }
  inline std::string GetCliVersion() { return cli_version_; }

  inline void SetCustomData(const std::string& custom_data) {
    custom_data_ = custom_data;
  }
  inline std::string GetCustomData() { return custom_data_; }

  void SetUseNewSwiper(bool enable) { use_new_swiper = enable; }

  bool GetUseNewSwiper() const { return use_new_swiper; }

  void SetEnableAsyncInitTTVideoEngine(bool enable) {
    async_init_tt_video_engine = enable;
  }

  bool GetEnableAsyncInitTTVideoEngine() const {
    return async_init_tt_video_engine;
  }

  void SetEnableCSSStrictMode(bool enable) {
    css_parser_configs_.enable_css_strict_mode = enable;
  }

  bool GetEnableCSSStrictMode() {
    return css_parser_configs_.enable_css_strict_mode;
  }

  inline const CSSParserConfigs& GetCSSParserConfigs() {
    return css_parser_configs_;
  }

  void SetCSSParserConfigs(const CSSParserConfigs& config) {
    css_parser_configs_ = config;
  }

  inline void SetTargetSDKVersion(const std::string& target_sdk_version) {
    target_sdk_version_ = target_sdk_version;
    layout_configs_.target_sdk_version = target_sdk_version;
    SetIsTargetSdkVerionHigherThan21();
  }
  inline std::string GetTargetSDKVersion() { return target_sdk_version_; }

  inline void SetIsTargetSdkVerionHigherThan21() {
    is_target_sdk_verion_higher_than_2_1_ =
        lynx::tasm::Version(target_sdk_version_) >
        lynx::tasm::Version(LYNX_VERSION_2_1);
  }

  inline void SetIsTargetSdkVerionHigherThan21(bool value) {
    is_target_sdk_verion_higher_than_2_1_ = value;
  }

  inline bool GetIsTargetSdkVerionHigherThan21() const {
    return is_target_sdk_verion_higher_than_2_1_;
  }

  inline void SetLepusVersion(const std::string& lepus_version) {
    lepus_version_ = lepus_version;
  }
  inline std::string GetLepusVersion() { return lepus_version_; }

  inline void SetRadonMode(std::string radon_mode) { radon_mode_ = radon_mode; }

  inline std::string GetRadonMode() { return radon_mode_; }

  inline void SetEnableLepusNG(bool enable_lepus_ng) {
    enable_lepus_ng_ = enable_lepus_ng;
  }
  inline bool GetEnableLepusNG() { return enable_lepus_ng_; }

  inline void SetTapSlop(const std::string& tap_slop) { tap_slop_ = tap_slop; }

  inline const std::string& GetTapSlop() { return tap_slop_; }

  void SetEnableCreateViewAsync(bool enable) {
    enable_create_view_async_ = enable;
  }

  void SetEnableVsyncAlignedFlush(bool enable) {
    enable_vsync_aligned_flush = enable;
  }

  bool GetEnableCreateViewAsync() const { return enable_create_view_async_; }

  bool GetEnableVsyncAlignedFlush() const { return enable_vsync_aligned_flush; }

  void SetEnableSavePageData(bool enable) { enable_save_page_data_ = enable; }

  bool GetEnableSavePageData() { return enable_save_page_data_; }
  void SetListNewArchitecture(bool list_new_architecture) {
    list_new_architecture_ = list_new_architecture;
  }

  bool GetListNewArchitecture() { return list_new_architecture_; }

  void SetListRemoveComponent(bool list_remove_component) {
    list_remove_component_ = list_remove_component;
  }
  bool GetListRemoveComponent() { return list_remove_component_; }

  void SetEnableListMoveOperation(bool list_enable_move) {
    list_enable_move_operation_ = list_enable_move;
  }

  bool GetEnableListMoveOperation() { return list_enable_move_operation_; }

  void SetEnableListPlug(bool list_enable_plug) {
    list_enable_plug_ = list_enable_plug;
  }

  bool list_enable_plug() { return list_enable_plug_; }

  void SetEnableAccessibilityElement(bool enable) {
    enable_accessibility_element_ = enable;
  }

  bool GetEnableAccessibilityElement() const {
    return enable_accessibility_element_;
  }

  void SetEnableOverlapForAccessibilityElement(bool enable) {
    enable_overlap_for_accessibility_element_ = enable;
  }

  bool GetEnableOverlapForAccessibilityElement() const {
    return enable_overlap_for_accessibility_element_;
  }

  void SetEnableNewAccessibility(bool enable) {
    enable_new_accessibility_ = enable;
  }

  bool GetEnableNewAccessibility() const { return enable_new_accessibility_; }

  inline void SetReactVersion(const std::string& react_version) {
    react_version_ = react_version;
  }
  inline std::string GetReactVersion() { return react_version_; }
  inline bool GetEnableTextRefactor() { return enable_text_refactor_; }
  void SetEnableTextRefactor(bool enable_text_refactor) {
    enable_text_refactor_ = enable_text_refactor;
  }

  void SetUnifyVWVH(bool unify) { css_configs_.unify_vw_vh_behavior_ = unify; }
  bool GetUnifyVWVH() { return css_configs_.unify_vw_vh_behavior_; }

  inline bool GetEnableZIndex() { return enable_z_index_; }
  inline void SetEnableZIndex(bool enable) { enable_z_index_ = enable; }

  inline bool GetEnableReactOnlyPropsId() const {
    return enable_react_only_props_id_;
  }
  inline void SetEnableReactOnlyPropsId(bool enable) {
    enable_react_only_props_id_ = enable;
  }

  inline bool GetEnableGlobalComponentMap() const {
    return enable_global_component_map_;
  }
  inline void SetEnableGlobalComponentMap(bool enable) {
    enable_global_component_map_ = enable;
  }

  inline bool GetEnableRemoveComponentExtraData() const {
    return enable_remove_component_extra_data_;
  }
  inline void SetEnableRemoveComponentExtraData(bool enable) {
    enable_remove_component_extra_data_ = enable;
  }

  inline void SetGlobalAutoResumeAnimation(bool enable_auto_resume) {
    auto_resume_animation_ = enable_auto_resume;
  }
  inline bool GetGlobalAutoResumeAnimation() { return auto_resume_animation_; }

  inline void SetGlobalEnableNewTransformOrigin(
      bool enable_new_transform_origin) {
    enable_new_transform_origin_ = enable_new_transform_origin;
  }
  inline bool GetGlobalEnableNewTransformOrigin() {
    return enable_new_transform_origin_;
  }
  inline void SetGlobalCircularDataCheck(bool enable_circular_data_check) {
    enable_circular_data_check_ = enable_circular_data_check;
  }
  inline bool GetGlobalCircularDataCheck() {
    return enable_circular_data_check_;
  }

  inline bool GetEnableLynxAir() { return enable_lynx_air_; }
  inline void SetEnableLynxAir(bool enable) { enable_lynx_air_ = enable; }
  inline bool GetEnableFiberArch() { return enable_fiber_arch_; }
  inline void SetEnableFiberArch(bool enable) { enable_fiber_arch_ = enable; }
  inline bool GetEnableTextLayerRender() { return enable_text_layer_render_; }

  void SetEnableTextLayerRender(bool enable_text_layer_render) {
    enable_text_layer_render_ = enable_text_layer_render;
  }

  inline bool GetEnableReduceInitDataCopy() {
    return enable_reduce_init_data_copy_;
  }
  inline void SetEnableReduceInitDataCopy(bool enable) {
    enable_reduce_init_data_copy_ = enable;
  }
  inline bool GetDisablePerfCollector() { return disable_perf_collector_; }
  inline void SetDisablePerfCollector(bool disable) {
    disable_perf_collector_ = disable;
  }
  inline bool GetEnableCSSParser() { return enable_css_parser_; }
  inline void SetEnableCSSParser(bool enable) { enable_css_parser_ = enable; }

  inline std::string GetAbSettingDisableCSSLazyDecode() {
    return absetting_disable_css_lazy_decode_;
  }
  inline void SetAbSettingDisableCSSLazyDecode(std::string disable) {
    absetting_disable_css_lazy_decode_ = disable;
  }

  inline void SetKeyboardCallbackUseRelativeHeight(bool enable) {
    keyboard_callback_pass_relative_height_ = enable;
  }

  inline bool GetKeyboardCallbackUseRelativeHeight() const {
    return keyboard_callback_pass_relative_height_;
  }

  inline void SetEnableEventRefactor(bool option) {
    enable_event_refactor_ = option;
  }

  bool GetEnableEventRefactor() const { return enable_event_refactor_; }

  inline void SetForceCalcNewStyle(bool option) {
    force_calc_new_style_ = option;
  }

  bool GetForceCalcNewStyle() const { return force_calc_new_style_; }

  inline void SetCompileRender(bool option) { compile_render_ = option; }

  bool GetCompileRender() const { return compile_render_; }

  inline void SetDisableLongpressAfterScroll(bool value) {
    disable_longpress_after_scroll_ = value;
  }

  inline bool GetDisableLongpressAfterScroll() {
    return disable_longpress_after_scroll_;
  }

  inline void SetEnableCheckDataWhenUpdatePage(bool option) {
    enable_check_data_when_update_page_ = option;
  }

  bool GetEnableCheckDataWhenUpdatePage() const {
    return enable_check_data_when_update_page_;
  }

  inline void SetTrialOptions(const lepus_value& option) {
    trial_options_ = option;
  }

  inline lepus_value GetTrialOptions() const { return trial_options_; }

  bool GetTextNewEventDispatch() const { return text_new_event_dispatch_; }

  void SetTextNewEventDispatch(bool value) { text_new_event_dispatch_ = value; }

  int32_t GetIncludeFontPadding() const { return include_font_padding_; }

  void SetIncludeFontPadding(bool value) {
    include_font_padding_ = value ? 1 : -1;
  }

  inline void SetEnableNewIntersectionObserver(bool option) {
    enable_new_intersection_observer_ = option;
  }

  inline bool GetEnableNewIntersectionObserver() const {
    return enable_new_intersection_observer_;
  }

  inline void SetObserverFrameRate(int32_t option) {
    observer_frame_rate_ = option;
  }

  inline int32_t GetObserverFrameRate() const { return observer_frame_rate_; }

  inline void SetEnableCheckExposureOptimize(
      bool enable_check_exposure_optimize) {
    enable_check_exposure_optimize_ = enable_check_exposure_optimize;
  }

  inline bool GetEnableCheckExposureOptimize() const {
    return enable_check_exposure_optimize_;
  }

  inline void SetEnableDisexposureWhenLynxHidden(
      bool enable_disexposure_when_lynx_hidden) {
    enable_disexposure_when_lynx_hidden_ = enable_disexposure_when_lynx_hidden;
  }

  inline bool GetEnableDisexposureWhenLynxHidden() const {
    return enable_disexposure_when_lynx_hidden_;
  }

  inline void SetEnableExposureUIMargin(bool option) {
    enable_exposure_ui_margin_ = option;
  }

  inline bool GetEnableExposureUIMargin() const {
    return enable_exposure_ui_margin_;
  }

  inline void SetLongPressDuration(int32_t option) {
    long_press_duration_ = option;
  }

  inline int32_t GetLongPressDuration() const { return long_press_duration_; }

  inline void SetEnableCheckLocalImage(bool option) {
    enable_check_local_image_ = option;
  }

  inline bool GetEnableCheckLocalImage() const {
    return enable_check_local_image_;
  }

  inline void SetEnableComponentLayoutOnly(bool enable) {
    enable_component_layout_only_ = enable;
  }

  inline bool GetEnableComponentLayoutOnly() {
    return enable_component_layout_only_;
  }

  inline void SetEnableBackgroundShapeLayer(bool enable) {
    enable_background_shape_layer_ = enable;
  }

  inline bool GetEnableBackgroundShapeLayer() {
    return enable_background_shape_layer_;
  }

  inline void SetLynxAirMode(CompileOptionAirMode air_mode) {
    air_mode_ = air_mode;
  }

  inline CompileOptionAirMode GetLynxAirMode() { return air_mode_; }

  inline void SetEnableLynxResourceServiceProvider(bool option) {
    enable_lynx_resource_service_provider_ = option;
  }

  inline bool GetEnableLynxResourceServiceProvider() {
    return enable_lynx_resource_service_provider_;
  }

  inline bool GetEnableTextOverflow() { return enable_text_overflow_; }
  void SetEnableTextOverflow(bool enable_text_overflow) {
    enable_text_overflow_ = enable_text_overflow;
  }

  inline bool GetEnableNewClipMode() { return enable_new_clip_mode_; }
  void SetEnableNewClipMode(bool enable_new_clip_mode) {
    enable_new_clip_mode_ = enable_new_clip_mode;
  }

  inline bool GetEnableCascadePseudo() const { return enable_cascade_pseudo_; }
  inline void SetEnableCascadePseudo(bool value) {
    enable_cascade_pseudo_ = value;
  }

  inline lepus::Value GetExtraInfo() const { return extra_info_; }

  inline void SetExtraInfo(lepus::Value extra_info) {
    extra_info_ = extra_info;
  }

  int64_t GetLepusGCThreshold() { return lepus_gc_threshold_; }
  void SetLepusGCThreshold(int64_t value) { lepus_gc_threshold_ = value; }

  inline bool GetEnableAttributeTimingFlag() const {
    return enable_attribute_timing_flag_;
  }

  void SetEnableAttributeTimingFlag(bool enable_attribute_timing_flag) {
    enable_attribute_timing_flag_ = enable_attribute_timing_flag;
  }

  inline bool GetEnableComponentNullProp() const {
    return enable_component_null_prop_;
  }

  inline void SetEnableComponentNullProp(bool enable_component_null_prop) {
    enable_component_null_prop_ = enable_component_null_prop;
  }

  inline bool GetEnableCSSInvalidation() const {
    return enable_css_invalidation_;
  }

  inline void SetEnableCSSInvalidation(bool enable) {
    enable_css_invalidation_ = enable;
  }

  bool GetRemoveDescendantSelectorScope() const {
    return remove_descendant_selector_scope_;
  }

  void SetRemoveDescendantSelectorScope(bool enable) {
    remove_descendant_selector_scope_ = enable;
  }

#ifdef ENABLE_TEST_DUMP
  void PrintPageConfig(std::ostream& output) {
#define PAGE_CONFIG_DUMP(key) output << #key << ":" << key << ",";
    PAGE_CONFIG_DUMP(page_version)
    PAGE_CONFIG_DUMP(page_flatten)
    PAGE_CONFIG_DUMP(page_implicit)
    output << "dsl_:" << static_cast<int>(dsl_) << ",";
    PAGE_CONFIG_DUMP(enable_auto_show_hide)
    output << "bundle_module_mode_:" << static_cast<int>(bundle_module_mode_)
           << ",";
    PAGE_CONFIG_DUMP(enable_async_display_)
    PAGE_CONFIG_DUMP(enable_view_receive_touch_)
    PAGE_CONFIG_DUMP(enable_lepus_strict_check_)
    PAGE_CONFIG_DUMP(enable_event_through_)
    PAGE_CONFIG_DUMP(layout_configs_.is_absolute_in_content_bound_)
    output << "layout_configs_.quirks_mode_:"
           << layout_configs_.IsFullQuirksMode() << ",";
    PAGE_CONFIG_DUMP(css_parser_configs_.enable_css_strict_mode)
#undef PAGE_CONFIG_DUMP
  }

  std::string StringifyPageConfig() {
    std::ostringstream output;
    PrintPageConfig(output);
    return output.str();
  }
#endif
 private:
  std::string page_version;
  bool page_flatten;
  bool enable_a11y_mutation_observer{false};
  bool enable_a11y{false};
  bool page_implicit{true};
  PackageInstanceDSL dsl_;
  bool enable_auto_show_hide;
  PackageInstanceBundleModuleMode bundle_module_mode_;
  bool enable_async_display_;
  bool enable_image_downsampling_{false};
  bool enable_New_Image_{true};
  bool enable_text_language_alignment_{false};
  bool enable_x_text_layout_reused_{false};
  bool trail_New_Image_{false};
  bool enable_view_receive_touch_;
  bool enable_lepus_strict_check_;
  uint32_t lepus_quickjs_stack_size_ = 0;
  // default big image warning threshold, adjust it if necessary
  uint32_t red_box_image_size_warning_threshold_ = 1000000;
  bool enable_event_through_;
  bool enable_simultaneous_tap_{false};
  // Default value is false. If this flag is true, the external gesture which's
  // state is possible or began will not cancel the Lynx iOS touch gesture see
  // issue:#7920.
  bool enable_touch_refactor_{false};
  // In the previous commit, when determining whether all fingers had moved off
  // the screen in multiple touch scenarios, touch.view was used for judgment.
  // However, in a scrolling container, touch.view obtained from
  // touchesEnd/touchesMove could be nil, resulting in incorrect judgment of
  // whether all fingers had moved off the screen. _touches could not be
  // cleared, leading to a subsequent failure to trigger tap events.
  // To fix this issue, we added null checks before calling touch.view, and
  // ended the gesture if _touches was empty. This resolved the problem.
  // only for ios, detail can see f-12375631 and its mr.
  bool enable_end_gesture_at_last_finger_up_{false};
  bool enable_lepus_null_prop_as_undef_{false};
  bool enable_text_non_contiguous_layout_{true};
  bool need_remove_component_element_;
  bool strict_prop_type_{false};
  bool enable_new_layout_only_{true};
  bool css_align_with_legacy_w3c_{false};
  bool enable_component_lifecycle_align_webview_{false};
  tasm::DynamicCSSConfigs css_configs_;
  TernaryBool use_new_image{TernaryBool::UNDEFINE_VALUE};
  bool async_redirect_url{false};
  bool sync_image_attach{true};
  bool use_image_post_processor_{false};
  std::string cli_version_;
  std::string custom_data_;
  bool use_new_swiper{false};
  bool async_init_tt_video_engine{false};
  CSSParserConfigs css_parser_configs_;
  std::string target_sdk_version_;
  std::string lepus_version_;
  std::string radon_mode_;
  bool enable_lepus_ng_{true};
  std::string tap_slop_{};
  bool default_overflow_visible_{false};
  bool enable_create_view_async_{true};
  bool enable_vsync_aligned_flush{false};
  bool enable_save_page_data_{false};
  bool list_new_architecture_{false};
  bool list_remove_component_{true};
  bool list_enable_move_operation_{false};
  bool list_enable_plug_{false};
  bool enable_accessibility_element_{true};
  bool enable_overlap_for_accessibility_element_{true};
  bool enable_new_accessibility_{false};
  std::string react_version_;
  bool enable_text_refactor_{false};
  bool data_strict_mode{true};
  bool enable_z_index_{false};
  bool enable_react_only_props_id_{false};
  bool enable_global_component_map_{false};
  bool enable_remove_component_extra_data_{false};
  bool enable_lynx_air_{false};
  bool enable_fiber_arch_{false};
  bool enable_text_layer_render_{false};
  bool auto_resume_animation_{true};
  bool enable_reduce_init_data_copy_{false};
  bool enable_component_layout_only_{false};
  // Disable "PerfCollector" callbacks according to page configuration.
  // default false;
  bool disable_perf_collector_{false};
  bool enable_cascade_pseudo_{false};
  // Used for lynx config
  bool enable_css_parser_{false};
  std::string absetting_disable_css_lazy_decode_;
  // text new touch dispatch
  bool text_new_event_dispatch_{false};
  // default include font padding
  // 1 means true
  // -1 means false
  int32_t include_font_padding_{0};

  // page's target sdk version controller
  bool is_target_sdk_verion_higher_than_2_1_{false};
  bool keyboard_callback_pass_relative_height_{false};
  bool enable_event_refactor_{true};
  bool force_calc_new_style_{true};
  bool enable_check_data_when_update_page_{true};
  bool compile_render_{false};

  // If this flag is true, iOS will not recognize the corresponding long press
  // gesture after triggering scrolling.
  bool disable_longpress_after_scroll_{false};

  bool enable_new_intersection_observer_{false};

  int32_t observer_frame_rate_{20};

  // The switch controlling whether to enable exposure detection optimization.
  bool enable_check_exposure_optimize_{false};

  // The switch controlling whether to enable send disexposure events when
  // lynxview is hidden.
  bool enable_disexposure_when_lynx_hidden_{true};

  bool enable_exposure_ui_margin_{false};

  int32_t long_press_duration_{-1};

  bool enable_check_local_image_{true};

  // If this flag is true ,new transform origin algorithm will apply
  bool enable_new_transform_origin_{true};
  // If this flag is true, circular data check will enable when convert js value
  // to other vale.
  bool enable_circular_data_check_{false};
  // trial options
  lepus_value trial_options_{};

  // Enable iOS background manager to apply shape layer optimization.
  bool enable_background_shape_layer_{true};

  CompileOptionAirMode air_mode_{CompileOptionAirMode::AIR_MODE_OFF};

  // Enable LynxResourceService to fetch external resource.
  bool enable_lynx_resource_service_provider_{false};

  // set text overflow as visible if true
  bool enable_text_overflow_{false};

  // set new clip mode if true
  bool enable_new_clip_mode_{false};

  // user defined extraInfo.
  lepus::Value extra_info_{};

  // gc threshold of lepusNG. Let default value be 256, and the unit is KB.
  int64_t lepus_gc_threshold_{256};

  // Enable FE to set timing flag by attribute
  bool enable_attribute_timing_flag_{false};

  // support component can be passed null props.
  // null props is only be supported in LepusNG now.
  // open this switch to support lepus use null prop.
  bool enable_component_null_prop_{false};

  // support CSS invalidation
  bool enable_css_invalidation_{false};

  // indicate need to remove descendant selector scope
  bool remove_descendant_selector_scope_{false};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_PAGE_CONFIG_H_
