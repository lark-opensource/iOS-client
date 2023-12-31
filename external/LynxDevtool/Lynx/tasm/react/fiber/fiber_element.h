// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_FIBER_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_FIBER_ELEMENT_H_

#include <deque>
#include <memory>
#include <string>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/ref_counted.h"
#include "css/css_fragment_decorator.h"
#include "css/css_style_sheet_manager.h"
#include "tasm/attribute_holder.h"
#include "tasm/base/element_template_info.h"
#include "tasm/react/element.h"
#include "tasm/selector/selector_item.h"

namespace lynx {
namespace tasm {
class NodeManager;

class FiberElement : public Element,
                     public base::RefCountedThreadSafeStorage,
                     public SelectorItem {
 public:
  // Construct element tree according to the element-template info.
  static lepus::Value FromTemplateInfo(int64_t parent_component_id,
                                       ElementManager* manager,
                                       const ElementTemplateInfo& info);

  FiberElement(ElementManager* manager, const lepus::String& tag);
  FiberElement(ElementManager* manager, const lepus::String& tag,
               int32_t css_id);

  virtual ~FiberElement();

  void ReleaseSelf() const override { delete this; }

  enum class Action {
    kCreateAct = 0,
    kDestroyAct,
    kInsertChildAct,
    kRemoveChildAct,
    kMoveAct,
    kUpdatePropsAct,
    kRemoveIntergenerationAct,
  };

  struct ActionParam {
    ActionParam(Action type, FiberElement* parent,
                const base::scoped_refptr<FiberElement>& child, int from,
                FiberElement* ref_node)
        : type_(type),
          parent_(parent),
          child_(child),
          index_(from),
          ref_node_(ref_node) {}
    Action type_;
    FiberElement* parent_;  // do not add parent's refcount
    base::scoped_refptr<FiberElement> child_;
    int index_;
    FiberElement* ref_node_;
  };

  struct ActionOption {
    // true if need trigger layout
    bool need_layout_{false};
    bool children_propagate_inherited_styles_flag_{false};

    StyleMap* inherited_styles_{nullptr};
    std::vector<tasm::CSSPropertyID>* reset_inherited_ids_{nullptr};
  };

  class ScopedOption {
   public:
    ScopedOption(ActionOption& option) : option_(option) {
      pre_option_ = option;
    }
    ~ScopedOption() {
      pre_option_.need_layout_ = option_.need_layout_;
      option_ = pre_option_;
    }
    ActionOption& GetOption() { return option_; }

   private:
    ActionOption& option_;
    ActionOption pre_option_{};
  };

  static const uint32_t kDirtyCreated = 0x01 << 0;
  static const uint32_t kDirtyTree = 0x01 << 1;
  static const uint32_t kDirtyStyle = 0x01 << 2;
  static const uint32_t kDirtyAttr = 0x01 << 3;
  static const uint32_t kDirtyForceUpdate = 0x01 << 4;
  static const uint32_t kDirtyEvent = 0x01 << 5;
  static const uint32_t kDirtyReAttachContainer = 0x01 << 6;
  static const uint32_t kDirtyPropagateInherited = 0x01 << 7;

  // for Fiber specific
  virtual bool is_view() const { return false; }
  virtual bool is_component() const { return false; }
  virtual bool is_page() const { return false; }
  virtual bool is_list() const { return false; }
  virtual bool is_scroll_view() const { return false; }
  virtual bool is_text() const { return false; }
  virtual bool is_raw_text() const { return false; }
  virtual bool is_image() const { return false; }

  virtual bool is_wrapper() const { return false; }
  virtual bool is_none() const { return false; }

  bool is_fiber_element() const override { return true; }

  /**
   * A key function to GetListNode
   */
  virtual ListNode* GetListNode() override;

  /**
   * A key function to get parent component's element
   */
  virtual Element* GetParentComponentElement() const override;

  /**
   * A key function to flush the tree with the current element as the root node.
   * Return true if need trigger layout.
   */
  virtual bool FlushActionsAsRoot();

  virtual void UpdateCurrentFlushOption(ActionOption& options);

  AttributeHolder* data_model() const override { return data_model_.get(); }

  void OnAnimatedNodeReady() override {
    // do thing for fiber, use onNodeReady instead!!
  }

  bool CanBeLayoutOnly() const override {
    return can_be_layout_only_ && config_enable_layout_only_ &&
           has_layout_only_props_ && overflow_ == OVERFLOW_XY;
  }

  void MarkCanBeLayoutOnly(bool flag) { can_be_layout_only_ = flag; }

  /**
   * A key function for flush all pending actions for current Element
   */
  void FlushActions(ActionOption& options);

  /**
   * A key function for generating children's actions.
   */
  void GenerateChildrenActions(ActionOption& options);

  virtual void HandleInsertChildAction(FiberElement* child, int index,
                                       FiberElement* ref_node);
  virtual void HandleRemoveChildAction(FiberElement* child);

  void SetParentComponentUniqueIdForFiber(int64_t id) {
    parent_component_unique_id_ = id;
  }

  /**
   * Element API for inserting child
   * @param child refCounted child
   */
  void InsertNode(const base::scoped_refptr<FiberElement>& child);

  /**
   * Element API for replacing elements
   * @param inserted inserted elements
   * @param removed removed elements
   */
  void ReplaceElements(
      const std::deque<base::scoped_refptr<FiberElement>>& inserted,
      const std::deque<base::scoped_refptr<FiberElement>>& removed);

  /**
   * Element API for setting class name to Element
   * @param clazz the name of class selector
   */
  void SetClass(const lepus::String& clazz);

  /**
   * Element API for removing all classes of
   */
  void RemoveAllClass();

  /**
   * Element API for InsertingNodeBefore reference child
   * @param child the child Element need to be inserted
   * @param reference_child the reference child
   */
  void InsertNodeBefore(
      const base::scoped_refptr<FiberElement>& child,
      const base::scoped_refptr<FiberElement>& reference_child);

  /**
   * Element API for removing the specific child Element
   * @param child the Element to be removed
   */
  void RemoveNode(const base::scoped_refptr<FiberElement>& child);

  /**
   * Deprecated: Inset child Element to the specific index
   * @param child the Element to be inserted
   * @param index the index where the child Element to be inserted
   */
  void InsertNode(const base::scoped_refptr<FiberElement>& child, int index);

  /**
   * Element API for appending css style to element
   * @param id the css property id
   * @param value the css property lepus type vale
   */
  void SetStyle(CSSPropertyID id, const lepus::Value& value);

  /**
   * Element API for updating css variables
   * @param variables the css variables to be updated from JS.
   */
  void UpdateCSSVariable(const lepus::Value& variables);

  /**
   * Element API for removing all inline styles.
   */
  void RemoveAllInlineStyles();

  /**
   * Destroy the related platform node of this element
   */
  void DestroyPlatformNode() override;

  /**
   * Element API for appending single attribute to element
   * @param key the attribute String type name
   * @param value the attribute value
   */
  void SetAttribute(const lepus::String& key, const lepus::Value& value);

  /**
   * Element API for setting id for element
   * @param idSelector the id of the element
   */
  void SetIdSelector(const lepus::String& idSelector);

  /**
   * Element API for adding js event
   * @param name the binding event's name
   * @param type the binding event's type
   * @param callback the binding event's corresponding js function name
   */
  void SetJSEventHandler(const lepus::String& name, const lepus::String& type,
                         const lepus::String& callback);

  /**
   * Element API for setNativeProps
   *  @param native_props the props that updated from js.
   */
  virtual void SetNativeProps(const lepus::Value& native_props) override;

  /**
   * Element API for adding lepus event
   * @param name the binding event's name
   * @param type the binding event's type
   * @param script the binding event's corresponding lepus script
   * @param callback the binding event's corresponding lepus function
   */
  void SetLepusEventHandler(const lepus::String& name,
                            const lepus::String& type,
                            const lepus::Value& script,
                            const lepus::Value& callback);
  /**
   * Element API for removing specific event
   * @param name the removed event's name
   * @param type the removed event's type
   */
  void RemoveEvent(const lepus::String& name, const lepus::String& type);

  /**
   * Element API for removing all events
   */
  void RemoveAllEvents();

  /**
   * Element API for setting compile stage parsed style
   * @param map the parsed style map
   * @param config parsed style config
   */
  void SetParsedStyle(const StyleMap& map, const lepus::Value& config);

  /**
   * Element API for adding config.
   * @param key the config key,
   * @param value the config value.
   */
  void AddConfig(const lepus::String& key, const lepus::Value& value);

  /**
   * Element API for setting config.
   * @param config the config will be setted,
   */
  void SetConfig(const lepus::Value& config);

  /**
   * A key function to get element's config
   */
  const lepus::Value& config() { return config_; }
  const lepus::Value& config() const { return config_; }

  void MarkDirty(const uint32_t flag) {
    dirty_ |= flag;
    RequireFlush();
  }

  bool StyleDirty() { return dirty_ & kDirtyStyle; }

  void MarkPropsDirty() { MarkDirty(kDirtyForceUpdate); }

  void MarkStyleDirty(bool recursive = false);

  // if child's related css variable is updated, invalidate child's style.
  void RecursivelyMarkChildrenCSSVariableDirty(
      const lepus::Value& css_variable_updated);

  void MarkNeedPropagateInheritedProperties() {
    MarkDirty(kDirtyPropagateInherited);
  }

  void SetStyle(const StyleMap& styles) override;
  void AddDataset(const lepus::String& key, const lepus::Value& value);
  void SetDataset(const lepus::Value& data_set);

  // Flush style and attribute to platform shadow node, platform painting node
  // will be created if has not been created,
  void FlushProps() override;

  const EventMap& event_map() override {
    if (data_model_) {
      return data_model_->static_events();
    }
    static base::NoDestructor<EventMap> kEmptyEventMap;
    return *kEmptyEventMap.get();
  }
  const EventMap& lepus_event_map() override {
    if (data_model_) {
      return data_model_->lepus_events();
    }
    static base::NoDestructor<EventMap> kEmptyLepusEventMap;
    return *kEmptyLepusEventMap.get();
  }

  bool InComponent() const override;

  std::string ParentComponentIdString() const override;

  const EventMap& global_bind_event_map() override {
    // TODO(songshourui.null): impl global bind event for fiber
    static base::NoDestructor<EventMap> kEmptyGlobalBindEventMap;
    return *kEmptyGlobalBindEventMap.get();
  }

  // TODO(linxs): to check if this APIs can be deleted
  void InsertNodeBeforeInternal(const base::scoped_refptr<FiberElement>& child,
                                FiberElement* ref_node);
  void AddChildAt(base::scoped_refptr<FiberElement> child, int index);
  int IndexOf(const FiberElement* child) const;
  Element* GetChildAt(size_t index) override;
  size_t GetChildCount() override { return scoped_children_.size(); }
  std::vector<Element*> GetChild() override;

  /**
   * Special API for processing Font size
   * font size should be handled at the beginning
   * @param value the font size value
   */
  void SetFontSize(const tasm::CSSValue* value);

#if ENABLE_RENDERKIT
  void SetMeasureFunc(std::unique_ptr<MeasureFunc> func);
#endif

  void UpdateFiberElement();

  bool IsRelatedCSSVariableUpdated(AttributeHolder* holder,
                                   const lepus::Value changing_css_variables);

  bool HasElementContainer() { return element_container_ != nullptr; }

  void set_path(const std::string path) { path_ = path; }

  std::string path() { return path_; }

  void set_style_sheet_manager(std::shared_ptr<CSSStyleSheetManager> manager) {
    css_style_sheet_manager_ = manager;
  }

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manage() {
    return css_style_sheet_manager_;
  }

  void set_css_id(int32_t id) { css_id_ = id; }

  bool IsInSameCSSScope(FiberElement* element) {
    return css_id_ == element->css_id_;
  }

  inline const std::unordered_map<tasm::CSSPropertyID, CSSValue>& styles()
      const {
    return styles_;
  }
  const lepus::Value& attributes() const { return attributes_; }

  const std::vector<base::scoped_refptr<FiberElement>>& children() {
    return scoped_children_;
  }

  Element* Sibling(int offset) const override;
  Element* render_parent() override { return render_parent_; }
  Element* first_render_child() override { return first_render_child_; }
  Element* next_render_sibling() override { return next_render_sibling_; }

  const ClassList& classes() { return data_model_->classes(); }

  const lepus::String GetIdSelector() { return data_model_->idSelector(); }

  const DataMap& dataset() { return data_model_->dataset(); }

  virtual void PrepareForCreateOrUpdate(ActionOption& option);
  void set_attached_to_layout_parent(bool has) {
    attached_to_layout_parent_ = has;
  }
  bool attached_to_layout_parent() const { return attached_to_layout_parent_; }

  void InsertLayoutNode(FiberElement* child, FiberElement* ref);
  void RemoveLayoutNode(FiberElement* child);

  void StoreLayoutNode(FiberElement* child, FiberElement* ref);
  void RestoreLayoutNode(FiberElement* child);

  // For snapshot test
  void DumpStyle(StyleMap& parsed_styles);

  void OnPseudoStatusChanged(PseudoState prev_status,
                             PseudoState current_status) override;

  bool RefreshStyle(StyleMap& parsed_styles,
                    std::vector<CSSPropertyID>& reset_ids);

  void OnClassChanged(const ClassList& old_classes,
                      const ClassList& new_classes);

  static constexpr const int INVALID_CSS_ID = -1;

  void OnPatchFinish(const PipelineOptions& option) override;

  virtual void ConsumeTransitionStylesInAdvanceInternal(
      CSSPropertyID css_id, const tasm::CSSValue& value) override;

  virtual void ResetTransitionStylesInAdvanceInternal(
      CSSPropertyID css_id) override;

  virtual std::optional<CSSValue> GetElementStyle(
      tasm::CSSPropertyID css_id) override;

  void UpdateDynamicElementStyle() override;

  void ResolveStyleValue(CSSPropertyID id, const tasm::CSSValue& value,
                         bool force_update) override;
  void CheckViewportUnit(CSSPropertyID id, CSSValue value) override;

 protected:
  /**
   * This function will be called before add node.
   * @param child the added node
   */
  virtual void OnNodeAdded(FiberElement* child){};

  // called when a child element is removed
  virtual void OnNodeRemoved(FiberElement* child){};

  static void NotifyNodeInserted(FiberElement* insertion_point,
                                 FiberElement* node);
  static void NotifyNodeRemoved(FiberElement* insertion_point,
                                FiberElement* node);

  // current element is inserted to DOM tree
  virtual void InsertedInto(FiberElement* insertion_point) {}
  // current element is removed from DOM tree
  virtual void RemovedFrom(FiberElement* insertion_point);

  // handle default overflow logic
  void SetDefaultOverflow(bool visible);

  bool IsInlineElement() const { return is_inline_element_; }

  void MarkAsInline() { is_inline_element_ = true; }
  virtual void SetAttributeInternal(const lepus::String& key,
                                    const lepus::Value& value);

  void RequireFlush();

  void RequireDynamicStyleUpdate();

  virtual CSSFragment* GetRelatedCSSFragment() override;

 private:
  friend class WrapperElement;

  // Construct element according to the element info.
  static base::scoped_refptr<FiberElement> FromElementInfo(
      int64_t parent_component_id, ElementManager* manager,
      const ElementInfo& info);

  void ResetAttribute(const lepus::String& key);

  void ResetStyleInternal(CSSPropertyID id);
  bool DisableFlattenWithOpacity();
  virtual bool TendToFlatten();

  inline void MarkPlatformNodeDestroyedRecursively();

  void ConsumeTransitionStyles(const StyleMap& styles) {}

  bool CheckHasIdMapInCSSFragment();

  FiberElement* FindEnclosingNoneWrapper(FiberElement* parent,
                                         FiberElement* node);

  static void PrepareChildForInsertion(FiberElement* child,
                                       ActionOption& option);

  void HandleContainerInsertion(FiberElement* parent, FiberElement* child,
                                FiberElement* ref);

  bool IsInheritable(CSSPropertyID id) const;

  bool IsCSSInheritanceEnabled() const;

  bool IsDirectionChangedEnabled() const;

  void TryDoDirectionRelatedCSSChange(CSSPropertyID id, CSSValue value,
                                      IsLogic is_logic_style);

  bool TryResolveLogicStyleAndSaveDirectionRelatedStyle(CSSPropertyID id,
                                                        CSSValue value);

  void WillResetCSSValue(CSSPropertyID& id);

  void ResetCSSValue(CSSPropertyID id);

  void HandleSelfFixedChange();
  void InsertFixedElement(FiberElement* child, FiberElement* ref_node);
  void RemoveFixedElement(FiberElement* child);

  bool CheckHasInvalidationForId(const std::string& old_id,
                                 const std::string& new_id);

  bool CheckHasInvalidationForClass(const ClassList& old_classes,
                                    const ClassList& new_classes);

  void VisitChildren(const base::MoveOnlyClosure<void, FiberElement*>& visitor);

  // relevant to hierarchy
  std::vector<base::scoped_refptr<FiberElement>> scoped_children_;

  // layout_parent/child to indicate current real tree hierarchy after
  // flushActions, it's different from dom tree.
  // dom tree is updated when the Element APIs called immediately
  FiberElement* render_parent_{nullptr};
  FiberElement* last_render_child_{nullptr};
  FiberElement* first_render_child_{nullptr};
  FiberElement* previous_render_sibling_{nullptr};
  FiberElement* next_render_sibling_{nullptr};

  std::unique_ptr<AttributeHolder> data_model_{nullptr};
  std::weak_ptr<UIImplObserver> observer_;

  css::InvalidationLists invalidation_lists_;

  std::unordered_map<tasm::CSSPropertyID, CSSValue> styles_{};
  lepus::Value attributes_{lepus::Dictionary::Create()};

  // css
  void PrepareComponentExternalStyles(AttributeHolder* holder);
  void PrepareRootCSSVariables(AttributeHolder* holder);

  std::string path_{};
  std::unordered_map<lepus::String, ClassList> external_classes_;
  std::shared_ptr<CSSStyleSheetManager> css_style_sheet_manager_{nullptr};
  CSSFragment* fragment_{nullptr};
  std::shared_ptr<CSSFragmentDecorator> style_sheet_{nullptr};

  uint8_t dirty_{0};

  // indicate this tree scope needs to do flushActon
  bool flush_required_{true};

  // indicate this tree scope needs to do dynamic style update
  bool dynamic_style_update_required_{false};

  StyleMap parsed_styles_map_;
  StyleMap pre_parsed_styles_map_;

  StyleMap updated_inline_parsed_styles_;
  StyleMap updated_inherited_styles_;  // current styles = parsed_styles_map_ +
                                       // updated_inherited_styles_
  RawStyleMap current_raw_inline_styles_;

  StyleMap viewport_unit_styles_;

  // indicate current not style related flags, such as viewport_unit_, em_units_
  // for performance, we will never reset it
  DynamicCSSStylesManager::StyleUpdateFlags dynamic_style_flags_{0};

  // Flag used to determine whether the element has extreme_parsed_styles_
  bool has_extreme_parsed_styles_{false};
  // If this flag is set to true, it indicates that only the selector was
  // extracted during compilation.
  bool only_selector_extreme_parsed_styles_{false};
  // the parsed styles that set from front-end resolved in compiler stage
  StyleMap extreme_parsed_styles_;

  StyleMap inherited_styles_;
  std::vector<tasm::CSSPropertyID> reset_inherited_ids_;

  bool is_first_created_{true};
  // indicates the node's layout node has been inserted to parent layout node
  // yet
  bool attached_to_layout_parent_{false};

  // indicated if use any css selector changed
  bool css_related_changed_{false};

  // can be optimized as layout only node, currently only view & component
  bool can_be_layout_only_{false};

  // indicate if its an inline element,such as inline-text, inline-image,etc.
  bool is_inline_element_{false};

  // indicate it's children has been marked to propagate inherited properties.
  bool children_propagate_inherited_styles_flag_{false};

  uint32_t wrapper_element_count_{false};
  FiberElement* enclosing_none_wrapper_{nullptr};

  bool direction_changed_{false};

  //{origin_css_id, {css_value, is_logic_style}}
  std::unordered_map<tasm::CSSPropertyID, std::pair<CSSValue, IsLogic>>
      pending_updated_direction_related_styles_;
  //{origin_css_id,{transited_css_id, css_value, is_logic_style}};
  std::unordered_map<tasm::CSSPropertyID,
                     std::tuple<tasm::CSSPropertyID, CSSValue, IsLogic>>
      current_direction_related_styles_;

  // TODO(linxs): tobe refined
  int64_t parent_component_unique_id_{-1};
  mutable FiberElement* parent_component_element_{nullptr};

  NodeManager* node_manager_;

  std::vector<Action> action_list_;
  std::vector<ActionParam> action_param_list_;

  AttrUMap updated_attr_map_;
  std::vector<lepus::String> reset_attr_vec_;
  int32_t css_id_{INVALID_CSS_ID};

  // Configuration set for elements through the LepusRuntime will be stored in
  // the config variable
  lepus::Value config_{lepus::Dictionary::Create()};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_FIBER_ELEMENT_H_
