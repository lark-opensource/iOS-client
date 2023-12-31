// Copyright 2022 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_ui_tree_agent.h"

#include <queue>

#include "agent/devtool_agent_ng.h"
#include "element/element_inspector.h"

namespace lynxdev {
namespace devtool {

InspectorUITreeAgent::InspectorUITreeAgent() : enabled_(false) {
  functions_map_["UITree.enable"] = &InspectorUITreeAgent::Enable;
  functions_map_["UITree.disable"] = &InspectorUITreeAgent::Disable;
  functions_map_["UITree.getLynxUITree"] = &InspectorUITreeAgent::GetLynxUITree;
  functions_map_["UITree.getUIInfoForNode"] =
      &InspectorUITreeAgent::GetUIInfoForNode;
  functions_map_["UITree.setUIStyle"] = &InspectorUITreeAgent::SetUIStyle;
  functions_map_["UITree.getUINodeForLocation"] =
      &InspectorUITreeAgent::GetUINodeForLocation;
}

void InspectorUITreeAgent::Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  Json::Value params = message["params"];
  if (params.isMember("useCompression")) {
    use_compression_ = params["useCompression"].asBool();
  }
  if (params.isMember("compressionThreshold")) {
    compression_threshold_ = params["compressionThreshold"].asBool();
  }
  enabled_ = true;

  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorUITreeAgent::Disable(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  enabled_ = false;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorUITreeAgent::GetLynxUITree(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  if (!enabled_) return;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);

  std::string tree_str = devtool_agent->GetLynxUITree();
  Json::Value tree;
  Json::Reader reader;
  if (tree_str.size()) {
    reader.parse(tree_str, tree, false);
  }
  content["root"] = tree;
  content["compress"] = false;

  devtool_agent->SendResponseAsync([devtool_agent, this, content, response,
                                    message]() mutable {
    std::string root_str = content["root"].toStyledString();
    if (this->use_compression_ &&
        root_str.size() > static_cast<size_t>(this->compression_threshold_)) {
      this->CompressData("getLynxUITree", root_str, content, "root");
    }
    response["result"] = content;
    response["id"] = message["id"].asInt64();
    devtool_agent->SendJsonResponse(response);
  });
}

void InspectorUITreeAgent::GetUIInfoForNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  if (!enabled_) return;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int id = static_cast<int>(params["UINodeId"].asInt64());

  std::string info_str = devtool_agent->GetUINodeInfo(id);
  Json::Reader reader;
  if (info_str.size()) {
    reader.parse(info_str, content, false);
  }

  response["id"] = message["id"].asInt64();
  response["result"] = content;

  devtool_agent->SendResponseAsync(response);
}

void InspectorUITreeAgent::SetUIStyle(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  if (!enabled_) return;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int id = static_cast<int>(params["UINodeId"].asInt64());
  std::string style_name = params["styleName"].asString();
  std::string style_content = params["styleContent"].asString();

  int ret = devtool_agent->SetUIStyle(id, style_name, style_content);

  if (ret == -1) {
    Json::Value error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("set ui style fail");
    content["error"] = error;
  }

  response["id"] = message["id"].asInt64();
  response["result"] = content;
  devtool_agent->SendResponseAsync(response);
  return;
}

void InspectorUITreeAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["error"]["id"] = message["id"].asInt64();
    devtool_agent->SendResponse(res.toStyledString());
  } else {
    (this->*(iter->second))(
        std::static_pointer_cast<DevToolAgentNG>(devtool_agent), message);
  }
}

void InspectorUITreeAgent::GetUINodeForLocation(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int x = params["x"].asInt();
  int y = params["y"].asInt();

  Element* root = devtool_agent->GetRoot();
  if (root != nullptr) {
    x = x * ElementInspector::GetDeviceDensity();
    y = y * ElementInspector::GetDeviceDensity();
    int id = 0;

    std::vector<int> overlays = ElementInspector::getVisibleOverlayView(root);
    if (overlays.size() != 0) {
      for (int i = static_cast<int>(overlays.size()) - 1; i >= 0; i--) {
        id = devtool_agent->FindUIIdForLocation(x, y, overlays[i]);
        // x-overlay-ng node' size is window size and it has one and only one
        // child if id == overlays[i], it means point is not in child so not in
        // overlay Under this circumstances,we need reset id to 0
        if (id != overlays[i] && id != 0) {
          break;
        } else {
          id = 0;
        }
      }
    }
    id = id != 0 ? id : devtool_agent->FindUIIdForLocation(x, y, 0);
    content["backendUINodeId"] = id;
  }

  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

}  // namespace devtool
}  // namespace lynxdev
