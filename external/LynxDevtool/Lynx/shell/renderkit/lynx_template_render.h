// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_LYNX_TEMPLATE_RENDER_H_
#define LYNX_SHELL_RENDERKIT_LYNX_TEMPLATE_RENDER_H_

#include <list>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "shell/renderkit/devtool_wrapper/lynx_devtool.h"
#include "shell/renderkit/js_proxy_renderkit.h"
#include "shell/renderkit/lynx_context.h"
#include "shell/renderkit/lynx_resource_provider_registry.h"
#include "shell/renderkit/public/lynx_basic_types.h"
#include "shell/renderkit/public/lynx_template_data.h"
#include "shell/renderkit/public/lynx_view_builder.h"
#include "shell/renderkit/public/lynx_view_client.h"
#include "shell/renderkit/public/template_render_callback.h"
#include "tasm/react/renderkit/layout_context_desktop.h"

namespace lynx {
namespace shell {
class LynxShell;
class ModuleDelegateImpl;
class VSyncMonitor;
}  // namespace shell

namespace piper {
class ModuleManagerDesktop;
template <typename>
class ModuleManagerRenderkit;
}  // namespace piper

class LynxViewBase;

class LynxTemplateRender : public TemplateRenderCallback,
                           public tasm::PageLoadCallback {
 public:
  LynxTemplateRender();
  ~LynxTemplateRender();

  void Init(LynxViewBaseBuilder& builder, LynxViewBase* view);
  void Reset();

  void Destroy();

  void UpdateScreenMetrics(float width, float height, float device_ratio);
  void UpdateFontScale(float scale);

  void TriggerLayout();
  void UpdateViewport(bool need_layout);

  void LoadTemplate(std::vector<uint8_t> source, const std::string& url,
                    LynxTemplateData* init_data);
  void LoadComponent(const std::string& source, const std::string& url,
                     int32_t callback_id);
  void LoadDynamicComponent(const std::string& source, const std::string& url,
                            int32_t callback_id);
  void LoadScriptAsync(const std::string& source, const std::string& url,
                       int32_t callback_id);
  void UpdateDataWithTemplateData(LynxTemplateData* data);
  void UpdateDataWithString(const std::string& data,
                            const std::string& processor_name);

  void ResetDataWithTemplateData(LynxTemplateData* data);

  LynxViewBaseSizeMode GetLayoutWidthMode();
  LynxViewBaseSizeMode GetLayoutHeightMode();
  void SetLayoutWidthMode(LynxViewBaseSizeMode mode);
  void SetLayoutHeightMode(LynxViewBaseSizeMode mode);

  float GetPreferredLayoutWidth() const;
  float GetPreferredLayoutHeight() const;
  void SetPreferredLayoutWidth(float value);
  void SetPreferredLayoutHeight(float value);

  float GetPreferredMaxLayoutWidth() const;
  float GetPreferredMaxLayoutHeight() const;
  void SetPreferredMaxLayoutWidth(float value);
  void SetPreferredMaxLayoutHeight(float value);

  void AddLynxViewBaseClient(LynxViewClient* client);
  void RemoveLynxViewBaseClient(LynxViewClient* client);

  void OnLoaded(const std::string& url) override;
  void OnRuntimeReady() override;
  void OnDataUpdated() override;
  void OnPageChanged(bool is_first_screen) override;
  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;
  void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;
  void onErrorOccurred(int32_t error_code, const std::string& message) override;
  void onThemeUpdatedByJs(
      const std::unordered_map<std::string, std::string>& theme) override;

  void OnLayoutFinish() override;
  void OnPageUpdate() override;

  void OnUpdateDataWithoutChange() override;

  void SetGlobalProps(const LynxTemplateData& data);

  void SendGlobalEvent(const std::string& name, const std::string& json_params);
  void SendGlobalEvent(const std::string& name, const EncodableList& _params);

  void OnEnterForeground();
  void OnEnterBackground();

  std::unordered_map<std::string, std::string> GetAllJsSource();

 private:
  void PrepareEnvWidthScreenSize(int width, int height);
  void PrepareShell();
  void InitJSBridge();

  void DispatchOnPageStart(const std::string& url);

  using ModuleManagerPtr = std::shared_ptr<
      lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDesktop>>;

  void RegisterNativeModules(
      const ModuleManagerPtr& module_manager,
      const std::shared_ptr<lynx::shell::ModuleDelegateImpl>& module_delegate);

  void RegisterNativeModulesX(
      const ModuleManagerPtr& module_manager,
      const std::shared_ptr<lynx::shell::ModuleDelegateImpl>& module_delegate);

 private:
  std::unique_ptr<lynx::shell::LynxShell> shell_;
  std::shared_ptr<lynx::shell::JsProxyRenderkit> js_proxy_;
  LynxViewBase* lynx_view_{};

  LynxViewBaseSizeMode layout_width_mode_{};
  LynxViewBaseSizeMode layout_height_mode_{};

  float preferred_max_layout_width_{};
  float preferred_max_layout_height_{};
  float preferred_layout_width_{};
  float preferred_layout_height_{};

  bool has_started_load_ = false;
  bool enable_pre_update_data_ = false;
  std::list<LynxViewClient*> view_clients_;
  std::shared_ptr<
      lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDesktop>>
      module_manager_;
  std::unique_ptr<LynxConfig> config_;
  std::unique_ptr<LynxConfig> global_config_;
  std::unique_ptr<LynxContext> lynx_context_;
  std::shared_ptr<lynx::shell::VSyncMonitor> vsync_monitor_;
  std::unique_ptr<lynx::LynxDevtool> devtool_;
  std::unique_ptr<LynxGroup> group_;
  std::unique_ptr<LynxProviderRegistry> resource_provider_registry_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_LYNX_TEMPLATE_RENDER_H_
