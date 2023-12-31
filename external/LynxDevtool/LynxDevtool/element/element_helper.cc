// Copyright 2021 The Lynx Authors. All rights reserved.

#include "element_helper.h"

#include <string>

#include "agent/devtool_agent_ng.h"
#include "base/log/logging.h"
#include "base/string/string_utils.h"
#include "css/css_decoder.h"
#include "element/inspector_css_helper.h"
#include "helper_util.h"
#include "inspector/style_sheet.h"

namespace lynxdev {
namespace devtool {

bool IsAnimationNameLegal(lynx::tasm::Element* ptr, std::string name) {
  bool res = false;
  lynx::tasm::Element* style = ElementInspector::StyleRoot(ptr);
  if (style == nullptr) {
    return res;
  }
  auto animation_map = ElementInspector::GetAnimationMap(style);
  if (animation_map.find(name) != animation_map.end()) {
    res = true;
  }
  return res;
}

bool IsAnimationValueLegal(lynx::tasm::Element* ptr,
                           std::string animation_value) {
  bool res = false;

  std::vector<std::string> animation;
  static std::vector<std::string> animation_key = {"animation-name",
                                                   "animation-duration",
                                                   "animation-timing-function",
                                                   "animation-delay",
                                                   "animation-iteration-count",
                                                   "animation-direction",
                                                   "animation-fill-mode",
                                                   "animation-play-state"};
  for (size_t i = 0; i < animation_value.length(); i++) {
    int pos = static_cast<int>(animation_value.find(' ', i));
    if (pos == -1) pos = static_cast<int>(animation_value.length());
    if (!animation_value.substr(i, pos - i).empty())
      animation.push_back(animation_value.substr(i, pos - i));
    i = pos;
  }
  bool flag = IsAnimationNameLegal(ptr, animation[0]);
  for (size_t i = 1; i < animation.size(); i++) {
    if (flag) {
      flag =
          InspectorCSSHelper::IsAnimationLegal(animation_key[i], animation[i]);
    } else {
      break;
    }
  }
  if (flag) res = true;
  return res;
}

Element* ElementHelper::GetPreviousNode(Element* ptr) {
  auto parent = ptr->parent();
  if (parent == nullptr) {
    return nullptr;
  }

  auto children = parent->GetChild();
  for (auto iter = children.begin(); iter != children.end(); ++iter) {
    if ((*iter) == ptr) {
      if (iter == children.begin()) {
        if (ElementInspector::Type(parent) == InspectorElementType::COMPONENT) {
          return ElementInspector::StyleElement(
              ElementInspector::ShadowRootElement(parent));
        }
      } else {
        return (*(--iter));
      }
      break;
    }
  }
  return nullptr;
}

// when find NodeIdForLocation for swiper, we need get current swiper item and
// check whether the point in it if not found, then  traverse child nodes from
// back to the front.
int ElementHelper::SwiperNodeIdForLocation(Element* ptr, int x, int y) {
  int current_swiper_index = ElementInspector::GetCurrentIndex(ptr);
  auto* child = ptr->GetChild()[current_swiper_index];
  if (PointInNode(child, x, y)) {
    return NodeIdForLocation(child, x, y);
  }
  for (int i = static_cast<int>(ptr->GetChild().size()) - 1; i >= 0; i--) {
    if (i != current_swiper_index) {
      child = ptr->GetChild()[i];
      if (PointInNode(child, x, y)) {
        return NodeIdForLocation(child, x, y);
      }
    }
  }
  return ElementInspector::NodeId(ptr);
}

int ElementHelper::XViewPagerProNodeIdForLocation(Element* ptr, int x, int y) {
  int page_item_index = -1;
  int current_page_item_index = ElementInspector::GetCurrentIndex(ptr);
  for (int i = 0; i < static_cast<int>(ptr->GetChild().size()); i++) {
    const auto child = ptr->GetChild()[i];
    if (ElementInspector::SelectorTag(child) == "x-viewpager-item-pro") {
      page_item_index++;
      if (page_item_index == current_page_item_index) {
        if (PointInNode(child, x, y)) {
          return NodeIdForLocation(child, x, y);
        }
      }
    } else {
      if (PointInNode(child, x, y)) {
        return NodeIdForLocation(child, x, y);
      }
    }
  }
  return ElementInspector::NodeId(ptr);
}

int ElementHelper::CommonNodeIdForLocation(Element* ptr, int x, int y) {
  for (int i = static_cast<int>(ptr->GetChild().size()) - 1; i >= 0; i--) {
    const auto child = ptr->GetChild()[i];
    if (PointInNode(child, x, y) &&
        !(ElementInspector::SelectorTag(child) == "x-overlay") &&
        !(ElementInspector::SelectorTag(child) == "x-overlay-ng")) {
      return NodeIdForLocation(child, x, y);
    }
  }
  return ElementInspector::NodeId(ptr);
}

int ElementHelper::NodeIdForLocation(Element* ptr, int x, int y) {
  // Components that overlap with each other at the same level need to be
  // handled specially
  if (ElementInspector::SelectorTag(ptr) == "x-viewpager-pro") {
    return XViewPagerProNodeIdForLocation(ptr, x, y);
  } else if (ElementInspector::SelectorTag(ptr) == "x-swiper" ||
             ElementInspector::SelectorTag(ptr) == "swiper") {
    return SwiperNodeIdForLocation(ptr, x, y);
  } else {
    return CommonNodeIdForLocation(ptr, x, y);
  }
}

int ElementHelper::OverlayNodeIdForLocation(Element* ptr, int x, int y) {
  // ptr is x-overlay-ng whose size is window size
  // x-overlay-ng has only one child
  // ignore x-overlay-ng and start traversing from its child node
  // if (x,y) not in child node, return -1 to shows that (x,y) not in overlay
  Element* child = ptr->GetChild().size() ? ptr->GetChild()[0] : nullptr;
  if (child != nullptr) {
    if (PointInNode(child, x, y)) {
      return NodeIdForLocation(child, x, y);
    } else {
      return -1;
    }
  }
  return -1;
}

bool ElementHelper::PointInNode(Element* ptr, int x, int y) {
  auto res = ElementInspector::GetBoxModel(ptr);
  return !res.empty() && x >= res[18] && x <= res[20] && y >= res[19] &&
         y <= res[25];
}

Json::Value ElementHelper::GetDocumentBodyFromNode(Element* ptr, bool plug,
                                                   bool with_box_model) {
  Json::Value res = Json::Value(Json::ValueType::objectValue);
  if (!plug && ElementInspector::SlotElement(ptr) != nullptr) {
    res = GetDocumentBodyFromNode(ElementInspector::SlotElement(ptr), false,
                                  with_box_model);
  } else if (ElementInspector::Type(ptr) == InspectorElementType::COMPONENT) {
    SetJsonValueOfNode(ptr, res, with_box_model);
    res["shadowRoots"] = Json::Value(Json::ValueType::arrayValue);
    res["shadowRoots"].append(GetDocumentBodyFromNode(
        ElementInspector::ShadowRootElement(ptr), false, with_box_model));
    res["childNodeCount"] =
        static_cast<int>(ElementInspector::SlotPlug(ptr).size());
    res["children"] = Json::Value(Json::ValueType::arrayValue);
    for (auto& child : ElementInspector::SlotPlug(ptr)) {
      if (child != nullptr) {
        res["children"].append(
            GetDocumentBodyFromNode(child, true, with_box_model));
      }
    }
    if (ElementInspector::SelectorTag(ptr) == "page") {
      Json::Value doc = Json::Value(Json::ValueType::objectValue);
      SetJsonValueOfNode(ElementInspector::DocElement(ptr), doc,
                         with_box_model);
      doc["childNodeCount"] = 1;
      doc["children"] = Json::Value(Json::ValueType::arrayValue);
      doc["children"].append(res);
      return doc;
    }
  } else if (ElementInspector::GetParentComponentElementFromDataModel(ptr) &&
             ElementInspector::IsNeedEraseId(
                 ElementInspector::GetParentComponentElementFromDataModel(
                     ptr))) {
    SetJsonValueOfNode(ptr, res, with_box_model);
    res["childNodeCount"] = static_cast<int>(ptr->GetChild().size());
    res["children"] = Json::Value(Json::ValueType::arrayValue);
    for (auto& child : ptr->GetChild()) {
      res["children"].append(
          GetDocumentBodyFromNode(child, false, with_box_model));
    }

    Json::Value comp = Json::Value(Json::ValueType::objectValue);
    Element* comp_ptr =
        ElementInspector::GetParentComponentElementFromDataModel(ptr);
    SetJsonValueOfNode(comp_ptr, comp, with_box_model);
    comp["shadowRoots"] = Json::Value(Json::ValueType::arrayValue);
    {
      Json::Value shadow_root = Json::Value(Json::ValueType::objectValue);
      Element* shadow_ptr = ElementInspector::ShadowRootElement(comp_ptr);
      SetJsonValueOfNode(shadow_ptr, shadow_root, with_box_model);
      if (!ElementInspector::ShadowRootType(shadow_ptr).empty()) {
        shadow_root["shadowRootType"] =
            ElementInspector::ShadowRootType(shadow_ptr);
      }
      shadow_root["childNodeCount"] = 2;
      shadow_root["children"] = Json::Value(Json::ValueType::arrayValue);
      shadow_root["children"].append(GetDocumentBodyFromNode(
          ElementInspector::StyleElement(shadow_ptr), false, with_box_model));
      shadow_root["children"].append(res);
      comp["shadowRoots"].append(shadow_root);
    }

    comp["childNodeCount"] =
        static_cast<int>(ElementInspector::SlotPlug(comp_ptr).size());
    comp["children"] = Json::Value(Json::ValueType::arrayValue);
    for (auto& child : ElementInspector::SlotPlug(comp_ptr)) {
      if (child != nullptr) {
        comp["children"].append(
            GetDocumentBodyFromNode(child, true, with_box_model));
      }
    }
    return comp;
  } else if (ElementInspector::Type(ptr) == InspectorElementType::SHADOWROOT) {
    SetJsonValueOfNode(ptr, res, with_box_model);
    if (!ElementInspector::ShadowRootType(ptr).empty()) {
      res["shadowRootType"] = ElementInspector::ShadowRootType(ptr);
    }
    res["childNodeCount"] =
        static_cast<int>(ptr->parent()->GetChild().size()) + 1;
    res["children"] = Json::Value(Json::ValueType::arrayValue);
    res["children"].append(GetDocumentBodyFromNode(
        ElementInspector::StyleElement(ptr), false, with_box_model));
    for (auto& child : ptr->parent()->GetChild()) {
      res["children"].append(
          GetDocumentBodyFromNode(child, false, with_box_model));
    }
  } else if (ElementInspector::Type(ptr) == InspectorElementType::STYLE) {
    SetJsonValueOfNode(ptr, res, with_box_model);
    res["childNodeCount"] = 1;
    res["children"] = Json::Value(Json::ValueType::arrayValue);
    res["children"].append(GetDocumentBodyFromNode(
        ElementInspector::StyleValueElement(ptr), false, with_box_model));
  } else if (ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
    SetJsonValueOfNode(ptr, res, with_box_model);
    res["childNodeCount"] = 0;
    res["children"] = Json::Value(Json::ValueType::arrayValue);
  } else {
    SetJsonValueOfNode(ptr, res, with_box_model);
    res["childNodeCount"] = static_cast<int>(ptr->GetChild().size());
    res["children"] = Json::Value(Json::ValueType::arrayValue);
    for (auto& child : ptr->GetChild()) {
      res["children"].append(
          GetDocumentBodyFromNode(child, false, with_box_model));
    }
  }

  return res;
}

void ElementHelper::SetJsonValueOfNode(Element* ptr, Json::Value& value,
                                       bool with_box_model) {
  value["backendNodeId"] = ElementInspector::NodeId(ptr);
  value["nodeId"] = ElementInspector::NodeId(ptr);
  value["nodeType"] = ElementInspector::NodeType(ptr);
  value["localName"] = ElementInspector::LocalName(ptr);
  value["nodeName"] = ElementInspector::NodeName(ptr);
  value["nodeValue"] = ElementInspector::NodeValue(ptr);

  // If element is plug, then set the corresponding slot info as assignedSlot to
  // the value.
  if (ptr->inspector_attribute_->slot_ != nullptr) {
    Json::Value assigned_slot = Json::Value(Json::ValueType::objectValue);
    assigned_slot["backendNodeId"] = Json::Value(
        ElementInspector::NodeId(ptr->inspector_attribute_->slot_.get()));
    assigned_slot["nodeName"] = Json::Value(
        ElementInspector::NodeName(ptr->inspector_attribute_->slot_.get()));
    assigned_slot["nodeType"] = Json::Value(
        ElementInspector::NodeType(ptr->inspector_attribute_->slot_.get()));
    value["assignedSlot"] = assigned_slot;
  }

  auto parent = ptr->parent();
  if (parent != nullptr) {
    value["parentId"] = ElementInspector::NodeId(parent);
  }

  value["attributes"] = Json::Value(Json::ValueType::arrayValue);
  if (ptr != nullptr) {
    for (const auto& name : ElementInspector::AttrOrder(ptr)) {
      value["attributes"].append(Json::Value(name));
      value["attributes"].append(
          Json::Value(ElementInspector::AttrMap(ptr).at(name)));
    }
    for (const auto& name : ElementInspector::DataOrder(ptr)) {
      value["attributes"].append(Json::Value(name));
      value["attributes"].append(
          Json::Value(ElementInspector::DataMap(ptr).at(name)));
    }
    for (const auto& name : ElementInspector::EventOrder(ptr)) {
      value["attributes"].append(Json::Value(name));
      value["attributes"].append(
          Json::Value(ElementInspector::EvenMap(ptr).at(name)));
    }
    if (!ElementInspector::ClassOrder(ptr).empty()) {
      value["attributes"].append(Json::Value("class"));
      std::string temp;
      for (const auto& str : ElementInspector::ClassOrder(ptr)) {
        temp += str.substr(1);
        if (str != ElementInspector::ClassOrder(ptr).back()) {
          temp += " ";
        }
      }
      value["attributes"].append(Json::Value(temp));
    }
    if (!ElementInspector::GetInlineStyleSheet(ptr).css_properties_.empty()) {
      value["attributes"].append(Json::Value("style"));
      value["attributes"].append(
          Json::Value(ElementInspector::GetInlineStyleSheet(ptr).css_text_));
    }
    if (ElementInspector::IsNeedEraseId(ptr)) {
      value["attributes"].append(Json::Value("fake-element"));
      value["attributes"].append(Json::Value("true"));
    }
    // If element is plug, then append the corresponding slot name to the
    // attributes.
    if (ptr->inspector_attribute_->slot_ != nullptr) {
      value["attributes"].append(Json::Value("slot"));
      value["attributes"].append(
          ptr->inspector_attribute_->slot_->inspector_attribute_->slot_name_
              .c_str());
    }
  }

  // if with_box_model is true, attach box_model for node except
  // document,document-fragment,style,stylevalue node
  if (with_box_model) {
    double screen_scale_factor = 1.0f;
    Json::Value res = GetBoxModelOfNode(ptr, screen_scale_factor);
    value["box_model"] = res["model"];
  }
}

Json::Value ElementHelper::GetMatchedStylesForNode(Element* ptr) {
  Json::Value content;
  if (ptr != nullptr && ElementInspector::HasDataModel(ptr)) {
    content["cssKeyframesRules"] = GetKeyframesRulesForNode(ptr);
    content["pseudoElements"] = Json::Value(Json::ValueType::arrayValue);
    content["inlineStyle"] = GetInlineStyleOfNode(ptr);
    content["matchedCSSRules"] = GetMatchedCSSRulesOfNode(ptr);
    content["inherited"] = GetInheritedCSSRulesOfNode(ptr);
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Node is not an Element");
    content["error"] = error;
  }
  return content;
}

void ElementHelper::FillKeyFramesRule(
    Element* ptr,
    const std::unordered_multimap<std::string, CSSPropertyDetail>& css_property,
    Json::Value& content, std::set<std::string>& animation_name_set,
    const std::string& key) {
  auto range = css_property.equal_range(key);
  for (auto it = range.first; it != range.second; ++it) {
    auto field = range.first->second;
    if (field.parsed_ok_ && !field.disabled_) {
      auto anim_names = GetAnimationNames(field.value_, key == "animation");
      for (auto&& anim_name : anim_names) {
        auto pair = GetKeyframesRule(anim_name, ptr);
        if (!pair.first) continue;
        Json::Value keyframes_rule = pair.second;
        std::string name = keyframes_rule["animationName"]["text"].asString();
        if (animation_name_set.find(name) == animation_name_set.end()) {
          content.append(keyframes_rule);
          animation_name_set.insert(name);
        }
      }
    }
  }
}

void ElementHelper::FillKeyFramesRuleByStyleSheet(
    Element* ptr, const InspectorStyleSheet& style_sheet, Json::Value& content,
    std::set<std::string>& animation_name_set) {
  const auto& css_property = style_sheet.css_properties_;
  if (css_property.find("animation-name") != css_property.end()) {
    FillKeyFramesRule(ptr, css_property, content, animation_name_set,
                      "animation-name");
  } else if (css_property.find("animation") != css_property.end()) {
    FillKeyFramesRule(ptr, css_property, content, animation_name_set,
                      "animation");
  }
}

Json::Value ElementHelper::GetKeyframesRulesForNode(Element* ptr) {
  Json::Value content(Json::ValueType::arrayValue);
  if (ptr == nullptr) return content;
  auto class_vec = ElementInspector::ClassOrder(ptr);
  std::set<std::string> animation_name_set;

  if (ElementInspector::IsEnableCSSSelector(ptr)) {
    const std::vector<lynxdev::devtool::InspectorStyleSheet>& match_rules =
        ElementInspector::GetMatchedStyleSheet(ptr);
    for (const auto& match : match_rules) {
      FillKeyFramesRuleByStyleSheet(ptr, match, content, animation_name_set);
    }
  } else {
    for (auto cls : class_vec) {
      const auto& style_sheet = ElementInspector::GetStyleSheetByName(ptr, cls);
      FillKeyFramesRuleByStyleSheet(ptr, style_sheet, content,
                                    animation_name_set);
    }
  }
  const auto& inline_stylesheet = ElementInspector::GetInlineStyleSheet(ptr);
  FillKeyFramesRuleByStyleSheet(ptr, inline_stylesheet, content,
                                animation_name_set);

  return content;
}

std::pair<bool, Json::Value> ElementHelper::GetKeyframesRule(
    const std::string& name, Element* ptr) {
  Json::Value keyframes_rule(Json::ValueType::objectValue);

  keyframes_rule["animationName"] = Json::Value(Json::ValueType::objectValue);
  keyframes_rule["keyframes"] = Json::Value(Json::ValueType::arrayValue);
  keyframes_rule["animationName"]["text"] = name;

  Element* style = ElementInspector::StyleRoot(ptr);
  if (style == nullptr) return std::make_pair(false, keyframes_rule);

  auto animation = ElementInspector::GetAnimationKeyframeByName(ptr, name);
  if (animation.empty()) {
    return std::make_pair(false, keyframes_rule);
  }

  for (auto part : animation) {
    Json::Value keyframe = Json::Value(Json::ValueType::objectValue);
    keyframe["keyText"] = Json::Value(Json::ValueType::objectValue);
    keyframe["keyText"]["text"] = part.key_text_;
    keyframe["origin"] = part.style_.origin_;
    keyframe["style"] = Json::Value(Json::ValueType::objectValue);
    keyframe["style"]["styleSheetId"] = part.style_.style_sheet_id_;
    keyframe["style"]["cssProperties"] =
        Json::Value(Json::ValueType::arrayValue);
    for (auto prop : part.style_.property_order_) {
      Json::Value property = Json::Value(Json::ValueType::objectValue);
      property["name"] = prop;
      property["value"] = part.style_.css_properties_.find(prop)->second.value_;
      keyframe["style"]["cssProperties"].append(property);
    }
    keyframe["style"]["shorthandEntries"] =
        Json::Value(Json::ValueType::arrayValue);
    for (auto entry : part.style_.shorthand_entries_) {
      Json::Value shorthand_entry = Json::Value(Json::ValueType::objectValue);
      shorthand_entry["name"] = entry.first;
      shorthand_entry["value"] = entry.second.value_;
      keyframe["style"]["shorthandEntries"].append(shorthand_entry);
    }
    keyframes_rule["keyframes"].append(keyframe);
  }
  return std::make_pair(true, keyframes_rule);
}

Json::Value ElementHelper::GetInlineStyleOfNode(Element* ptr) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value temp(Json::ValueType::objectValue);
  Json::Value range(Json::ValueType::objectValue);
  if (ptr != nullptr) {
    InspectorStyleSheet inline_style_sheet =
        ElementInspector::GetInlineStyleSheet(ptr);
    if (!inline_style_sheet.empty) {
      content["shorthandEntries"] = Json::Value(Json::ValueType::arrayValue);
      content["cssProperties"] = Json::Value(Json::ValueType::arrayValue);
      auto& css_properties = inline_style_sheet.css_properties_;
      for (auto& item : css_properties) item.second.looped_ = false;
      for (const auto& name : inline_style_sheet.property_order_) {
        auto iter_range = css_properties.equal_range(name);
        for (auto it = iter_range.first; it != iter_range.second; ++it) {
          if (it->second.looped_) continue;
          CSSPropertyDetail& css_property_detail = it->second;
          css_property_detail.looped_ = true;
          temp["name"] = name;
          if (name == "animation") {
            temp["value"] =
                NormalizeAnimationString(css_property_detail.value_);
          } else {
            temp["value"] = css_property_detail.value_;
          }
          temp["implicit"] = css_property_detail.implicit_;
          temp["disabled"] = css_property_detail.disabled_;
          temp["parsedOk"] = css_property_detail.parsed_ok_;
          temp["text"] = css_property_detail.text_;
          range["startLine"] = css_property_detail.property_range_.start_line_;
          range["startColumn"] =
              css_property_detail.property_range_.start_column_;
          range["endLine"] = css_property_detail.property_range_.end_line_;
          range["endColumn"] = css_property_detail.property_range_.end_column_;
          temp["range"] = range;
          content["cssProperties"].append(temp);
          break;
        }
      }
      range["startLine"] = inline_style_sheet.style_value_range_.start_line_;
      range["startColumn"] =
          inline_style_sheet.style_value_range_.start_column_;
      range["endLine"] = inline_style_sheet.style_value_range_.end_line_;
      range["endColumn"] = inline_style_sheet.style_value_range_.end_column_;
      content["range"] = range;
      content["cssText"] = inline_style_sheet.css_text_;
      content["styleSheetId"] = inline_style_sheet.style_sheet_id_;
    }
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Node is not an Element");
    content["error"] = error;
  }
  return content;
}

Json::Value ElementHelper::GetBackGroundColorsOfNode(Element* ptr) {
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  if (ptr != nullptr && ElementInspector::HasDataModel(ptr)) {
    auto dict = ElementInspector::GetDefaultCss();
    if (ElementInspector::IsEnableCSSSelector(ptr)) {
      const std::vector<InspectorStyleSheet>& match_rules =
          ElementInspector::GetMatchedStyleSheet(ptr);
      for (const auto& match : match_rules) {
        ReplaceDefaultComputedStyle(dict, match.css_properties_);
      }
    } else {
      ReplaceDefaultComputedStyle(
          dict,
          ElementInspector::GetStyleSheetByName(ptr, "*").css_properties_);
      ReplaceDefaultComputedStyle(
          dict,
          ElementInspector::GetStyleSheetByName(ptr, "body *").css_properties_);
      for (size_t i = 0; i < ElementInspector::ClassOrder(ptr).size(); ++i) {
        ReplaceDefaultComputedStyle(
            dict, ElementInspector::GetStyleSheetByName(
                      ptr, ElementInspector::ClassOrder(ptr)[i])
                      .css_properties_);
      }
      ReplaceDefaultComputedStyle(dict,
                                  ElementInspector::GetStyleSheetByName(
                                      ptr, ElementInspector::SelectorTag(ptr))
                                      .css_properties_);
      ReplaceDefaultComputedStyle(dict,
                                  ElementInspector::GetStyleSheetByName(
                                      ptr, ElementInspector::SelectorId(ptr))
                                      .css_properties_);
    }
    ReplaceDefaultComputedStyle(
        dict, ElementInspector::GetInlineStyleSheet(ptr).css_properties_);
    Json::Value background_colors(Json::ValueType::arrayValue);
    background_colors.append(dict.at("background-color"));
    content["backgroundColors"] = background_colors;
    content["computedFontSize"] = dict.at("font-size");
    content["computedFontWeight"] = dict.at("font-weight");
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Node is not an Element");
    content["error"] = error;
  }
  return content;
}

Json::Value ElementHelper::GetComputedStyleOfNode(Element* ptr) {
  Json::Value res = Json::Value(Json::ValueType::arrayValue);
  Json::Value temp = Json::Value(Json::ValueType::objectValue);
  if (ptr != nullptr && ElementInspector::HasDataModel(ptr)) {
    auto dict = ElementInspector::GetDefaultCss();

    if (ElementInspector::IsEnableCSSSelector(ptr)) {
      const std::vector<InspectorStyleSheet>& match_rules =
          ElementInspector::GetMatchedStyleSheet(ptr);
      for (const auto& match : match_rules) {
        ReplaceDefaultComputedStyle(dict, match.css_properties_);
      }
    } else {
      ReplaceDefaultComputedStyle(
          dict,
          ElementInspector::GetStyleSheetByName(ptr, "*").css_properties_);
      ReplaceDefaultComputedStyle(
          dict,
          ElementInspector::GetStyleSheetByName(ptr, "body *").css_properties_);
      for (size_t i = 0; i < ElementInspector::ClassOrder(ptr).size(); ++i) {
        ReplaceDefaultComputedStyle(
            dict, ElementInspector::GetStyleSheetByName(
                      ptr, ElementInspector::ClassOrder(ptr)[i])
                      .css_properties_);
      }
      ReplaceDefaultComputedStyle(dict,
                                  ElementInspector::GetStyleSheetByName(
                                      ptr, ElementInspector::SelectorId(ptr))
                                      .css_properties_);
      ReplaceDefaultComputedStyle(dict,
                                  ElementInspector::GetStyleSheetByName(
                                      ptr, ElementInspector::SelectorTag(ptr))
                                      .css_properties_);
    }

    ReplaceDefaultComputedStyle(
        dict, ElementInspector::GetInlineStyleSheet(ptr).css_properties_);
    auto box_info = ElementInspector::GetBoxModel(ptr);
    if (!box_info.empty()) {
      dict["width"] = lynx::tasm::CSSDecoder::ToPxValue(box_info[0]);
      dict["height"] = lynx::tasm::CSSDecoder::ToPxValue(box_info[1]);

      // clang-format off
      //margin 26-33 border 18-25 padding 10-17 content 2-9

        ///   (26,27)-------------------------------------------------(28,29)
        ///     |   (18,19) --------------------------------(20,21)     |
        ///     |         |    (10,11)------------------(12,13)    |          |
        ///     |         |      |       (2,3) ------(4,5)          |       |          |
        ///     |         |      |         |               |               |       |          |
        ///     |         |      |         |               |               |       |          |
        ///     |         |      |       (8,9)-------(6,7)          |       |          |
        ///     |         |   (16,17) ------------------(14,15)    |          |
        ///     |     (24,25) ------------------------------(22,23)      |
        ///   (32,33)   -------------------------------------------  (30,31)

      // clang-format on
      // margin
      dict["margin-left"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[18] - box_info[26]);
      dict["margin-top"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[19] - box_info[27]);
      dict["margin-right"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[28] - box_info[20]);
      dict["margin-bottom"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[33] - box_info[25]);
      if (dict["margin-left"] == dict["margin-right"] &&
          dict["margin-left"] == dict["margin-top"] &&
          dict["margin-left"] == dict["margin-bottom"]) {
        dict["margin"] = dict["margin-left"];
      } else {
        std::ostringstream margin_str;
        margin_str << dict["margin-top"] << " " << dict["margin-right"] << " "
                   << dict["margin-bottom"] << " " << dict["margin-left"];
        dict["margin"] = margin_str.str();
      }

      // border
      dict["border-left-width"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[10] - box_info[18]);
      dict["border-right-width"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[20] - box_info[12]);
      dict["border-top-width"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[11] - box_info[19]);
      dict["border-bottom-width"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[25] - box_info[17]);

      if (dict["border-left"] == dict["border-right"] &&
          dict["border-left"] == dict["border-top"] &&
          dict["border-left"] == dict["border-bottom"]) {
        dict["border"] = dict["border-left"];
      } else {
        std::ostringstream margin_str;
        margin_str << dict["border-top"] << " " << dict["border-right"] << " "
                   << dict["border-bottom"] << " " << dict["border-left"];
        dict["border"] = margin_str.str();
      }

      // padding
      dict["padding-left"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[2] - box_info[10]);
      dict["padding-top"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[3] - box_info[11]);
      dict["padding-right"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[12] - box_info[4]);
      dict["padding-bottom"] =
          lynx::tasm::CSSDecoder::ToPxValue(box_info[17] - box_info[9]);

      if (dict["padding-left"] == dict["padding-right"] &&
          dict["padding-left"] == dict["padding-top"] &&
          dict["padding-left"] == dict["padding-bottom"]) {
        dict["padding"] = dict["padding-left"];
      } else {
        std::ostringstream margin_str;
        margin_str << dict["padding-top"] << " " << dict["padding-right"] << " "
                   << dict["padding-bottom"] << " " << dict["padding-left"];
        dict["border"] = margin_str.str();
      }
    }

    dict["font-size"] = lynx::tasm::CSSDecoder::ToPxValue(
        ptr->FontSize() / ElementInspector::GetDeviceDensity());

    for (const auto& pair : dict) {
      if (pair.first != "") {
        temp["name"] = pair.first;
        if (pair.first.find("color") != std::string::npos) {
          temp["value"] =
              lynx::tasm::CSSDecoder::ToRgbaFromColorValue(pair.second);
        } else {
          temp["value"] = pair.second;
        }
        res.append(temp);
      }
    }
  }
  return res;
}

Json::Value ElementHelper::GetMatchedCSSRulesOfNode(Element* ptr) {
  Json::Value res(Json::ValueType::arrayValue);
  if (!ptr || !ElementInspector::HasDataModel(ptr)) {
    return res;
  }

  if (ElementInspector::IsEnableCSSSelector(ptr)) {
    const std::vector<lynxdev::devtool::InspectorStyleSheet>& match_styles =
        ElementInspector::GetMatchedStyleSheet(ptr);

    for (const auto& matched : match_styles) {
      MergeCSSStyle(res, matched, true);
    }
  } else {
    MergeCSSStyle(res, ElementInspector::GetStyleSheetByName(ptr, "*"), false);
    if (ElementInspector::Type(ptr) != InspectorElementType::HTMLBODY) {
      MergeCSSStyle(res, ElementInspector::GetStyleSheetByName(ptr, "body *"),
                    false);
    }
    MergeCSSStyle(res,
                  ElementInspector::GetStyleSheetByName(
                      ptr, ElementInspector::SelectorTag(ptr)),
                  false);
    ApplyPseudoChildStyle(ptr, res, ElementInspector::SelectorTag(ptr));

    for (const auto& name : ElementInspector::ClassOrder(ptr)) {
      MergeCSSStyle(res, ElementInspector::GetStyleSheetByName(ptr, name),
                    false);
      ApplyCascadeStyles(ptr, res, name);
      ApplyPseudoChildStyle(ptr, res, name);
      ApplyPseudoCascadeStyles(ptr, res, name);
    }
    if (!ElementInspector::SelectorId(ptr).empty()) {
      MergeCSSStyle(res,
                    ElementInspector::GetStyleSheetByName(
                        ptr, ElementInspector::SelectorId(ptr)),
                    false);
      ApplyCascadeStyles(ptr, res, ElementInspector::SelectorId(ptr));
      ApplyPseudoChildStyle(ptr, res, ElementInspector::SelectorId(ptr));
      ApplyPseudoCascadeStyles(ptr, res, ElementInspector::SelectorId(ptr));
    }
  }
  return res;
}

void ElementHelper::ApplyCascadeStyles(Element* ptr, Json::Value& result,
                                       const std::string& rule) {
  if (ElementInspector::IsStyleRootHasCascadeStyle(ptr)) {
    auto* parent = ptr->parent();
    while (parent) {
      for (const auto& parent_rule : ElementInspector::ClassOrder(parent)) {
        auto style_sheet =
            ElementInspector::GetStyleSheetByName(ptr, rule + parent_rule);
        if (!style_sheet.empty) MergeCSSStyle(result, style_sheet, false);
      }
      parent = parent->parent();
    }

    parent = ptr->parent();
    while (parent) {
      if (!ElementInspector::SelectorId(parent).empty()) {
        auto style_sheet = ElementInspector::GetStyleSheetByName(
            ptr, rule + ElementInspector::SelectorId(parent));
        if (!style_sheet.empty) MergeCSSStyle(result, style_sheet, false);
      }
      parent = parent->parent();
    }
  }
}

void ElementHelper::ApplyPseudoCascadeStyles(Element* ptr, Json::Value& result,
                                             const std::string& rule) {
  if (ElementInspector::IsStyleRootHasCascadeStyle(ptr)) {
    auto* parent = ptr->parent();
    while (parent) {
      for (const auto& parent_rule : ElementInspector::ClassOrder(parent)) {
        ApplyPseudoChildStyle(ptr, result, rule + parent_rule);
      }
      parent = parent->parent();
    }

    parent = ptr->parent();
    while (parent) {
      if (!ElementInspector::SelectorId(parent).empty()) {
        ApplyPseudoChildStyle(ptr, result,
                              rule + ElementInspector::SelectorId(parent));
      }
      parent = parent->parent();
    }
  }
}

std::string ElementHelper::GetPseudoChildNameForStyle(
    const std::string& rule, const std::string& pseudo_child) {
  std::string pseudo_style;
  size_t dot_index = rule.find_last_of(".");
  size_t id_index = rule.find_last_of("#");

  if (dot_index != std::string::npos && dot_index != 0) {
    std::string child_name = rule.substr(0, dot_index);
    std::string parent_name = rule.substr(dot_index);
    pseudo_style = child_name + pseudo_child + parent_name;
  } else if (id_index != std::string::npos && id_index != 0) {
    std::string child_name = rule.substr(0, id_index);
    std::string parent_name = rule.substr(id_index);
    pseudo_style = child_name + pseudo_child + parent_name;
  } else {
    pseudo_style = rule + pseudo_child;
  }
  return pseudo_style;
}

void ElementHelper::ApplyPseudoChildStyle(Element* ptr, Json::Value& result,
                                          const std::string& rule) {
  if (!ptr->parent()) {
    return;
  }
  if (ptr == ptr->parent()->GetChildAt(0)) {
    auto style_sheet = ElementInspector::GetStyleSheetByName(
        ptr, GetPseudoChildNameForStyle(rule, ":first-child"));
    if (!style_sheet.empty) MergeCSSStyle(result, style_sheet, false);
  }
  if (ptr == ptr->parent()->GetChildAt(ptr->GetChildCount() - 1)) {
    auto style_sheet = ElementInspector::GetStyleSheetByName(
        ptr, GetPseudoChildNameForStyle(rule, ":last-child"));
    if (!style_sheet.empty) MergeCSSStyle(result, style_sheet, false);
  }
}

Json::Value ElementHelper::GetStyleSheetText(
    Element* ptr, const std::string& style_sheet_id) {
  Json::Value content;
  std::string text;
  if (ElementInspector::Type(ptr) != InspectorElementType::DOCUMENT) {
    auto style_root = ElementInspector::StyleRoot(ptr);
    if (style_root != nullptr) {
      std::unordered_map<std::string, InspectorStyleSheet>& map =
          ElementInspector::GetStyleSheetMap(style_root);
      text += !map.empty() ? "\n" : "";
      for (const auto& item : map) {
        const InspectorStyleSheet& cur_style_sheet = item.second;
        text += cur_style_sheet.style_name_ + kPaddingCurlyBrackets +
                cur_style_sheet.css_text_ + "}\n";
      }
    }
  } else {
    // element type is document
    auto document_ptr = ptr;
    const auto& css_rules = ElementInspector::GetCssRules(document_ptr);
    for (const auto& css_rule : css_rules) {
      text += css_rule.style_.style_name_ + kPaddingCurlyBrackets +
              css_rule.style_.css_text_ + "}\n";
    }
  }
  content["text"] = text;
  return content;
}

Json::Value ElementHelper::GetInheritedCSSRulesOfNode(Element* ptr) {
  Json::Value res(Json::ValueType::arrayValue);
  Json::Value content(Json::ValueType::objectValue);
  auto parent_ptr = ptr->parent();
  while (parent_ptr != nullptr && ElementInspector::HasDataModel(parent_ptr)) {
    content["inlineStyle"] = GetInlineStyleOfNode(parent_ptr);
    content["matchedCSSRules"] = GetMatchedCSSRulesOfNode(parent_ptr);
    res.append(content);
    parent_ptr = parent_ptr->parent();
  }
  return res;
}

Json::Value ElementHelper::GetBoxModelOfNode(Element* ptr,
                                             double screen_scale_factor) {
  Json::Value res(Json::ValueType::objectValue);
  if (ElementInspector::Type(ptr) == InspectorElementType::SLOT) {
    ptr = ElementInspector::PlugElement(ptr);
  } else if (ElementInspector::IsNeedEraseId(ptr)) {
    ptr = ElementInspector::GetChildElementForComponentRemoveView(ptr);
  }
  if (ptr != nullptr && ElementInspector::HasDataModel(ptr) &&
      !ElementInspector::GetBoxModel(ptr).empty()) {
    Json::Value model(Json::ValueType::objectValue);
    auto box_model = ElementInspector::GetBoxModel(ptr);
    model["width"] = box_model[0] / ElementInspector::GetDeviceDensity() *
                     screen_scale_factor;
    model["height"] = box_model[1] / ElementInspector::GetDeviceDensity() *
                      screen_scale_factor;
    // content
    model["content"] = Json::Value(Json::ValueType::arrayValue);
    for (int i = 2; i <= 9; ++i) {
      model["content"].append(box_model[i] /
                              ElementInspector::GetDeviceDensity() *
                              screen_scale_factor);
    }
    // padding
    model["padding"] = Json::Value(Json::ValueType::arrayValue);
    for (int i = 10; i <= 17; ++i) {
      model["padding"].append(box_model[i] /
                              ElementInspector::GetDeviceDensity() *
                              screen_scale_factor);
    }
    // border
    model["border"] = Json::Value(Json::ValueType::arrayValue);
    for (int i = 18; i <= 25; ++i) {
      model["border"].append(box_model[i] /
                             ElementInspector::GetDeviceDensity() *
                             screen_scale_factor);
    }
    // margin
    model["margin"] = Json::Value(Json::ValueType::arrayValue);
    for (int i = 26; i <= 33; ++i) {
      model["margin"].append(box_model[i] /
                             ElementInspector::GetDeviceDensity() *
                             screen_scale_factor);
    }
// for ios and android, screencast range from lynxview to full screen
// e2e test requires compatibility with lynxView and fullscreen screencast based
// on model["absolute"] renderkit screenshot unchanged, so no model["absolute"]
// message will be sent
#if !ENABLE_RENDERKIT
    model["absolute"] = true;
#endif
    res["model"] = model;
  } else {
    auto error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Could not compute box model.");
    res["error"] = error;
  }
  return res;
}

Json::Value ElementHelper::GetNodeForLocation(Element* root, int x, int y) {
  Json::Value res(Json::ValueType::objectValue);
  x = x * ElementInspector::GetDeviceDensity();
  y = y * ElementInspector::GetDeviceDensity();
  if (root != nullptr) {
    int id = -1;
#if !ENABLE_RENDERKIT
    std::vector<int> overlays = ElementInspector::getVisibleOverlayView(root);
    if (overlays.size() != 0) {
      for (int i = static_cast<int>(overlays.size()) - 1; i >= 0; i--) {
        Element* overlay = ElementInspector::GetElementByID(root, overlays[i]);
        if (overlay != nullptr) {
          // OverlayNodeIdForLocation return -1 if (x,y) not in overlay
          id = OverlayNodeIdForLocation(overlay, x, y);
          if (id != -1) {
            break;
          }
        }
      }
    }
    id = id != -1 ? id : NodeIdForLocation(root, x, y);
#else
    // if enable renderkit, we will use renderkit api to get node id.
    // in renderkit, GetNodeForLocation is implemented by hittest.
    // the coordinates should be relative to lynx view rather than window or
    // screen.
    id = ElementInspector::GetNodeForLocation(root, x, y);
#endif
    res["backendNodeId"] = id;
    res["nodeId"] = id;
  }
  return res;
}

Json::Value ElementHelper::GetAttributesAsTextOfNode(Element* ptr,
                                                     const std::string& name) {
  std::string res;
  if (name == "class") {
    for (const auto& c : ElementInspector::ClassOrder(ptr)) {
      res += c.substr(1);
      if (c != ElementInspector::ClassOrder(ptr).back()) {
        res += " ";
      }
    }
  } else if (name == "style") {
    res = ElementInspector::GetInlineStyleSheet(ptr).css_text_;
  } else if (name == "id") {
    res = ElementInspector::SelectorId(ptr);
  } else {
    res = ElementInspector::AttrMap(ptr).at(name);
  }
  return Json::Value(res);
}

Json::Value ElementHelper::GetStyleSheetAsText(
    const InspectorStyleSheet& style_sheet) {
  Json::Value content;
  Json::Value styles(Json::ValueType::objectValue);
  Json::Value range(Json::ValueType::objectValue);
  Json::Value property(Json::ValueType::objectValue);
  styles["styleSheetId"] = style_sheet.style_sheet_id_;
  styles["cssText"] = style_sheet.css_text_;
  range["startLine"] = style_sheet.style_value_range_.start_line_;
  range["startColumn"] = style_sheet.style_value_range_.start_column_;
  range["endLine"] = style_sheet.style_value_range_.end_line_;
  range["endColumn"] = style_sheet.style_value_range_.end_column_;
  styles["range"] = range;
  styles["cssProperties"] = Json::ValueType::arrayValue;
  styles["shorthandEntries"] = Json::ValueType::arrayValue;

  auto css_properties = style_sheet.css_properties_;
  for (auto& item : css_properties) item.second.looped_ = false;
  for (const auto& name : style_sheet.property_order_) {
    auto iter_range = css_properties.equal_range(name);
    for (auto it = iter_range.first; it != iter_range.second; ++it) {
      if (it->second.looped_) continue;
      CSSPropertyDetail& css_property_detail = it->second;
      css_property_detail.looped_ = true;
      property["name"] = css_property_detail.name_;
      property["value"] = css_property_detail.value_;
      if (css_property_detail.disabled_) {
        property.removeMember("implicit");
        property["disabled"] = css_property_detail.disabled_;
      } else {
        property["implicit"] = css_property_detail.implicit_;
        property["disabled"] = css_property_detail.disabled_;
      }
      property["parsedOk"] = css_property_detail.parsed_ok_;
      property["text"] = css_property_detail.text_;
      range["startLine"] = css_property_detail.property_range_.start_line_;
      range["startColumn"] = css_property_detail.property_range_.start_column_;
      range["endLine"] = css_property_detail.property_range_.end_line_;
      range["endColumn"] = css_property_detail.property_range_.end_column_;
      property["range"] = range;
      styles["cssProperties"].append(property);
      break;
    }
  }
  content["styles"] = Json::ValueType::arrayValue;
  content["styles"].append(styles);
  Json::Value msg(Json::ValueType::objectValue);
  return content;
}

Json::Value ElementHelper::GetStyleSheetAsTextOfNode(
    Element* ptr, const std::string& style_sheet_id, const Range& range) {
  Json::Value content;
  if (ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
    auto style_root = ElementInspector::StyleRoot(ptr);
    if (style_root != nullptr) {
      std::unordered_map<std::string, InspectorStyleSheet>& map =
          ElementInspector::GetStyleSheetMap(style_root);
      for (const auto& item : map) {
        const InspectorStyleSheet& cur_style_sheet = item.second;
        if (cur_style_sheet.style_value_range_.start_line_ ==
            range.start_line_) {
          content = GetStyleSheetAsText(cur_style_sheet);
          break;
        }
      }
    }
  } else if (ElementInspector::Type(ptr) == InspectorElementType::DOCUMENT) {
    auto document_root = ptr;
    auto& css_rules = ElementInspector::GetCssRules(document_root);
    for (const auto& css_rule : css_rules) {
      const auto& cur_style_sheet = css_rule.style_;
      if (cur_style_sheet.style_value_range_.start_line_ == range.start_line_) {
        content = GetStyleSheetAsText(cur_style_sheet);
        break;
      }
    }
  } else {
    content = GetStyleSheetAsText(ElementInspector::GetInlineStyleSheet(ptr));
  }
  return content;
}

void ElementHelper::SetInlineStyleTexts(Element* ptr, const std::string& text,
                                        const Range& range) {
  InspectorStyleSheet pre_style_sheet =
      ElementInspector::GetInlineStyleSheet(ptr);
  auto modified_style_sheet = StyleTextParser(ptr, text, pre_style_sheet);
  ElementInspector::SetInlineStyleSheet(ptr, modified_style_sheet);
  ElementInspector::Flush(ptr);
  return;
}

void ElementHelper::SetInlineStyleSheet(
    Element* ptr, const InspectorStyleSheet& style_sheet) {
  ElementInspector::SetInlineStyleSheet(ptr, style_sheet);
  ElementInspector::Flush(ptr);
}

void ElementHelper::SetSelectorStyleTexts(
    std::shared_ptr<DevToolAgentNG> devtool_agent, Element* ptr,
    const std::string& text, const Range& range) {
  if (ptr == nullptr) return;
  auto style_root = ElementInspector::StyleRoot(ptr);
  if (style_root != nullptr) {
    std::unordered_map<std::string, InspectorStyleSheet>& map =
        ElementInspector::GetStyleSheetMap(style_root);
    for (const auto& item : map) {
      const InspectorStyleSheet& cur_style_sheet = item.second;
      if (cur_style_sheet.style_value_range_.start_line_ == range.start_line_) {
        InspectorStyleSheet modified_style_sheet =
            StyleTextParser(ptr, text, cur_style_sheet);
        ElementInspector::SetStyleSheetByName(ptr, item.first,
                                              modified_style_sheet);
        std::vector<Element*> ptr_vec;
        devtool_agent->GetElementPtrMatchingStyleSheet(
            ptr_vec, devtool_agent->GetRoot(), item.first);
        for (auto& temp_ptr : ptr_vec) ElementInspector::Flush(temp_ptr);
        break;
      }
    }
  }
}

void ElementHelper::SetDocumentStyleTexts(
    std::shared_ptr<DevToolAgentNG> devtool_agent, Element* ptr,
    const std::string& text, const Range& range) {
  if (ptr == nullptr) return;
  auto document_root = ptr;
  if (document_root == nullptr) return;
  auto& css_rules = ElementInspector::GetCssRules(document_root);
  for (InspectorCSSRule& css_rule : css_rules) {
    auto& cur_style_sheet = css_rule.style_;
    if (cur_style_sheet.style_value_range_.start_line_ == range.start_line_) {
      InspectorStyleSheet modified_style_sheet =
          StyleTextParser(ptr, text, cur_style_sheet);
      cur_style_sheet = modified_style_sheet;
      std::vector<Element*> ptr_vec;
      devtool_agent->GetElementPtrMatchingStyleSheet(
          ptr_vec, devtool_agent->GetRoot(), cur_style_sheet.style_name_);
      for (auto& temp_ptr : ptr_vec) ElementInspector::Flush(temp_ptr);
      break;
    }
  }
}

void ElementHelper::SetStyleTexts(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  Element* ptr, const std::string& text,
                                  const Range& range) {
  if (ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
    SetSelectorStyleTexts(devtool_agent, ptr, text, range);
  } else if (ElementInspector::Type(ptr) == InspectorElementType::DOCUMENT) {
    SetDocumentStyleTexts(devtool_agent, ptr, text, range);
  } else {
    SetInlineStyleTexts(ptr, text, range);
  }
}

void ElementHelper::SetAttributes(Element* ptr, const std::string& name,
                                  const std::string& text) {
  if (name == "style") {
    SetInlineStyleTexts(ptr, text, Range());
  } else if (name == "class") {
    std::vector<std::string> class_order;
    std::string class_name;
    std::string temp = ".";
    for (const auto& c : text) {
      if (c != ' ') {
        class_name += c;
      } else {
        class_name = temp + class_name;
        class_order.push_back(class_name);
        class_name.clear();
      }
    }
    if (!class_name.empty()) {
      class_name = temp + class_name;
      class_order.push_back(class_name);
      class_name.clear();
    }
    ElementInspector::SetClassOrder(ptr, class_order);
  } else if (name == "id") {
    ElementInspector::SetSelectorId(ptr, "#" + text);
  } else {
    auto attr_map = ElementInspector::AttrMap(ptr);
    auto attr_order = ElementInspector::AttrOrder(ptr);
    if (attr_map.find(name) == attr_map.end()) {
      attr_order.push_back(name);
    }
    attr_map[name] = text;
    ElementInspector::SetAttrOrder(ptr, attr_order);
    ElementInspector::SetAttrMap(ptr, attr_map);
  }
  ElementInspector::Flush(ptr);
}

void ElementHelper::RemoveAttributes(Element* ptr, const std::string& name) {
  if (name == "style") {
    InspectorStyleSheet sheet = ElementInspector::GetInlineStyleSheet(ptr);
    sheet.css_text_.clear();
    sheet.css_properties_.clear();
    sheet.shorthand_entries_.clear();
    sheet.property_order_.clear();
    sheet.style_value_range_ = sheet.style_name_range_;
    ElementInspector::SetInlineStyleSheet(ptr, sheet);
  } else if (name == "class") {
    ElementInspector::SetClassOrder(ptr, std::vector<std::string>());
  } else if (name == "id") {
    ElementInspector::SetSelectorId(ptr, "");
  } else {
    auto attr_map = ElementInspector::AttrMap(ptr);
    auto attr_order = ElementInspector::AttrOrder(ptr);
    if (attr_map.find(name) != attr_map.end()) {
      for (auto iter = attr_order.begin(); iter != attr_order.end(); ++iter) {
        if (*iter == name) {
          attr_order.erase(iter);
          break;
        }
      }
      attr_map.erase(name);
    }
    ElementInspector::SetAttrOrder(ptr, attr_order);
    ElementInspector::SetAttrMap(ptr, attr_map);
  }
  ElementInspector::Flush(ptr);
}

void ElementHelper::SetOuterHTML(Element* manager, int indexId,
                                 std::string html) {}

std::vector<Json::Value> ElementHelper::SetAttributesAsText(Element* ptr,
                                                            std::string name,
                                                            std::string text) {
  std::vector<Json::Value> msg_v;
  Json::Value msg;
  std::string temp;
  size_t i;
  for (i = 0; i < text.size(); ++i) {
    if (text[i] != '=') {
      temp += text[i];
    } else {
      break;
    }
  }
  if (i + 1 < text.size() && text[i + 1] == '"') {
    text = text.substr(i + 2, text.size() - i - 3);
  } else if (i + 1 < text.size()) {
    text = text.substr(i + 1, text.size() - 1);
  }

  if (temp != name) {
    RemoveAttributes(ptr, name);
    msg["method"] = "DOM.attributeRemoved";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    msg["params"]["name"] = name;
    msg_v.push_back(msg);
  }
  SetAttributes(ptr, temp, text);
  msg["method"] = "DOM.attributeModified";
  msg["params"] = Json::Value(Json::ValueType::objectValue);
  msg["params"]["name"] = temp;
  msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
  msg_v.push_back(msg);
  if (name == "style") {
    msg["method"] = "CSS.styleSheetChanged";
    msg["params"] = Json::Value(Json::ValueType::objectValue);
    msg["params"]["styleSheetId"] =
        ElementInspector::GetInlineStyleSheet(ptr).style_sheet_id_;
    msg_v.push_back(msg);
  }
  return msg_v;
}

std::string ElementHelper::GetElementContent(Element* ptr, int num) {
  std::string res = "";
  if (ptr == nullptr) return res;
  std::string temp;
  for (int i = 0; i < num; i++) {
    temp += "\t";
  }
  if (ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
    auto style_ptr = ptr;
    for (const auto& style : ElementInspector::GetStyleSheetOrder(style_ptr)) {
      res +=
          ElementInspector::GetStyleSheetMap(style_ptr).at(style).style_name_;
      res += "{";
      res += ElementInspector::GetStyleSheetMap(style_ptr).at(style).css_text_;
      res += "}";
      res += "\n";
    }
  } else {
    res += temp;
    res += "<" + ElementInspector::LocalName(ptr);
    if (!ElementInspector::ClassOrder(ptr).empty()) {
      res += " class=\"";
      int tmp = 0;
      for (auto cls : ElementInspector::ClassOrder(ptr)) {
        if (tmp != 0) {
          res += " ";
        }
        res += cls.substr(cls.find(".") + 1);
        tmp++;
      }
      res += "\"";
    }
    if (!ElementInspector::SelectorId(ptr).empty()) {
      res += " id=\"" + ElementInspector::SelectorId(ptr) + "\"";
    }
    if (!ElementInspector::GetInlineStyleSheet(ptr).property_order_.empty()) {
      res += " style=\"" +
             ElementInspector::GetInlineStyleSheet(ptr).css_text_ + "\"";
    }
    std::unordered_map<std::string, std::string> attr_map =
        ElementInspector::AttrMap(ptr);
    if (!ElementInspector::AttrOrder(ptr).empty()) {
      for (auto attr : ElementInspector::AttrOrder(ptr)) {
        std::string value = attr_map.find(attr)->second;
        res += " " + attr + "=\"" + value + "\"";
      }
    }
    res += ">\n";
    if (!ptr->GetChild().empty()) {
      for (auto child : ptr->GetChild()) {
        res += GetElementContent(child, num + 1);
      }
    }
    res += temp;
    res += "</" + ElementInspector::LocalName(ptr) + ">\n";
  }
  return res;
}

std::string ElementHelper::GetStyleNodeText(Element* ptr) {
  return ElementInspector::NodeValue(ptr);
}

Json::Value ElementHelper::GetStyleSheetHeader(Element* ptr) {
  Json::Value header(Json::ValueType::objectValue);
  if (ptr == nullptr) return header;
  Element* style_root = ElementInspector::StyleRoot(ptr);
  if (style_root != nullptr) {
    std::unordered_map<std::string, InspectorStyleSheet>& map =
        ElementInspector::GetStyleSheetMap(style_root);
    std::string style_sheet_id =
        std::to_string(ElementInspector::NodeId(style_root));
    header["styleSheetId"] = style_sheet_id;
    header["frameId"] = kDefaultFrameId;
    header["sourceURL"] = kLynxLocalUrl;
    header["origin"] = "regular";
    header["title"] = "";
    header["ownerNode"] = ElementInspector::NodeId(style_root);
    header["disabled"] = false;
    header["isInline"] = true;
    header["isMutable"] = true;
    header["startLine"] = 0;
    header["startColumn"] = 0;
    header["endLine"] = static_cast<int>(map.size() + 2);
    header["endColumn"] = 0;
    int length = 0;
    for (const auto& item : map) {
      length +=
          item.second.style_name_.length() + item.second.css_text_.length() + 4;
    }
    header["length"] = length;
    if (ElementInspector::GetStyleSheetIdSet().find(style_sheet_id) ==
        ElementInspector::GetStyleSheetIdSet().end()) {
      ElementInspector::GetStyleSheetIdSet().insert(style_sheet_id);
    }
  }
  return header;
}

InspectorStyleSheet ElementHelper::GetInlineStyleTexts(Element* ptr) {
  return ElementInspector::GetInlineStyleSheet(ptr);
}

Json::Value ElementHelper::CreateStyleSheet(Element* ptr,
                                            const std::string& frame_id) {
  Json::Value header(Json::ValueType::objectValue);
  header["styleSheetId"] = std::to_string(ElementInspector::NodeId(ptr));
  header["origin"] = "inspector";
  header["frameId"] = frame_id;
  header["sourceURL"] = "";
  header["title"] = "";
  header["ownerNode"] = ElementInspector::NodeId(ptr);
  header["disabled"] = false;
  header["isInline"] = false;
  header["startLine"] = 0;
  header["startColumn"] = 0;
  header["endLine"] = 0;
  header["endColumn"] = 0;
  header["length"] = 0;
  return header;
}

// FIXME(zhengyuwei):this function is used for cdp CSS.addRule
// not clear yet
Json::Value ElementHelper::AddRule(Element* ptr,
                                   const std::string& style_sheet_id,
                                   const std::string& rule_text,
                                   const Range& range) {
  // parse rule text
  bool parse_ok = true;
  std::string temp_text = rule_text;
  std::vector<std::string> parse_result;
  std::vector<std::string> strip_result;
  if (temp_text.length() > 3 &&
      temp_text.substr(temp_text.length() - 3, 3) == " {}") {
    temp_text = temp_text.substr(0, temp_text.length() - 3);
    std::string::size_type next_pos = 0;
    while (std::string::npos != (next_pos = temp_text.find_first_of(","))) {
      auto temp_str = temp_text.substr(0, next_pos);
      parse_result.push_back(temp_str);
      if (next_pos + 1 >= temp_text.length()) break;
      temp_text = temp_text.substr(next_pos + 1);
    }
    if (next_pos + 1 >= temp_text.length()) {
      parse_result.emplace_back();
    } else {
      parse_result.push_back(temp_text.substr(next_pos + 1));
    }
  }
  if (parse_result.empty()) {
    parse_ok = false;
  } else {
    for (auto& str : parse_result) {
      std::string temp_str = StripSpace(str);
      if (temp_str.empty()) {
        parse_ok = false;
        break;
      }
      strip_result.push_back(temp_str);
    }
  }

  Json::Value content(Json::ValueType::objectValue);
  if (parse_ok &&
      ElementInspector::Type(ptr) == InspectorElementType::DOCUMENT) {
    auto document_ptr = ptr;
    auto& css_rules = ElementInspector::GetCssRules(document_ptr);
    int cur_line = static_cast<int>(css_rules.size());
    InspectorCSSRule new_css_rule;
    new_css_rule.origin_ = "inspector";
    new_css_rule.style_sheet_id_ = style_sheet_id;
    InspectorSelectorList& new_select_list = new_css_rule.selector_list_;
    std::string all_text;
    int prev_col = 0;
    Range new_range;
    for (size_t i = 0; i < strip_result.size() - 1; ++i) {
      all_text += strip_result[i] + ", ";
      new_range.start_line_ = cur_line;
      new_range.end_line_ = cur_line;
      new_range.start_column_ = prev_col;
      new_range.end_column_ =
          prev_col + static_cast<int>(strip_result[i].length());
      new_select_list.selectors_order_.emplace_back(strip_result[i]);
      new_select_list.selectors_[strip_result[i]] = new_range;
      prev_col += static_cast<int>(strip_result[i].length()) + 2;
    }
    all_text += strip_result[strip_result.size() - 1];
    new_range.start_line_ = cur_line;
    new_range.end_line_ = cur_line;
    new_range.start_column_ = prev_col;
    new_range.end_column_ =
        prev_col +
        static_cast<int>(strip_result[strip_result.size() - 1].length());
    new_select_list.selectors_order_.emplace_back(
        strip_result[strip_result.size() - 1]);
    new_select_list.selectors_[strip_result[strip_result.size() - 1]] =
        new_range;
    new_select_list.text_ = all_text;

    InspectorStyleSheet& new_style_sheet = new_css_rule.style_;
    new_style_sheet.style_sheet_id_ = style_sheet_id;
    new_range.start_line_ = cur_line;
    new_range.end_line_ = cur_line;
    new_range.start_column_ = 0;
    new_range.end_column_ = prev_col;
    new_style_sheet.style_name_ = all_text;
    new_style_sheet.style_name_range_ = new_range;
    prev_col +=
        static_cast<int>(strip_result[strip_result.size() - 1].length()) + 2;
    new_range.start_line_ = cur_line;
    new_range.end_line_ = cur_line;
    new_range.start_column_ = prev_col;
    new_range.end_column_ = prev_col;
    new_style_sheet.css_text_ = "";
    new_style_sheet.style_value_range_ = new_range;

    Json::Value rule(Json::ValueType::objectValue);
    rule["media"] = Json::ValueType::arrayValue;
    rule["origin"] = new_css_rule.origin_;
    rule["styleSheetId"] = new_css_rule.style_sheet_id_;
    rule["selectorList"] = Json::Value(Json::ValueType::objectValue);
    const InspectorSelectorList& selector_list = new_css_rule.selector_list_;
    rule["selectorList"]["text"] = selector_list.text_;
    rule["selectorList"]["selectors"] =
        Json::Value(Json::ValueType::arrayValue);
    for (const auto& name : selector_list.selectors_order_) {
      Json::Value text(Json::ValueType::objectValue);
      text["text"] = name;
      text["range"]["startLine"] =
          selector_list.selectors_.at(name).start_line_;
      text["range"]["endLine"] = selector_list.selectors_.at(name).end_line_;
      text["range"]["startColumn"] =
          selector_list.selectors_.at(name).start_column_;
      text["range"]["endColumn"] =
          selector_list.selectors_.at(name).end_column_;
      rule["selectorList"]["selectors"].append(text);
    }
    Json::Value style(Json::ValueType::objectValue);
    const InspectorStyleSheet& style_sheet = new_css_rule.style_;
    style["styleSheetId"] = style_sheet.style_sheet_id_;
    style["cssProperties"] = Json::Value(Json::ValueType::arrayValue);
    style["shorthandEntries"] = Json::Value(Json::ValueType::arrayValue);
    style["cssText"] = "";
    style["range"] = Json::ValueType::objectValue;
    style["range"]["startLine"] = style_sheet.style_value_range_.start_line_;
    style["range"]["endLine"] = style_sheet.style_value_range_.end_line_;
    style["range"]["startColumn"] =
        style_sheet.style_value_range_.start_column_;
    style["range"]["endColumn"] = style_sheet.style_value_range_.end_column_;
    rule["style"] = style;
    content["rule"] = rule;
    // add style sheet to node
    css_rules.emplace_back(new_css_rule);
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("SyntaxError Rule text is not valid.");
    content["error"] = error;
  }
  return content;
}

int ElementHelper::QuerySelector(Element* ptr, const std::string& selector) {
  auto element_arr = ElementInspector::SelectElementAll(ptr, selector);
  return !element_arr.empty() ? ElementInspector::NodeId((*element_arr.begin()))
                              : -1;
}

Json::Value ElementHelper::QuerySelectorAll(Element* ptr,
                                            const std::string& selector) {
  Json::Value res(Json::ValueType::arrayValue);
  auto element_arr = ElementInspector::SelectElementAll(ptr, selector);
  for (Element* element : element_arr) {
    res.append(ElementInspector::NodeId(element));
  }
  return res;
}

std::string ElementHelper::GetProperties(Element* ptr) {
  return ptr ? ElementInspector::GetComponentProperties(ptr) : "";
}

std::string ElementHelper::GetData(Element* ptr) {
  return ptr ? ElementInspector::GetComponentData(ptr) : "";
}

int ElementHelper::GetComponentId(Element* ptr) {
  return ptr ? ElementInspector::GetComponentId(ptr) : -1;
}

void ElementHelper::PerformSearchFromNode(Element* ptr, std::string& query,
                                          std::vector<int>& results) {
  bool match = false;
  if (ElementInspector::LocalName(ptr).find(query) != std::string::npos) {
    results.push_back(ElementInspector::NodeId(ptr));
    match = true;
  }
  if (!match && !ElementInspector::ClassOrder(ptr).empty()) {
    for (const auto& className : ElementInspector::ClassOrder(ptr)) {
      if (className.find(query) != std::string::npos) {
        results.push_back(ElementInspector::NodeId(ptr));
        match = true;
        break;
      }
    }
  }
  if (!match && !ElementInspector::AttrMap(ptr).empty()) {
    for (auto iter = ElementInspector::AttrMap(ptr).begin();
         iter != ElementInspector::AttrMap(ptr).end(); ++iter) {
      if (iter->first.find(query) != std::string::npos ||
          iter->second.find(query) != std::string::npos) {
        results.push_back(ElementInspector::NodeId(ptr));
        break;
      }
    }
  }
  if (!ptr->GetChild().empty()) {
    for (const auto& child_ptr : ptr->GetChild()) {
      PerformSearchFromNode(child_ptr, query, results);
    }
  }
}

}  // namespace devtool
}  // namespace lynxdev
