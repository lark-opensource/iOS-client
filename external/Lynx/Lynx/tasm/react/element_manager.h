// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_ELEMENT_MANAGER_H_
#define LYNX_TASM_REACT_ELEMENT_MANAGER_H_

#include <map>
#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "animation/animation_vsync_proxy.h"
#include "base/any.h"
#include "base/ref_counted.h"
#include "base/threading/task_runner_manufactor.h"
#include "config/config.h"
#include "css/css_variable_handler.h"
#include "inspector/style_sheet.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/css_patching.h"
#include "tasm/page_config.h"
#include "tasm/react/element.h"
#include "tasm/react/element_container.h"
#include "tasm/react/fiber/page_element.h"
#include "tasm/react/layout_context.h"
#include "tasm/react/painting_context.h"
#include "tasm/react/pipeline_option.h"
#include "tasm/react/radon_element.h"

namespace lynx {
namespace shell {
class VSyncMonitor;
}  // namespace shell
namespace tasm {

struct PseudoPlaceHolderStyles;
class PaintingContext;
class PropBundle;
class Element;
class FiberElement;
class ComponentElement;
class ImageElement;
class ListElement;
class NoneElement;
class ScrollElement;
class TextElement;
class RawTextElement;
class ViewElement;
class WrapperElement;
class Catalyzer;
class ElementCache;
class LynxEnvConfig;
class AirElement;
class AirLepusRef;
class AirPageElement;

class HierarchyObserver {
 public:
  virtual ~HierarchyObserver() {}

  virtual intptr_t GetLynxDevtoolFunction() { return 0; }

  virtual void OnDocumentUpdated() {}
  virtual void OnElementNodeAdded(Element *ptr) {}
  virtual void OnElementNodeRemoved(Element *ptr) {}
  virtual void OnElementNodeMoved(Element *ptr) {}
  virtual void OnElementDataModelSetted(Element *ptr,
                                        AttributeHolder *new_node_ptr) {}
  virtual void OnCSSStyleSheetAdded(Element *ptr) {}
  virtual void OnLayoutPerformanceCollected(std::string &performanceStr) {}
  virtual void OnComponentUselessUpdate(const std::string &component_name,
                                        const lepus::Value &properties) {}
  virtual void OnSetNativeProps(Element *ptr, const std::string &name,
                                const std::string &value, bool is_style) {}

  virtual void EnsureUIImplObserver() {}
};

class NodeManager {
 public:
  NodeManager() = default;
  ~NodeManager() = default;
  inline void Record(int id, Element *node) { node_map_[id] = node; }

  inline void Erase(int id) { node_map_.erase(id); }

  inline bool IsActive() const { return !(node_map_.empty()); }

  inline Element *Get(int tag) {
    auto it = node_map_.find(tag);
    if (it != node_map_.end()) {
      return it->second;
    }
    return nullptr;
  }

  void WillDestroy() {
    for (const auto &pair : node_map_) {
      if (pair.second) {
        pair.second->set_will_destroy(true);
      }
    }
    node_map_.clear();
  }

 private:
  std::unordered_map<int, Element *> node_map_;
};

/*
 * ComponentManager is used to map component id into element.
 * ComponentManager is a field of ElementManager.
 */
class ComponentManager {
 public:
  ComponentManager() = default;
  ~ComponentManager() = default;

  inline void Record(const std::string &id, Element *node) {
    component_map_[id] = node;
  }

  inline void Erase(const std::string &id, Element *node) {
    // see issue:#8417, if the component element corresponding to the deleted id
    // is not same as the current element, the deletion operation will not be
    // performed.
    auto iter = component_map_.find(id);
    if (iter == component_map_.end()) {
      return;
    }
    if (node == iter->second) {
      component_map_.erase(iter);
    }
  }

  inline Element *Get(const std::string &id) {
    auto it = component_map_.find(id);
    if (it != component_map_.end()) {
      return it->second;
    }
    return nullptr;
  }

 private:
  std::unordered_map<std::string, Element *> component_map_;
};

class AirNodeManager {
 public:
  AirNodeManager() = default;
  ~AirNodeManager() = default;

#if ENABLE_AIR
  inline void Record(int id, const std::shared_ptr<AirElement> &node) {
    air_node_map_[id] = node;
  }

  inline bool IsActive() const { return !(air_node_map_.empty()); }

  void RecordForLepusId(int id, uint64_t key,
                        base::scoped_refptr<AirLepusRef> node);

  inline void RecordCustomId(const std::string &id, int tag) {
    air_customize_id_map_[id] = tag;
  }

  inline void Erase(int id) { air_node_map_.erase(id); }

  inline void EraseCustomId(const std::string &id) {
    air_customize_id_map_.erase(id);
  }

  void EraseLepusId(int id, AirElement *node);

  inline std::shared_ptr<AirElement> Get(int tag) const {
    auto it = air_node_map_.find(tag);
    if (it != air_node_map_.end()) {
      return it->second;
    }
    return nullptr;
  }

  base::scoped_refptr<AirLepusRef> GetForLepusId(int tag, uint64_t key);

  const std::vector<base::scoped_refptr<AirLepusRef>> GetAllNodesForLepusId(
      int tag) const;

  inline const std::shared_ptr<AirElement> GetCustomId(std::string tag) const {
    auto it = air_customize_id_map_.find(tag);
    if (it != air_customize_id_map_.end()) {
      return Get(it->second);
    }
    return nullptr;
  }

 private:
  std::unordered_map<int, std::shared_ptr<AirElement>> air_node_map_;
  std::unordered_map<
      int, std::map<uint64_t,
                    base::scoped_refptr<base::RefCountedThreadSafeStorage>>>
      air_lepus_id_map_;
  std::unordered_map<std::string, int> air_customize_id_map_;
#endif
};

using ShadowNodeCreator =
    std::function<int(int, intptr_t, const std::string &, PropBundle *,
                      bool is_parent_inline_container)>;

class ElementManager {
 public:
  class Delegate {
   public:
    Delegate() = default;
    virtual ~Delegate() = default;

    virtual void DispatchLayoutUpdates(const PipelineOptions &options) = 0;

    virtual void DispatchLayoutHasBaseline() = 0;

    virtual void SetEnableLayout() = 0;

    virtual void UpdateLayoutNodeFontSize(LayoutContext::SPLayoutNode node,
                                          double cur_node_font_size,
                                          double root_node_font_size,
                                          double font_scale) = 0;
    virtual void InsertLayoutNode(LayoutContext::SPLayoutNode parent,
                                  LayoutContext::SPLayoutNode child,
                                  int index) = 0;
    virtual void SendAnimationEvent(const char *type, int tag,
                                    const lepus::Value &dict) = 0;
    virtual void RemoveLayoutNode(LayoutContext::SPLayoutNode parent,
                                  LayoutContext::SPLayoutNode child, int index,
                                  bool destroy) = 0;
    virtual void MoveLayoutNode(LayoutContext::SPLayoutNode parent,
                                LayoutContext::SPLayoutNode child,
                                int from_index, int to_index) = 0;
    virtual void InsertLayoutNodeBefore(
        LayoutContext::SPLayoutNode parent, LayoutContext::SPLayoutNode child,
        LayoutContext::SPLayoutNode ref_node) = 0;
    virtual void RemoveLayoutNode(LayoutContext::SPLayoutNode parent,
                                  LayoutContext::SPLayoutNode child) = 0;
    virtual void DestroyLayoutNode(LayoutContext::SPLayoutNode node) = 0;
    virtual void UpdateLayoutNodeStyle(LayoutContext::SPLayoutNode node,
                                       CSSPropertyID css_id,
                                       const tasm::CSSValue &value) = 0;
    virtual void ResetLayoutNodeStyle(LayoutContext::SPLayoutNode node,
                                      CSSPropertyID css_id) = 0;
    virtual void UpdateLayoutNodeAttribute(LayoutContext::SPLayoutNode node,
                                           starlight::LayoutAttribute key,
                                           const lepus::Value &value) = 0;
    virtual void SetFontFaces(const CSSFontFaceTokenMap &fontfaces) = 0;
    virtual void MarkNodeAnimated(LayoutContext::SPLayoutNode node,
                                  bool animated) = 0;
    virtual void UpdateLayoutNodeProps(
        LayoutContext::SPLayoutNode node,
        const std::shared_ptr<PropBundle> &props) = 0;
    virtual void MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node) = 0;
    virtual void UpdateLynxEnvForLayoutThread(LynxEnvConfig env) = 0;
    virtual void OnUpdateViewport(float width, int width_mode, float height,
                                  int height_mode, bool need_layout) = 0;
    virtual void SetRootOnLayout(const std::shared_ptr<LayoutNode> &root) = 0;
    virtual void OnUpdateDataWithoutChange() = 0;
    virtual void SetHierarchyObserverOnLayout(
        const std::weak_ptr<HierarchyObserver> &hierarchy_observer) = 0;
    virtual void RegisterPlatformAttachedLayoutNode(
        LayoutContext::SPLayoutNode node) = 0;
  };

  ElementManager(
      std::unique_ptr<PaintingContext::PlatformImpl> platform_painting_context,
      Delegate *delegate, const LynxEnvConfig &lynx_env_config,
      const std::shared_ptr<shell::VSyncMonitor> &vsync_monitor = nullptr,
      const bool enable_diff_without_layout = false);

  // avoid pImpl idiom type of compilation error when self inlclude
  // std::unique_ptr object
  virtual ~ElementManager();

  virtual RadonElement *CreateNode(const lepus::String &tag,
                                   AttributeHolder *node);

  void OnDeleteStyle(RadonElement *node,
                     std::vector<CSSPropertyID> &style_names);

  void OnUpdateStyle(RadonElement *node, StyleMap &styles);

  void OnDeletedAttr(RadonElement *node, const lepus::String &attr_name);

  void OnUpdateAttr(RadonElement *node, const lepus::String &attr_name,
                    const lepus::Value &new_value);

  void OnUpdateDataSet(RadonElement *node, const DataMap &data);

  void GetStyleList(AttributeHolder *node, StyleMap &new_styles,
                    bool process_variable = true);

  void GetCachedStyleList(AttributeHolder *node, StyleMap &new_styles,
                          bool process_variable = true);
  void GetUpdatedStyleList(AttributeHolder *node, StyleMap &new_styles,
                           bool process_variable = true);

  BASE_EXPORT_FOR_DEVTOOL void OnFinishUpdateProps(Element *node);

  void OnValidateNode(Element *node);

  BASE_EXPORT_FOR_DEVTOOL void OnPatchFinish(const PipelineOptions &option);
  void OnPatchFinishFromRadon(bool outer_has_patches,
                              const PipelineOptions &option);
  void PatchEventRelatedInfo();
  void OnPatchFinishInner(const PipelineOptions &option);
  void OnPatchFinishInner(const PipelineOptions &option,
                          const bool is_need_notify_finish_patch_operation);

  void OnNodeFailedToRender(int tag);

  void SetTraceId(int trace_id);

  bool GetDevtoolFlag() { return devtool_flag_; }

  void SetDevtoolFlag(bool devtool_flag) { devtool_flag_ = devtool_flag; }
  // for air only, these functions won't be used when ENABLE_AIR is off, so link
  // process works normally even if ENABLE_AIR is off.
  base::scoped_refptr<AirLepusRef> GetAirNode(const lepus::String &tag,
                                              int32_t lepus_id);
  base::scoped_refptr<AirLepusRef> CreateAirNode(const lepus::String &tag,
                                                 int32_t lepus_id,
                                                 int32_t impl_id, uint64_t key);
  AirPageElement *CreateAirPage(int32_t lepus_id);
  inline void SetAirRoot(AirPageElement *node) { air_root_ = node; }
  AirPageElement *AirRoot() { return air_root_; }
  void OnPatchFinishInnerForAir(const PipelineOptions &option);
  // for air end

  PaintingContext *painting_context();
  inline Catalyzer *catalyzer() { return catalyzer_.get(); }
  inline NodeManager *node_manager() { return node_manager_.get(); }
  inline AirNodeManager *air_node_manager() { return air_node_manager_.get(); }
  inline void SetRoot(Element *node) { root_ = node; }
  Element *root() { return root_; }

  void RecordComponent(const std::string &id, Element *node);
  void EraseComponentRecord(const std::string &id, Element *node);
  Element *GetComponent(const std::string &id);
  virtual void ResolveAttributesAndStyle(AttributeHolder *node,
                                         RadonElement *shadow_node);

  void ResolveAttributesAndStyle(AttributeHolder *node,
                                 RadonElement *shadow_node, StyleMap &styles);

  void ResolveEvents(AttributeHolder *node, Element *element);

  void GenerateContentData(const lepus::Value &value,
                           const AttributeHolder *vnode,
                           RadonElement *shadow_node);
  void UpdatePseudoShadows(AttributeHolder *node, RadonElement *shadow_node);
  void UpdatePseudoShadowsNew(AttributeHolder *node, RadonElement *shadow_node);

  // return token-list about target selector, ordered by selector priority
  std::vector<CSSParseToken *> ParsePseudoCSSTokens(AttributeHolder *node,
                                                    const char *selector);
  void UpdateScreenMetrics(float width, float height);
  void UpdateFontScale(float font_scale);
  void UpdateViewport(float width, SLMeasureMode width_mode_, float height,
                      SLMeasureMode height_mode, bool need_layout);

  void SetHierarchyObserver(
      const std::shared_ptr<HierarchyObserver> &hierarchy_observer);
  void OnUpdateViewport(float width, int width_mode, float height,
                        int height_mode, bool need_layout);
  void SetHierarchyObserverOnLayout(
      const std::weak_ptr<HierarchyObserver> &hierarchy_observer);
  BASE_EXPORT_FOR_DEVTOOL void SetRootOnLayout(
      const std::shared_ptr<LayoutNode> &root);
#if ENABLE_ARK_RECORDER
  void SetRecordId(int64_t record_id) { record_id_ = record_id; }
#endif

  // delegate for class element
  void UpdateLayoutNodeFontSize(tasm::LayoutContext::SPLayoutNode node,
                                double cur_node_font_size,
                                double root_node_font_size);
  void InsertLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child, int index);
  void RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child, int index,
                        bool destroy);
  void InsertLayoutNodeBefore(tasm::LayoutContext::SPLayoutNode parent,
                              tasm::LayoutContext::SPLayoutNode child,
                              tasm::LayoutContext::SPLayoutNode ref_node);
  void RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child);
  void DestroyLayoutNode(tasm::LayoutContext::SPLayoutNode node);
  void SendAnimationEvent(const char *type, int tag, const lepus::Value &dict);
  void MoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                      tasm::LayoutContext::SPLayoutNode child, int from_index,
                      int to_index);
  void UpdateLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                             tasm::CSSPropertyID css_id,
                             const tasm::CSSValue &value);
  void ResetLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                            tasm::CSSPropertyID css_id);
  void UpdateLayoutNodeAttribute(tasm::LayoutContext::SPLayoutNode node,
                                 starlight::LayoutAttribute key,
                                 const lepus::Value &value);
  void SetFontFaces(const tasm::CSSFontFaceTokenMap &fontfaces);
  void MarkNodeAnimated(tasm::LayoutContext::SPLayoutNode node, bool animated);
  void UpdateLayoutNodeProps(tasm::LayoutContext::SPLayoutNode node,
                             const std::shared_ptr<tasm::PropBundle> &props);
  void AttachLayoutNode(tasm::LayoutContext::SPLayoutNode node,
                        tasm::PropBundle *props);
  bool IsShadowNodeVirtual(const lepus::String &tag_name);
  void MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node);
  void UpdateTouchPseudoStatus(bool value);

#if ENABLE_INSPECTOR

  /**
   * When page is created, call this API to notify devtool that page is updated
   * and node ids are no longer valid.
   */
  void OnDocumentUpdated();

  void OnElementNodeAddedForInspector(Element *element);
  void OnElementNodeRemovedForInspector(Element *element);
  void OnElementNodeSettedForInspector(Element *element,
                                       AttributeHolder *attribute_holder);
  void OnCSSStyleSheetAddedForInspector(Element *element);
  void OnComponentUselessUpdate(const std::string &component_name,
                                const lepus::Value &properties);
  void OnSetNativeProps(tasm::Element *ptr, const std::string &name,
                        const std::string &value, bool is_style);

  void RunDevtoolFunction(lynxdev::devtool::DevtoolFunction func_enum,
                          const base::any &data);
#endif  // ENABLE_INSPECTOR

  virtual int GetTraceId() { return trace_id_; }

  const tasm::DynamicCSSConfigs &GetDynamicCSSConfigs() {
    if (config_) {
      return config_->GetDynamicCSSConfigs();
    }
    static base::NoDestructor<tasm::DynamicCSSConfigs> kDefaultCSSConfigs;
    return *kDefaultCSSConfigs;
  }

  const tasm::CSSParserConfigs &GetCSSParserConfigs() {
    if (config_) {
      return config_->GetCSSParserConfigs();
    }
    static base::NoDestructor<tasm::CSSParserConfigs> kDefaultCSSConfigs;
    return *kDefaultCSSConfigs;
  }

  bool GetEnableLayoutOnly() {
    if (config_) {
      return config_->GetEnableNewLayoutOnly() && enable_layout_only_;
    }
    return enable_layout_only_;
  }

  inline bool GetLayoutHasBaseline() const { return layout_has_baseline_; }

  bool GetEnableComponentLayoutOnly() {
    if (config_) {
      return config_->GetEnableComponentLayoutOnly();
    }
    return false;
  }

  void SetEnableLayoutOnly(bool enable) { enable_layout_only_ = enable; }

  inline void SetLayoutHasBaseline(bool flag) { layout_has_baseline_ = flag; }

  void SetConfig(const std::shared_ptr<PageConfig> &config);

  bool GetPageFlatten() {
    if (config_) {
      return config_->GetGlobalFlattern();
    }
    return true;
  }

  starlight::LayoutConfigs GetLayoutConfigs() {
    if (config_) {
      return config_->GetLayoutConfigs();
    }
    return starlight::LayoutConfigs();
  }

  bool GetRemoveComponentElement() {
    if (config_) {
      return config_->GetRemoveComponentElement();
    }
    return false;
  }

  bool GetEnableSavePageData() {
    if (config_) {
      return config_->GetEnableSavePageData();
    }
    return false;
  }

  bool GetEnableCheckDataWhenUpdatePage() {
    if (config_) {
      return config_->GetEnableCheckDataWhenUpdatePage();
    }
    return true;
  }

  bool GetListNewArchitecture() {
    if (config_) {
      return config_->GetListNewArchitecture();
    }
    return false;
  }

  bool GetEnableFiberArch() {
    if (config_) {
      return config_->GetEnableFiberArch();
    }
    return false;
  }

  bool GetListRemoveComponent() {
    if (config_) {
      return config_->GetListRemoveComponent();
    }
    return false;
  }

  bool GetListEnableMoveOperation() {
    if (config_) {
      return config_->GetEnableListMoveOperation();
    }
    return false;
  }

  bool GetListEnablePlug() {
    if (config_) {
      return config_->list_enable_plug();
    }
    return false;
  }

  bool GetDefaultOverflowVisible() {
#if ENABLE_RENDERKIT
    return true;
#else
    return config_ ? config_->GetDefaultOverflowVisible() : false;
#endif
  }

  bool GetDefaultTextOverflow() {
    return config_ ? config_->GetEnableTextOverflow() : false;
  }

  bool GetDefaultDisplayLinear() {
    return config_ ? config_->GetDefaultDisplayLinear() : false;
  }

  bool GetDefaultCssAlignWithLegacyW3C() {
    return config_ ? config_->GetCSSAlignWithLegacyW3C() : false;
  }

  bool GetEnableComponentLifecycleAlignWebview() {
    return config_ ? config_->GetEnableComponentLifecycleAlignWebview() : false;
  }

  bool GetStrictPropType() {
    return config_ ? config_->GetStrictPropType() : false;
  }

  bool GetKeyboardCallbackUseRelativeHeight() {
    return config_ ? config_->GetKeyboardCallbackUseRelativeHeight() : false;
  }

  bool GetForceCalcNewStyle() {
    return config_ ? config_->GetForceCalcNewStyle() : true;
  }

  bool GetCompileRender() {
    return config_ ? config_->GetCompileRender() : false;
  }

  void InsertPlug(Element *plug) {
    current_insert_plug_vector_.push_back(plug);
  }

  std::vector<Element *> &GetCurrentInsertPlugVector() {
    return current_insert_plug_vector_;
  }

  bool IsDomTreeEnabled() { return dom_tree_enabled_; }
  bool GetEnableZIndex() { return config_ && config_->GetEnableZIndex(); }

  void InsertDirtyContext(ElementContainer *stacking_context) {
    dirty_stacking_contexts_.insert(stacking_context);
  }

  void RemoveDirtyContext(ElementContainer *stacking_context) {
    auto it = dirty_stacking_contexts_.find(stacking_context);
    if (it != dirty_stacking_contexts_.end())
      dirty_stacking_contexts_.erase(it);
  }

  std::string GetTargetSdkVersion() {
    return config_ ? config_->GetTargetSDKVersion() : "";
  }

  bool GetEnableReactOnlyPropsId() {
    return config_ ? config_->GetEnableReactOnlyPropsId() : false;
  }

  bool GetEnableGlobalComponentMap() {
    return config_ ? config_->GetEnableGlobalComponentMap() : false;
  }

  bool GetEnableRemoveComponentExtraData() {
    return config_ ? config_->GetEnableRemoveComponentExtraData() : false;
  }

  bool GetIsTargetSdkVerionHigherThan21() const {
    return config_ ? config_->GetIsTargetSdkVerionHigherThan21() : false;
  }

  bool GetEnableReduceInitDataCopy() {
    return config_ ? config_->GetEnableReduceInitDataCopy() : false;
  }

  bool GetEnableCascadePseudo() {
    return config_ ? config_->GetEnableCascadePseudo() : false;
  }

  bool GetEnableComponentNullProp() {
    return config_ ? config_->GetEnableComponentNullProp() : false;
  }

  LynxEnvConfig &GetLynxEnvConfig() { return lynx_env_config_; }

  const LynxEnvConfig &GetLynxEnvConfig() const { return lynx_env_config_; }

  bool GetEnableAttributeTimingFlag() const {
    return config_ ? config_->GetEnableAttributeTimingFlag() : false;
  }

  bool GetRemoveDescendantSelectorScope() const {
    return config_ ? config_->GetRemoveDescendantSelectorScope() : false;
  }

  std::shared_ptr<shell::VSyncMonitor> &vsync_monitor() {
    return vsync_monitor_;
  }

  void SetShadowNodeCreator(ShadowNodeCreator creator) {
    shadow_node_creator_ = std::move(creator);
  }
  bool Hydrate(AttributeHolder *node, RadonElement *shadow_node);

  void SetHasPatches() {
    // TODO(linxiaosong): Clean up the element manager & layout context life
    // cycle
    has_patches_ = true;
  }

  void SetGlobalBindElementId(const lepus::String &name,
                              const lepus::String &type, const int node_id);

  std::set<int> GetGlobalBindElementIds(const std::string &name) const;

  void EraseGlobalBindElementId(const EventMap &global_event_map,
                                const int node_id);

  // Element notify element_manager to regist itself to set.
  // TODO(WANGYIFEI): The function name is not appropriate, please change all
  // instances of "RequestNextFrameTime" to "RequestNextFrame".
  void RequestNextFrameTime(Element *element);
  // Element notify element_manager to logout itself from set.
  void NotifyElementDestroy(Element *element);
  // Tick all element need to animated.
  void TickAllElement(fml::TimePoint &time);

  bool IsFirstPatch() { return is_first_patch_; }
  // for Fiber Element related
  /**
   * create common Element via tag name
   * @param tag the tag name of Dom Element
   * @return  the refCounted type
   */
  base::scoped_refptr<FiberElement> CreateFiberNode(const lepus::String &tag);
  /**
   * create Page Element for fiber
   * @param component_id the component id for Page
   * @param css_id the css_id for getting StyleSheet for Page
   * @return the refCounted type
   */
  base::scoped_refptr<PageElement> CreateFiberPage(
      const lepus::String &component_id, int32_t css_id);

  /**
   * create Component Element for fiber
   * @param component_id the component id for specific Component
   * @param css_id  the css_id for getting StyleSheet for current component
   * @param entry_name the entry_name for current component
   * @param name the component name
   * @param path the component path
   * @return the refCounted type
   */
  base::scoped_refptr<ComponentElement> CreateFiberComponent(
      const lepus::String &component_id, int32_t css_id,
      const lepus::String &entry_name, const lepus::String &name,
      const lepus::String &path);

  /**
   * create View Element
   * @return the refCounted type
   */
  base::scoped_refptr<ViewElement> CreateFiberView();

  /**
   * create Text Element
   * @param tag the tag name of Image Element, such as "image", "x-image"
   * @return the refCounted type
   */
  base::scoped_refptr<ImageElement> CreateFiberImage(const lepus::String &tag);

  /**
   * create Text Element
   * @param tag the tag name of Image Element, such as "text", "x-text"
   * @return the refCounted type
   */
  base::scoped_refptr<TextElement> CreateFiberText(const lepus::String &tag);

  /**
   * create Raw Text Element
   * @return the refCounted type
   */
  base::scoped_refptr<RawTextElement> CreateFiberRawText();

  /**
   * create Scroll Element
   * @param tag the tag name of Image Element, such as "scroll-view",
   * "x-scroll-view"
   * @return the refCounted type
   */
  base::scoped_refptr<ScrollElement> CreateFiberScrollView(
      const lepus::String &tag);

  /**
   * create List element for fiber
   * @param tasm the template_assembler instance
   * @param component_at_index (Ref list, Number listID, Number cellIndex,
   * Number opID)=>{}
   * @param enqueue_component  (Ref list, Number listID, Number
   * elementUniqueID)=>{}
   * @return the refCounted type
   */
  base::scoped_refptr<ListElement> CreateFiberList(
      tasm::TemplateAssembler *tasm, const lepus::String &tag,
      const lepus::Value &component_at_index,
      const lepus::Value &enqueue_component);

  /**
   * create None Element, it's just meaningless Node
   * @return the refCounted type
   */
  base::scoped_refptr<NoneElement> CreateFiberNoneElement();

  /**
   * create Wrapper Element, it's just meaningless Node
   * @return the refCounted type
   */
  base::scoped_refptr<WrapperElement> CreateFiberWrapperElement();

  /**
   * a special onPatchFinish function for fiber
   * @param option options for onPatchFinish
   */
  void OnPatchFinishForFiber(const PipelineOptions &option,
                             FiberElement *root = nullptr);
  /**
   * Resolve styles for Fiber Element
   * @param holder the attributes holder
   * @param style_sheet the related style sheet for current component
   * @param styles  return the resolved styles
   */
  void ResolveStyleForFiber(FiberElement *holder, CSSFragment *style_sheet,
                            StyleMap &styles);

  /**
   * Generate ID for element
   */
  int32_t GenerateElementID();

  starlight::ComputedCSSStyle *platform_computed_css() {
    return platform_computed_css_.get();
  }
  starlight::ComputedCSSStyle *layout_computed_css() {
    return layout_computed_css_.get();
  }

  /**
   * Prepare node for inspector
   * @param element the element which will be processed
   */
  void PrepareNodeForInspector(Element *element);

  /**
   * Prepare slot and plug node for inspector
   * @param element the element which will be processed
   */
  void CheckAndProcessSlotForInspector(Element *element);

 protected:
  /**
   * call this function to request layout
   * @param options the pipeline options passed to layout context
   */
  void RequestLayout(const PipelineOptions &options);

  /**
   * call this function after exec OnPatchFinishForFiber
   */
  void DidPatchFinishForFiber();

  void PrepareComponentNodeForInspector(Element *component);
  virtual RadonElement *CreatePseudoNode(int style_type);

  PseudoPlaceHolderStyles ParsePlaceHolderTokens(
      std::vector<CSSParseToken *> tokens);
  void ParsePlaceHolderTokens(PseudoPlaceHolderStyles &result,
                              const StyleMap &map);

  bool has_patches_;
  std::unique_ptr<NodeManager> node_manager_;
  std::unique_ptr<AirNodeManager> air_node_manager_;
  std::unique_ptr<ComponentManager> component_manager_;
  std::unique_ptr<CSSPatching> css_patch_;
  std::unique_ptr<Catalyzer> catalyzer_;
  Element *root_;
  AirPageElement *air_root_{nullptr};
  bool is_first_patch_;
  std::weak_ptr<HierarchyObserver> hierarchy_observer_;

  void UpdateBeforeAfterPseudo(std::vector<CSSParseToken *> const &token_list,
                               AttributeHolder *node, RadonElement *self,
                               bool before);

  void UpdateSelectionPseudo(std::vector<CSSParseToken *> const &token_list,
                             RadonElement *self);

 private:
  void UpdateContentNode(const StyleMap &attrs, RadonElement *element);
  void WillDestroy();
  ElementManager(const ElementManager &) = delete;
  ElementManager &operator=(const ElementManager &) = delete;
  CSSFragment *preresolving_style_sheet_ = nullptr;
  bool devtool_flag_ = false;
  bool dom_tree_enabled_ = true;
  int trace_id_ = 0;
  std::shared_ptr<PageConfig> config_;
  CSSVariableHandler css_var_handler_;
  std::vector<Element *> current_insert_plug_vector_;
  bool enable_layout_only_{true};
  bool layout_has_baseline_{false};
  std::unordered_set<ElementContainer *> dirty_stacking_contexts_;
  LynxEnvConfig lynx_env_config_;
  Delegate *delegate_{nullptr};
  std::shared_ptr<shell::VSyncMonitor> vsync_monitor_{nullptr};
  std::unordered_map<lepus::String, int> node_type_recorder_;
  std::unordered_map<std::string, bool> node_virtuality_recorder_;
  ShadowNodeCreator shadow_node_creator_;
  std::unordered_map<std::string, std::set<int32_t>> global_bind_name_to_ids_;

  // Animation proxy class
  std::shared_ptr<animation::AnimationVSyncProxy> animation_vsync_proxy_;

  // If it has been set to 'true', OnPatchFinish will not trigger layout
  // anymore, platform must trigger layout manually.
  bool enable_diff_without_layout_ = false;
  // If this flag is true, it indicates that when exec the next patchfinish
  // operation, additional information related to pseudo-class will be pushed to
  // the platform.
  bool push_touch_pseudo_flag_{false};

  ALLOW_UNUSED_TYPE int64_t record_id_ = 0;

  base::scoped_refptr<PageElement> fiber_page_{};

  int32_t element_id_{kInitialImplId};
  std::unique_ptr<starlight::ComputedCSSStyle> platform_computed_css_;
  std::unique_ptr<starlight::ComputedCSSStyle> layout_computed_css_;
  std::set<tasm::Element *> animation_element_set_;

 public:
  ALLOW_UNUSED_TYPE std::map<lynxdev::devtool::DevtoolFunction,
                             std::function<void(const base::any &)>>
      devtool_func_map_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_ELEMENT_MANAGER_H_
