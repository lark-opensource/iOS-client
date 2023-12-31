// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_overlay_agent_ng.h"

#include "agent/devtool_agent_ng.h"
#include "css/css_decoder.h"
#include "element/element_helper.h"

namespace lynxdev {
namespace devtool {

InspectorOverlayAgentNG::InspectorOverlayAgentNG() {
  functions_map_["Overlay.highlightNode"] =
      &InspectorOverlayAgentNG::HighlightNode;
  functions_map_["Overlay.hideHighlight"] =
      &InspectorOverlayAgentNG::HideHighlight;
}

void InspectorOverlayAgentNG::HighlightNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  if (!params.isNull()) {
    auto node_id = static_cast<size_t>(params["nodeId"].asInt64());
    auto highlight_config = params["highlightConfig"];
    auto selector = params["selector"].asString();
    auto* current_node =
        devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
    if (current_node == nullptr ||
        !ElementInspector::HasDataModel(current_node) ||
        ElementInspector::IsNeedEraseId(current_node)) {
      Json::Value error = Json::Value(Json::ValueType::objectValue);
      error["code"] = Json::Value(-32000);
      error["message"] = Json::Value("Node is not an Element");
      content["error"] = error;
    } else {
      if (node_id != origin_node_id_) {
        RestoreOriginNodeInlineStyle(devtool_agent);
        origin_inline_style_ = ElementHelper::GetInlineStyleTexts(current_node);
        origin_node_id_ = node_id;
        auto json_content_color = highlight_config["contentColor"];
        std::stringstream inlineStyle;
        inlineStyle << "background-color:"
                    << lynx::tasm::CSSDecoder::ToRgbaFromRgbaValue(
                           json_content_color["r"].asString(),
                           json_content_color["g"].asString(),
                           json_content_color["b"].asString(),
                           json_content_color["a"].asString());
        ElementHelper::SetInlineStyleTexts(current_node, inlineStyle.str(),
                                           Range());
      }
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorOverlayAgentNG::HideHighlight(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  RestoreOriginNodeInlineStyle(devtool_agent);
}

void InspectorOverlayAgentNG::RestoreOriginNodeInlineStyle(
    std::shared_ptr<DevToolAgentNG> devtool_agent) {
  if (origin_node_id_ == 0) return;
  Element* origin_node =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), origin_node_id_);
  if (origin_node != nullptr) {
    ElementHelper::SetInlineStyleSheet(origin_node, origin_inline_style_);
  }
}

void InspectorOverlayAgentNG::CallMethod(
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

}  // namespace devtool
}  // namespace lynxdev
