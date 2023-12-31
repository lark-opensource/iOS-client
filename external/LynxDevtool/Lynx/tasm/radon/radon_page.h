// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_PAGE_H_
#define LYNX_TASM_RADON_RADON_PAGE_H_

#include <memory>
#include <string>
#include <vector>

#include "css/css_fragment.h"
#include "lepus/vm_context.h"
#include "tasm/moulds.h"
#include "tasm/page_delegate.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_component.h"

namespace lynx {
namespace tasm {

class RadonPage : public RadonComponent {
 public:
  RadonPage(PageProxy *proxy, int tid, CSSFragment *style_sheet,
            std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
            PageMould *mould, lepus::Context *context);
  virtual ~RadonPage();

  void UpdateComponentData(const std::string &id, const lepus::Value &table);
  void CreatePage();
  bool UpdatePage(const lepus::Value &table,
                  const UpdatePageOption &update_page_option);
#if LYNX_ENABLE_TRACING
  std::string ConcatUpdateDataInfo(const RadonComponent *comp,
                                   const lepus::Value &table) const;
#endif
  void DeriveFromMould(ComponentMould *data) override;

  virtual void DispatchSelf(const DispatchOption &) override;
  virtual void Dispatch(const DispatchOption &) override;
  virtual void DispatchForDiff(const DispatchOption &) override;
  // for remove component element
  virtual bool NeedsElement() const override { return true; }
  virtual bool UpdateConfig(const lepus::Value &config, bool to_refresh);
  void UpdateSystemInfo(const lynx::lepus::Value &config);
  void Refresh(const DispatchOption &) override;
  void RefreshWithNewStyle(const DispatchOption &) override;
  void SetCSSVariables(const std::string &component_id,
                       const std::string &id_selector,
                       const lepus::Value &properties);

  virtual bool IsPageForBaseComponent() const override { return true; }
  virtual CSSFragment *GetStyleSheetBase(AttributeHolder *holder) override;

  bool NeedsExtraData() const override;

  std::unique_ptr<lepus::Value> GetPageData();

  lepus::Value GetPageDataByKey(const std::vector<std::string> &keys);

  inline void SetEnableSavePageData(bool enable) {
    enable_save_page_data_ = enable;
  }

  inline void SetEnableCheckDataWhenUpdatePage(bool option) {
    enable_check_data_when_update_page_ = option;
  }

  bool RefreshWithGlobalProps(const lepus::Value &table, bool should_render);

  RadonComponent *GetComponent(const std::string &comp_id);

  virtual const std::string &GetEntryName() const override;

  PageProxy *proxy_ = nullptr;
  std::vector<BaseComponent *> radon_component_dispatch_order_;

  void TriggerComponentLifecycleUpdate(const std::string name);
  void ResetComponentDispatchOrder();
  void CollectComponentDispatchOrder(RadonBase *radon_node);

  RadonPage(const RadonPage &) = delete;
  RadonPage(RadonPage &&) = delete;

  RadonPage &operator=(const RadonPage &) = delete;
  RadonPage &operator=(RadonPage &&) = delete;

  void OnScreenMetricsSet(float &width, float &height);
  void SetScreenMetricsOverrider(const lepus::Value &overrider);

  // Bind the page logic to the page reconstructed from ssr data
  void Hydrate();

 protected:
  void OnReactComponentDidUpdate(const DispatchOption &option) override;

 private:
  bool UpdatePageData(const std::string &name, const lepus::Value &value,
                      const bool update_top_var = false);
  bool ResetPageData();
  bool PrePageRender(const lepus::Value &data);
  bool PrePageRenderReact(const lepus::Value &data);
  bool PrePageRenderTT(const lepus::Value &data);
  bool ForcePreprocessPageData(const lepus::Value &updated_data,
                               lepus::Value &merged_data);
  bool ShouldKeepPageData();
  bool enable_save_page_data_{false};
  bool enable_check_data_when_update_page_{true};
  lepus::Value get_override_screen_metrics_function_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_PAGE_H_
