// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_ELEMENT_H_
#define LYNX_TASM_REACT_ELEMENT_H_

#include <array>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "animation/css_keyframe_manager.h"
#include "animation/css_transition_manager.h"
#include "base/base_export.h"
#include "base/no_destructor.h"
#include "css/content_data.h"
#include "inspector/style_sheet.h"
#include "lepus/table.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/attribute_holder.h"
#include "tasm/react/catalyzer.h"
#include "tasm/react/dynamic_css_styles_manager.h"
#include "tasm/react/element_container.h"
#include "tasm/react/event.h"
#include "tasm/react/layout_node.h"
#include "tasm/react/painting_context.h"

namespace lynx {
namespace tasm {

class AttributeHolder;
class ElementManager;
class ListNode;

class InspectorAttribute {
 public:
  BASE_EXPORT_FOR_DEVTOOL InspectorAttribute();
  BASE_EXPORT_FOR_DEVTOOL ~InspectorAttribute() = default;

 public:
  int node_type_;
  std::string local_name_;
  std::string node_name_;
  std::string node_value_;
  std::string selector_id_;
  std::vector<std::string> class_order_;
  std::string shadow_root_type_;
  lynxdev::devtool::InspectorElementType type_;
  std::string slot_name_;
  std::vector<std::string> attr_order_;
  std::unordered_map<std::string, std::string> attr_map_;
  std::vector<std::string> data_order_;
  std::unordered_map<std::string, std::string> data_map_;
  std::vector<std::string> event_order_;
  std::unordered_map<std::string, std::string> event_map_;
  Element* style_root_;  // not owned
  lynxdev::devtool::InspectorStyleSheet inline_style_sheet_;
  std::vector<lynxdev::devtool::InspectorCSSRule> css_rules_;

  int start_line_;
  std::vector<std::string> style_sheet_order_;
  std::unordered_map<std::string, lynxdev::devtool::InspectorStyleSheet>
      style_sheet_map_;
  std::unordered_map<std::string,
                     std::vector<lynxdev::devtool::InspectorKeyframe>>
      animation_map_;

  int plug_id = 0;

  // for component remove view, erase component
  // id from node_manager in  element destructor
  bool needs_erase_id_ = false;

  // only for style value element
  // initialized true when style sheet has cascaded style
  bool has_cascaded_style_ = false;

  bool enable_css_selector_ = false;

  std::unique_ptr<Element> doc_;
  std::unique_ptr<Element> style_;
  std::unique_ptr<Element> style_value_;
  std::unique_ptr<Element> shadow_root_;
  // This is plug's corresponding slot element, only plug element has slot_.
  // Other elements' slot_ must be nullptr.
  std::unique_ptr<Element> slot_;
  Element* slot_component_;  // not owned
  // This is slot's corresponding plug element, only slot element has plug_.
  // Other elements' plug_ must be nullptr. And the slot does not hold plug
  // nodes and does not manage the life cycle of plugs.
  Element* plug_;
  std::vector<Element*> slot_plug_;
};

class Element {
 public:
  Element(const lepus::String& tag, ElementManager* element_manager);
  Element(const Element&) = delete;
  Element& operator=(const Element&) = delete;

  virtual AttributeHolder* data_model() const = 0;

  virtual bool is_radon_element() const { return false; }
  virtual bool is_fiber_element() const { return false; }

  void SetObserver(const std::shared_ptr<UIImplObserver>& observer);
  int impl_id() const { return id_; }

  std::vector<float> ScrollBy(float width, float height);
  std::vector<float> GetRectToLynxView();
  void Invoke(const std::string& method, const lepus::Value& params,
              const std::function<void(int32_t code, const lepus::Value& data)>&
                  callback);

  ElementManager* element_manager() { return element_manager_; }
  Element* parent() const { return parent_; }
  Element* next_sibling() const { return Sibling(1); }
  Element* previous_sibling() const { return Sibling(-1); }
  virtual Element* Sibling(int offset) const = 0;

  // only for fiber arch, indicate current real render tree hierarchy
  virtual Element* render_parent() { return nullptr; }
  virtual Element* first_render_child() { return nullptr; }
  virtual Element* next_render_sibling() { return nullptr; }

  virtual ~Element() = default;

  // For style op
  BASE_EXPORT_FOR_DEVTOOL virtual void SetStyle(const StyleMap& styles) = 0;
  virtual void SetStyleInternal(CSSPropertyID id, const tasm::CSSValue& value,
                                bool force_update = false);
  void SetPlaceHolderStyles(const PseudoPlaceHolderStyles& styles);
  BASE_EXPORT_FOR_DEVTOOL void ResetStyle(
      const std::vector<CSSPropertyID>& style_names);

  // For attr op
  BASE_EXPORT_FOR_DEVTOOL void SetAttribute(const lepus::String& key,
                                            const lepus::Value& value);
  void ResetAttribute(const lepus::String& key);

  // For dataset op
  void SetDataSet(const tasm::DataMap& data);

  // For event handler
  void SetEventHandler(const lepus::String& name, EventHandler* handler);
  void ResetEventHandlers();

  // For prop op
  void SetProp(const char* key, const lepus::Value& value);
  void ResetProp(const char* key);

  // For keyframe op
  // The first parameter names can be string type or array type of lepus value
  void SetKeyframesByNames(const lepus::Value& names,
                           const CSSKeyframesTokenMap&);

  // For font face
  void SetFontFaces(const CSSFontFaceTokenMap&);

  // For pseudo
  void ResetPseudoType(int pseudo_type) { pseudo_type_ = pseudo_type; }

  // For Animation API
  void Animate(const lepus::Value& args);

  // For JS API setNativeProps
  virtual void SetNativeProps(const lepus::Value& args) = 0;

  // Get List Node
  virtual ListNode* GetListNode() = 0;

  // Get Parent Component's Element
  BASE_EXPORT_FOR_DEVTOOL virtual Element* GetParentComponentElement()
      const = 0;

  inline std::shared_ptr<LayoutNode> layout_node() { return layout_node_; }
  Catalyzer* GetCaCatalyzer() { return catalyzer_; }

  virtual const EventMap& event_map();
  virtual const EventMap& lepus_event_map();
  virtual const EventMap& global_bind_event_map();

  virtual bool InComponent() const { return false; }
  virtual int ParentComponentId() const { return 0; }
  virtual std::string ParentComponentIdString() const = 0;

  virtual void OnRenderFailed() {}

  inline bool IsLayoutOnly() { return is_layout_only_; }
  inline bool is_virtual() { return is_virtual_; }
  virtual bool is_fixed_new() { return false; }
  BASE_EXPORT_FOR_DEVTOOL virtual bool GetPageElementEnabled() { return false; }

  void UpdateLayout(float left, float top, float width, float height,
                    const std::array<float, 4>& paddings,
                    const std::array<float, 4>& margins,
                    const std::array<float, 4>& borders,
                    const std::array<float, 4>* sticky_positions,
                    float max_height);

  virtual void OnAnimatedNodeReady();

  virtual Element* GetChildAt(size_t index) { return nullptr; }
  virtual size_t GetChildCount() { return 0; }
  virtual std::vector<Element*> GetChild() { return {}; }
  virtual size_t GetUIIndexForChild(Element* child) { return 0; }

  inline bool CanHasLayoutOnlyChildren() {
    return can_has_layout_only_children_;
  };

  float FontSize() { return font_size_; }
  void SetFontSize(const tasm::CSSValue* value);
  starlight::DirectionType Direction() { return direction_; }

  virtual void OnPseudoStatusChanged(PseudoState prev_status,
                                     PseudoState current_status) {}

  ContentData* content_data() const { return content_data_.get(); }
  void SetContentData(ContentData* data) { content_data_.reset(data); }
  virtual void UpdateDynamicElementStyle() {}

  bool HasPlaceHolder() { return has_placeholder_; }

  PaintingContext* painting_context();

  std::string GetTag() { return tag_.str(); }
  void UpdateElement();
  int ZIndex() {
    return GetEnableZIndex() ? computed_css_style()->GetZIndex() : 0;
  }
  bool HasElementContainer() { return element_container_ != nullptr; }
  bool IsStackingContextNode();
  ElementContainer* element_container() { return element_container_.get(); }
  void CreateElementContainer(bool platform_is_flatten);

  std::unique_ptr<ElementContainer> element_container_;
  bool is_fixed_{false};
  bool is_sticky_{false};
  // indicate the element's position:fixed style has changed
  bool fixed_changed_{false};
  DynamicCSSStylesManager& StylesManager() { return styles_manager_; }

  void set_parent(Element* parent) { parent_ = parent; }
  bool EnableTriggerGlobalEvent() const { return trigger_global_event_; }

  void PreparePropBundleIfNeed();

  bool GetEnableZIndex();

  void MarkLayoutDirty();
  inline const std::unordered_map<tasm::CSSPropertyID, CSSValue>& styles()
      const {
    return styles_;
  }
  inline const lepus::Value& attributes() const { return attributes_; }
  inline const std::set<std::string>& GlobalBindTarget() {
    return global_bind_target_set_;
  }
  virtual bool CanBeLayoutOnly() const = 0;

  bool IsSetBaselineOnView(CSSPropertyID id, const tasm::CSSValue& value);
  bool IsSetBaselineOnInlineView(CSSPropertyID id, const tasm::CSSValue& value);

  void CheckHasInlineContainer(Element* parent);

  bool FlushAnimatedStyle();

  BASE_EXPORT_FOR_DEVTOOL std::string GetLayoutTree();

  float width() { return width_; }
  float height() { return height_; }
  float top() { return top_; }
  float left() { return left_; }
  inline bool enable_new_animator() { return !enable_new_animator_.empty(); }

  PropertiesResolvingStatus GenerateRootPropertyStatus() const;

  void SetDirection(const tasm::CSSValue& value) {
    styles_manager_.UpdateDirectionStyle(value);
  }

  void SetComputedFontSize(const tasm::CSSValue& value, double font_size,
                           double root_font_size, bool force_update = false);
  void SetPlaceHolderStylesInternal(const PseudoPlaceHolderStyles& styles);

  void ResetStyleInternal(CSSPropertyID id);
  void SetDirectionInternal(const tasm::CSSValue& value) {
    direction_ = value.GetEnum<starlight::DirectionType>();
    SetStyleInternal(kPropertyIDDirection, value);
  }
  void ResetDirectionInternal() {
    direction_ = starlight::DefaultCSSStyle::SL_DEFAULT_DIRECTION;
    ResetStyleInternal(kPropertyIDDirection);
  }
  void ResetFontSizeInternalLegacy();
  inline const std::array<float, 4>& borders() { return borders_; }
  inline const std::array<float, 4>& paddings() { return paddings_; }
  inline const std::array<float, 4>& margins() { return margins_; }
  inline float max_height() { return max_height_; }
  inline bool need_update() { return subtree_need_update_; }
  inline bool frame_changed() { return frame_changed_; }
  inline void MarkUpdated() {
    subtree_need_update_ = false;
    frame_changed_ = false;
  }

  inline void set_config_flatten(bool value) { config_flatten_ = value; }

  void MarkSubtreeNeedUpdate();
  void NotifyElementSizeUpdatedToAnimation();
  inline void set_is_layout_only(bool is_layout_only) {
    is_layout_only_ = is_layout_only;
  }

  bool TendToFlatten();

  static constexpr short OVERFLOW_HIDDEN = 0x00;
  static constexpr short OVERFLOW_X = 0x01;
  static constexpr short OVERFLOW_Y = 0x02;
  static constexpr short OVERFLOW_XY = (OVERFLOW_X | OVERFLOW_Y);
  short overflow() { return overflow_; }

  void CheckOverflow(CSSPropertyID id, const tasm::CSSValue& value);

  bool HasPaintingNode() { return has_painting_node_; }
  void ResetPropBundle();
  void ResetFontSize();

  void PreparePropsBundleForDynamicCSS();
  bool CheckFlattenProp(const lepus::String& key,
                        const lepus::Value& value = lepus::Value(true));
  bool CheckEventProp(const lepus::String& key, const lepus::Value& value);
  void CheckHasPlaceholder(const lepus::String& key,
                           const lepus::Value& value = lepus::Value(true));
  void CheckHasNonFlattenAttr(const lepus::String& key,
                              const lepus::Value& value = lepus::Value(true));
  void CheckHasUserInteractionEnabled(
      const lepus::String& key, const lepus::Value& value = lepus::Value(true));
  void CheckTriggerGlobalEvent(const lynx::lepus::String& key,
                               const lynx::lepus::Value& value);
  void CheckGlobalBindTarget(
      const lynx::lepus::String& key,
      const lynx::lepus::Value& value = lepus::Value(""));
  void CheckNewAnimatorAttr(const lepus::String& key,
                            const lepus::Value& value = lepus::Value(true));
  void CheckHasOpacityProps(CSSPropertyID id, bool reset);
  // return true indicates current style is transtion related
  bool CheckTransitionProps(CSSPropertyID id);
  // return true indicates current style is keyframe related
  bool CheckKeyframeProps(CSSPropertyID id);

  // return true indicates current style is animated related
  // TODO(wujintian): to be removed later!
  virtual void CheckAnimateProps(CSSPropertyID id) {}

  void CheckHasNonFlattenCSSProps(CSSPropertyID id);
  void CheckFixedSticky(CSSPropertyID id, const tasm::CSSValue& value);
  // return true indicate that current css is z-index
  bool CheckZIndexProps(CSSPropertyID id, bool reset);
  void CheckBoxShadowOrOutline(CSSPropertyID id);
  bool DisableFlattenWithOpacity();

  void PushToBundle(CSSPropertyID id);

  inline starlight::ComputedCSSStyle* computed_css_style() {
    return platform_css_style_.get();
  }

  void SetDataToNativeKeyframeAnimator();
  void SetDataToNativeTransitionAnimator();

  bool ShouldConsumeTransitionStylesInAdvance();
  void ConsumeTransitionStylesInAdvance(const StyleMap& styles,
                                        bool force_reset = false);

  virtual void ResolveStyleValue(CSSPropertyID id, const tasm::CSSValue& value,
                                 bool force_update) {}
  virtual void CheckViewportUnit(CSSPropertyID id, CSSValue value) {
    // currently, radon element do no need to such kind of check
  }
  virtual void ConsumeTransitionStylesInAdvanceInternal(
      CSSPropertyID css_id, const tasm::CSSValue& value) = 0;
  void ResetTransitionStylesInAdvance(
      const std::vector<CSSPropertyID>& css_names);
  virtual void ResetTransitionStylesInAdvanceInternal(CSSPropertyID css_id) = 0;

  void ResolveAndFlushKeyframes();

  virtual void CheckBaseline(CSSPropertyID id, CSSValue value) {}
  void RecordElementPreviousStyle(CSSPropertyID css_id,
                                  const tasm::CSSValue& value);
  void ResetElementPreviousStyle(CSSPropertyID css_id);

  std::optional<CSSValue> GetElementPreviousStyle(tasm::CSSPropertyID css_id);

  virtual std::optional<CSSValue> GetElementStyle(tasm::CSSPropertyID css_id);

  CSSKeyframesToken* GetCSSKeyframesToken(const std::string& animation_name);

  virtual CSSFragment* GetRelatedCSSFragment() = 0;

  virtual void FlushProps() {}

  void set_will_destroy(bool destroy) { will_destroy_ = destroy; }

  bool will_destroy() { return will_destroy_; }

  virtual void DestroyPlatformNode() {}

  void TickAllAnimation(fml::TimePoint& time);

  void RequestNextFrameTime();

  void SetFinalStyleMap(StyleMap& map) { final_animator_map_ = map; }

  void UpdateFinalStyleMap(const StyleMap& styles);

  virtual void OnPatchFinish(const PipelineOptions& option) = 0;

  // for devtool
 public:
  ALLOW_UNUSED_TYPE std::unique_ptr<InspectorAttribute> inspector_attribute_;

 protected:
  // relevant to flatten
  bool support_flatten_{false};
  bool has_event_listener_{false};
  bool has_event_prop_{false};
  bool has_animate_props_{false};
  bool has_transition_props_{false};
  bool has_keyframe_props_{false};
  bool has_non_flatten_attrs_{false};
  bool has_user_interaction_enabled_{false};
  bool has_opacity_{false};
  // relevant to z-index
  bool has_z_props_{false};

  // Should be set to false if children's layout parameter will be used on
  // platform layer. (e.g. scroll-view will use children's margin value on both
  // android and iOS)
  bool can_has_layout_only_children_{true};

  // relevant to layout only
  bool is_virtual_{false};
  lepus::String tag_;

  // indicate has platform UI(view)
  bool has_painting_node_{false};
  // indicate has platform layout node(shadow node)
  bool has_platform_layout_node_{false};
  bool is_component_{false};

  Catalyzer* catalyzer_;

  // config settings for enableLayoutOnly
  bool config_enable_layout_only_{true};
  bool has_layout_only_props_{true};

  bool enable_component_layout_only_{false};

  std::shared_ptr<PropBundle> prop_bundle_{nullptr};
  // just for unit test now.
  std::shared_ptr<PropBundle> pre_prop_bundle_{nullptr};

  // relevant to layout and frame
  float width_{0};
  float height_{0};
  float top_{0};
  float left_{0};
  // left, right, top, bottom -> starlight::Direction
  std::array<float, 4> borders_{};
  std::array<float, 4> margins_{};
  std::array<float, 4> paddings_{};
  std::array<float, 4> sticky_positions_{};
  float max_height_{starlight::DefaultCSSStyle::kDefaultMaxSize};
  bool subtree_need_update_{false};
  bool frame_changed_{false};
  // Determine by Catalyzer
  bool is_layout_only_{false};

  std::unique_ptr<ContentData> content_data_{nullptr};
  bool config_flatten_;

  std::shared_ptr<LayoutNode> layout_node_{nullptr};

  // relevant to hierarchy
  Element* parent_{nullptr};
  std::vector<Element*> children_;

  bool is_pseudo_{false};
  int pseudo_type_{0};

  // determine rem or em. default is 14dp * density px。
  double font_size_;
  double root_font_size_;

  starlight::DirectionType direction_ =
      starlight::DefaultCSSStyle::SL_DEFAULT_DIRECTION;

  short overflow_{0};

  bool has_placeholder_{false};
  bool trigger_global_event_{false};

  DynamicCSSStylesManager styles_manager_;

  int id_;
  std::weak_ptr<UIImplObserver> observer_;
  std::unique_ptr<starlight::ComputedCSSStyle> platform_css_style_;

  friend class Catalyzer;
  friend class ElementContainer;
  friend class DynamicCSSStylesManager;
  friend class animation::CSSKeyframeManager;
#ifdef ENABLE_TEST_DUMP
  friend class ElementDumpHelper;
  friend class DynamicCSSStyleTestsUtils;
#endif

  bool will_destroy_{false};
  ElementManager* element_manager_;
  std::unordered_map<tasm::CSSPropertyID, CSSValue> styles_{};
  lepus::Value attributes_{lepus::Dictionary::Create()};

  // for animation
  std::string enable_new_animator_;
  std::unique_ptr<animation::CSSKeyframeManager> css_keyframe_manager_;
  std::unique_ptr<animation::CSSTransitionManager> css_transition_manager_;
  // Saves the css style that the all animation applied to the element.
  StyleMap final_animator_map_;
  // Save the keyframes of the Animate API.
  tasm::CSSKeyframesTokenMap keyframes_map_;
  // for global-bind event
  std::set<std::string> global_bind_target_set_;

  // Using to record some previous element styles which New Animator needs.
  std::unordered_map<tasm::CSSPropertyID, CSSValue>
      animation_previous_styles_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_ELEMENT_H_
