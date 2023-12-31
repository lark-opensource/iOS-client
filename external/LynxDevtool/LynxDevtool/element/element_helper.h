// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_HELPER_ELEMENT_HELPER_H_
#define LYNX_INSPECTOR_HELPER_ELEMENT_HELPER_H_

#include <memory>
#include <set>

#include "element_inspector.h"
#include "inspector/style_sheet.h"
#include "tasm/react/element.h"
#include "third_party/jsoncpp/include/json/json.h"

using lynx::tasm::Element;

namespace lynxdev {
namespace devtool {

// The following constants are obtained from chromium
// kDefaultFrameId、kDefaultLoaderId is calculated by hash value in chromium and
// the calculation process is not clear yet
static const char* kDefaultFrameId = "18D8BD1EDE86A29BECB29184EA054C2B";
static const char* kDefaultLoaderId = "D3E1D3CC0F9B78E8E6E29A0C568F3532";
static const char* kLynxLocalUrl = "file:///Lynx.html";
static const char* kLynxSecurityOrigin = "file://Lynx";
static const char* kLynxMimeType = "text/html";

static constexpr const char* kPaddingCurlyBrackets = " {";

class DevToolAgentNG;

class ElementHelper {
 public:
  static Element* GetPreviousNode(Element* ptr);
  static bool PointInNode(Element* ptr, int x, int y);

  static int XViewPagerProNodeIdForLocation(Element* ptr, int x, int y);
  static int SwiperNodeIdForLocation(Element* ptr, int x, int y);
  static int CommonNodeIdForLocation(Element* ptr, int x, int y);
  static int NodeIdForLocation(Element* ptr, int x, int y);
  static int OverlayNodeIdForLocation(Element* ptr, int x, int y);

  static Json::Value GetDocumentBodyFromNode(Element* ptr, bool plug,
                                             bool with_box_model = false);
  static void SetJsonValueOfNode(Element* ptr, Json::Value& value,
                                 bool with_box_model = false);
  static Json::Value GetMatchedStylesForNode(Element* ptr);
  static Json::Value GetKeyframesRulesForNode(Element* ptr);
  static std::pair<bool, Json::Value> GetKeyframesRule(const std::string& name,
                                                       Element* ptr);
  static void FillKeyFramesRule(
      Element* ptr,
      const std::unordered_multimap<std::string, CSSPropertyDetail>&
          css_property,
      Json::Value& content, std::set<std::string>& animation_name_set,
      const std::string& key);
  static void FillKeyFramesRuleByStyleSheet(
      Element* ptr, const InspectorStyleSheet& style_sheet,
      Json::Value& content, std::set<std::string>& animation_name_set);
  static Json::Value GetInlineStyleOfNode(Element* ptr);
  static Json::Value GetBackGroundColorsOfNode(Element* ptr);
  static Json::Value GetComputedStyleOfNode(Element* ptr);
  static Json::Value GetMatchedCSSRulesOfNode(Element* ptr);
  static void ApplyCascadeStyles(Element* ptr, Json::Value& result,
                                 const std::string& rule);
  static void ApplyPseudoCascadeStyles(Element* ptr, Json::Value& result,
                                       const std::string& rule);
  static std::string GetPseudoChildNameForStyle(
      const std::string& rule, const std::string& pseudo_child);
  static void ApplyPseudoChildStyle(Element* ptr, Json::Value& result,
                                    const std::string& rule);
  static Json::Value GetInheritedCSSRulesOfNode(Element* ptr);
  static Json::Value GetBoxModelOfNode(Element* ptr,
                                       double screen_scale_factor = 1);
  static Json::Value GetNodeForLocation(Element* ptr, int x, int y);
  static Json::Value GetAttributesAsTextOfNode(Element* ptr,
                                               const std::string& name);
  static Json::Value GetStyleSheetAsText(
      const InspectorStyleSheet& style_sheet);
  static Json::Value GetStyleSheetAsTextOfNode(
      Element* ptr, const std::string& style_sheet_id, const Range& range);
  static Json::Value GetStyleSheetText(Element* ptr,
                                       const std::string& style_sheet_id);

  static void SetInlineStyleTexts(Element* ptr, const std::string& text,
                                  const Range& range);
  static void SetInlineStyleSheet(Element* ptr,
                                  const InspectorStyleSheet& style_sheet);
  static void SetSelectorStyleTexts(
      std::shared_ptr<DevToolAgentNG> devtool_agent, Element* ptr,
      const std::string& text, const Range& range);
  static void SetDocumentStyleTexts(
      std::shared_ptr<DevToolAgentNG> devtool_agent, Element* ptr,
      const std::string& text, const Range& range);
  static void SetStyleTexts(std::shared_ptr<DevToolAgentNG> devtool_agent,
                            Element* ptr, const std::string& text,
                            const Range& range);
  static void SetAttributes(Element* ptr, const std::string& name,
                            const std::string& text);
  static void RemoveAttributes(Element* ptr, const std::string& name);
  static void SetOuterHTML(Element* manager, int indexId, std::string html);

  static std::vector<Json::Value> SetAttributesAsText(Element* ptr,
                                                      std::string name,
                                                      std::string text);
  static std::string GetElementContent(Element* ptr, int num);
  static std::string GetStyleNodeText(Element* ptr);
  static Json::Value GetStyleSheetHeader(Element* ptr);
  static Json::Value CreateStyleSheet(Element* ptr,
                                      const std::string& frame_id);
  static InspectorStyleSheet GetInlineStyleTexts(Element* ptr);
  static Json::Value AddRule(Element* ptr, const std::string& style_sheet_id,
                             const std::string& rule_text, const Range& range);
  static int QuerySelector(Element* ptr, const std::string& selector);
  static Json::Value QuerySelectorAll(Element* ptr,
                                      const std::string& selector);
  static std::string GetProperties(Element* ptr);
  static std::string GetData(Element* ptr);
  static int GetComponentId(Element* ptr);
  static void PerformSearchFromNode(Element* ptr, std::string& query,
                                    std::vector<int>& results);
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_HELPER_INSPECTOR_ELEMENT_HELPER_H_
