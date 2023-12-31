// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_css_agent_ng.h"

#include <queue>

#include "agent/devtool_agent_ng.h"
#include "element/element_helper.h"

#if !defined(OS_WIN)
#include <unistd.h>
#endif

namespace lynxdev {
namespace devtool {

InspectorCSSAgentNG::InspectorCSSAgentNG() {
  functions_map_["CSS.enable"] = &InspectorCSSAgentNG::Enable;
  functions_map_["CSS.disable"] = &InspectorCSSAgentNG::Disable;

  functions_map_["CSS.getMatchedStylesForNode"] =
      &InspectorCSSAgentNG::GetMatchedStylesForNode;
  functions_map_["CSS.getComputedStyleForNode"] =
      &InspectorCSSAgentNG::GetComputedStyleForNode;
  functions_map_["CSS.getInlineStylesForNode"] =
      &InspectorCSSAgentNG::GetInlineStylesForNode;
  functions_map_["CSS.setStyleTexts"] = &InspectorCSSAgentNG::SetStyleTexts;
  functions_map_["CSS.getBackgroundColors"] =
      &InspectorCSSAgentNG::GetBackgroundColors;
  functions_map_["CSS.styleSheetChanged"] =
      &InspectorCSSAgentNG::StyleSheetChanged;
  functions_map_["CSS.styleSheetAdded"] = &InspectorCSSAgentNG::StyleSheetAdded;
  functions_map_["CSS.styleSheetRemoved"] =
      &InspectorCSSAgentNG::StyleSheetRemoved;
  functions_map_["CSS.getStyleSheetText"] =
      &InspectorCSSAgentNG::GetStyleSheetText;
  functions_map_["CSS.setStyleSheetText"] =
      &InspectorCSSAgentNG::SetStyleSheetText;
  functions_map_["CSS.createStyleSheet"] =
      &InspectorCSSAgentNG::CreateStyleSheet;
  functions_map_["CSS.addRule"] = &InspectorCSSAgentNG::AddRule;
  functions_map_["CSS.startRuleUsageTracking"] =
      &InspectorCSSAgentNG::StartRuleUsageTracking;
  functions_map_["CSS.updateRuleUsageTracking"] =
      &InspectorCSSAgentNG::UpdateRuleUsageTracking;
  functions_map_["CSS.stopRuleUsageTracking"] =
      &InspectorCSSAgentNG::StopRuleUsageTracking;
}

InspectorCSSAgentNG::~InspectorCSSAgentNG() = default;

void InspectorCSSAgentNG::CreateStyleSheet(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string frame_id = params["frameId"].asString();
  auto* ptr = devtool_agent->GetRoot();
  Json::Value header = ElementHelper::CreateStyleSheet(ptr, frame_id);
  content["styleSheetId"] = header["styleSheetId"];
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  // send styleSheetAdded event
  Json::Value msg(Json::ValueType::objectValue);
  msg["method"] = "CSS.styleSheetAdded";
  msg["params"] = Json::Value(Json::ValueType::objectValue);
  msg["params"]["header"] = header;
  devtool_agent->DispatchJsonMessage(msg);
}

void InspectorCSSAgentNG::AddRule(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string style_sheet_id = params["styleSheetId"].asString();
  std::string rule_text = params["ruleText"].asString();
  Range range;
  range.start_line_ = params["location"]["startLine"].asInt();
  range.start_column_ = params["location"]["startColumn"].asInt();
  range.end_line_ = params["location"]["endLine"].asInt();
  range.end_column_ = params["location"]["endColumn"].asInt();
  auto index =
      atoi(style_sheet_id.substr(style_sheet_id.find('.') + 1).c_str());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  response["result"] =
      ElementHelper::AddRule(ptr, style_sheet_id, rule_text, range);

  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::SetStyleSheetText(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string style_sheet_id = params["styleSheetId"].asString();
  content["sourceMapURL"] = "";
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                 const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  std::vector<Element*> style_values;
  devtool_agent->GetElementByType(InspectorElementType::STYLEVALUE,
                                  style_values, devtool_agent->GetRoot());
  for (auto* ptr : style_values) {
    if (ptr != nullptr &&
        ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "CSS.styleSheetAdded";
      msg["params"] = Json::Value(Json::ValueType::objectValue);
      msg["params"]["header"] = ElementHelper::GetStyleSheetHeader(ptr);
      devtool_agent->DispatchJsonMessage(msg);
    }
  }
}

void InspectorCSSAgentNG::Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::GetMatchedStylesForNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content = ElementHelper::GetMatchedStylesForNode(ptr);
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Node is not an Element");
    content["error"] = error;
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::GetComputedStyleForNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content["computedStyle"] = ElementHelper::GetComputedStyleOfNode(ptr);
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::GetInlineStylesForNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content["inlineStyle"] = ElementHelper::GetInlineStyleOfNode(ptr);
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::SetStyleTexts(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  auto edits = params.get("edits", Json::Value(Json::ValueType::arrayValue));
  for (const auto& edit : edits) {
    std::string style_sheet_id = edit["styleSheetId"].asString();
    auto index =
        atoi(style_sheet_id.substr(style_sheet_id.find('.') + 1).c_str());
    auto range_json =
        edit.get("range", Json::Value(Json::ValueType::objectValue));
    Range range;
    range.start_line_ = range_json["startLine"].asInt();
    range.start_column_ = range_json["startColumn"].asInt();
    range.end_line_ = range_json["endLine"].asInt();
    range.end_column_ = range_json["endColumn"].asInt();
    std::string text = edit["text"].asString();
    auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
    if (ptr != nullptr) {
      ElementHelper::SetStyleTexts(devtool_agent, ptr, text, range);
      content =
          ElementHelper::GetStyleSheetAsTextOfNode(ptr, style_sheet_id, range);
      std::string res = content.toStyledString();
      DispatchMessage(devtool_agent, ptr, style_sheet_id);
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::GetStyleSheetText(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string style_sheet_id = params["styleSheetId"].asString();
  int index = atoi(style_sheet_id.substr(style_sheet_id.find('.') + 1).c_str());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content = ElementHelper::GetStyleSheetText(ptr, style_sheet_id);
  } else {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Node is not an Element");
    content["error"] = error;
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::GetBackgroundColors(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content = ElementHelper::GetBackGroundColorsOfNode(ptr);
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::StyleSheetChanged(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value res(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  res["styleSheetId"] = params["styleSheetId"];
  content["method"] = "CSS.styleSheetChanged";
  content["params"] = res;
  devtool_agent->SendResponseAsync(content);
}

void InspectorCSSAgentNG::StyleSheetAdded(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value params = message["params"];
  if (params["all"] == Json::Value::nullSingleton()) {
    Json::Value msg(Json::ValueType::objectValue);
    msg["method"] = "CSS.styleSheetAdded";
    msg["params"] = Json::Value(Json::ValueType::objectValue);
    msg["params"]["header"] = params["header"];
    devtool_agent->SendResponseAsync(msg);
  } else {
    std::vector<Element*> style_values;
    devtool_agent->GetElementByType(InspectorElementType::STYLEVALUE,
                                    style_values, devtool_agent->GetRoot());
    for (auto ptr : style_values) {
      if (ptr != nullptr &&
          ElementInspector::Type(ptr) == InspectorElementType::STYLEVALUE) {
        Json::Value msg(Json::ValueType::objectValue);
        msg["method"] = "CSS.styleSheetAdded";
        msg["params"] = Json::Value(Json::ValueType::objectValue);
        msg["params"]["header"] = ElementHelper::GetStyleSheetHeader(ptr);
        devtool_agent->DispatchJsonMessage(msg);
      }
    }
  }
}

void InspectorCSSAgentNG::StyleSheetRemoved(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value res(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  res["styleSheetId"] = params["styleSheetId"];
  content["method"] = "CSS.styleSheetRemoved";
  content["params"] = res;
  devtool_agent->SendResponseAsync(content);
}

void InspectorCSSAgentNG::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(
        std::static_pointer_cast<DevToolAgentNG>(devtool_agent), message);
  }
}

void InspectorCSSAgentNG::DispatchMessage(
    std::shared_ptr<DevToolAgentNG> devtool_agent, Element* ptr,
    const std::string& sheet_id) {
  Json::Value msg(Json::ValueType::objectValue);
  if (ElementInspector::Type(ptr) != InspectorElementType::STYLEVALUE ||
      ElementInspector::Type(ptr) != InspectorElementType::DOCUMENT) {
    msg["method"] = "DOM.attributeModified";
    msg["params"] = Json::Value(Json::ValueType::objectValue);
    msg["params"]["name"] = "style";
    int nodeid = atoi(sheet_id.substr(sheet_id.find('.') + 1).c_str());
    msg["params"]["nodeId"] = nodeid;
    devtool_agent->DispatchJsonMessage(msg);
  }
  msg["method"] = "CSS.styleSheetChanged";
  msg["params"] = Json::Value(Json::ValueType::objectValue);
  msg["params"]["styleSheetId"] = sheet_id;
  devtool_agent->DispatchJsonMessage(msg);
}

void InspectorCSSAgentNG::StartRuleUsageTracking(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  rule_usage_tracking_ = true;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorCSSAgentNG::UpdateRuleUsageTracking(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  if (rule_usage_tracking_) {
    Json::Value selectors(Json::ValueType::arrayValue);
    selectors = message["params"]["selector"];
    for (const auto& selector : selectors) {
      css_used_selector_.insert(selector.asString());
    }
  }
}

void InspectorCSSAgentNG::StopRuleUsageTracking(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value res(Json::ValueType::objectValue);
  Json::Value rule_usage(Json::ValueType::arrayValue);

  std::vector<Element*> elements;
  devtool_agent->GetElementByType(InspectorElementType::STYLEVALUE, elements,
                                  devtool_agent->GetRoot());
  auto ptr = elements.empty() ? devtool_agent->GetRoot() : elements[0];
  std::string style_sheet_id = std::to_string(ElementInspector::NodeId(ptr));

  std::string content;
  auto element_ptr = devtool_agent->GetElementById(
      devtool_agent->GetRoot(), ElementInspector::NodeId(ptr));
  if (element_ptr != nullptr) {
    content =
        ElementHelper::GetStyleSheetText(element_ptr, style_sheet_id)["text"]
            .asString();
  }

  if (css_used_selector_.empty()) {
    CollectDomTreeCssUsage(devtool_agent, rule_usage, style_sheet_id, content);
  } else {
    for (const auto& selector : css_used_selector_) {
      if (!selector.empty()) {
        rule_usage.append(GetUsageItem(style_sheet_id, content, selector));
      }
    }
  }

  res["ruleUsage"] = rule_usage;
  response["result"] = res;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);

  css_used_selector_.clear();
  rule_usage_tracking_ = false;
}

void InspectorCSSAgentNG::CollectDomTreeCssUsage(
    const std::shared_ptr<DevToolAgentNG>& devtool_agent,
    Json::Value& rule_usage_array, const std::string& stylesheet_id,
    const std::string& content) {
  auto* root = devtool_agent->GetRoot();
  std::queue<Element*> inspect_node_queue;
  inspect_node_queue.push(root);
  while (!inspect_node_queue.empty()) {
    auto* element = inspect_node_queue.front();
    inspect_node_queue.pop();
    for (const auto& child : element->GetChild()) {
      inspect_node_queue.push(child);
    }
    if (ElementInspector::Type(element) == InspectorElementType::DOCUMENT) {
      continue;
    }

    std::string select_id = ElementInspector::SelectorId(element);
    if (!select_id.empty()) {
      rule_usage_array.append(GetUsageItem(stylesheet_id, content, select_id));
    }

    std::vector<std::string> class_order =
        ElementInspector::ClassOrder(element);
    for (auto& order : class_order) {
      if (!order.empty()) {
        rule_usage_array.append(GetUsageItem(stylesheet_id, content, order));
      }
    }
  }
}

Json::Value InspectorCSSAgentNG::GetUsageItem(const std::string& stylesheet_id,
                                              const std::string& content,
                                              const std::string& selector) {
  Json::Value usage_item(Json::ValueType::objectValue);
  usage_item["styleSheetId"] = stylesheet_id;

  // find the start index and end index of the selector in 'content'
  auto start_offset =
      content.find(selector + lynxdev::devtool::kPaddingCurlyBrackets);
  usage_item["startOffset"] = static_cast<Json::Int64>(start_offset);
  usage_item["endOffset"] =
      static_cast<Json::Int64>(content.find('\n', start_offset)) + 1;
  usage_item["used"] = true;
  return usage_item;
}

}  // namespace devtool
}  // namespace lynxdev
