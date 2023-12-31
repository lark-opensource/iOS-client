// Copyright 2022 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_layer_tree_agent_ng.h"

#include <queue>

#include "agent/devtool_agent_ng.h"
#include "element/element_inspector.h"

namespace lynxdev {
namespace devtool {

InspectorLayerTreeAgentNG::InspectorLayerTreeAgentNG() : enabled_(false) {
  functions_map_["LayerTree.enable"] = &InspectorLayerTreeAgentNG::Enable;
  functions_map_["LayerTree.layerTreeDidChange"] =
      &InspectorLayerTreeAgentNG::LayerTreeDidChange;
  functions_map_["LayerTree.layerPainted"] =
      &InspectorLayerTreeAgentNG::LayerPainted;
  functions_map_["LayerTree.disable"] = &InspectorLayerTreeAgentNG::Disable;
  functions_map_["LayerTree.compositingReasons"] =
      &InspectorLayerTreeAgentNG::CompositingReasons;
}

void InspectorLayerTreeAgentNG::Enable(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
  enabled_ = true;
  LayerPainted(devtool_agent, message);
  LayerTreeDidChange(devtool_agent, message);
}

void InspectorLayerTreeAgentNG::Disable(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  enabled_ = false;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  devtool_agent->SendResponse(content.toStyledString());
}

void InspectorLayerTreeAgentNG::LayerTreeDidChange(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  if (enabled_) {
    Json::Value response(Json::ValueType::objectValue);
    response["method"] = "LayerTree.layerTreeDidChange";
    Json::Value layers(Json::ValueType::arrayValue);
    lynx::tasm::Element* element = devtool_agent->GetRoot();
    if (element) {
      layers = BuildLayerTreeFromElement(element);
    }
    response["params"]["layers"] = layers;
    devtool_agent->SendResponse(response.toStyledString());
  }
}

void InspectorLayerTreeAgentNG::LayerPainted(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value layerId(Json::ValueType::stringValue);
  Json::Value clip(Json::ValueType::objectValue);
  lynx::tasm::Element* element = devtool_agent->GetRoot();
  if (element != nullptr) {
    Json::Value rootLayer = GetLayerContentFromElement(element);
    clip["x"] = rootLayer["offsetX"];
    clip["y"] = rootLayer["offsetY"];
    clip["width"] = rootLayer["width"];
    clip["height"] = rootLayer["height"];
    layerId = rootLayer["layerId"].asString();
  }
  response["method"] = "LayerTree.layerPrinted";
  response["params"]["layerId"] = layerId;
  response["params"]["clip"] = clip;
  devtool_agent->SendResponse(response.toStyledString());
}

void InspectorLayerTreeAgentNG::CompositingReasons(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value compositingReasons(Json::ValueType::arrayValue);
  Json::Value compositingReasonsIds(Json::ValueType::arrayValue);
  Json::Value params = message["params"];
  int layerId = std::stoi(params["layerId"].asString());
  lynx::tasm::Element* element =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), layerId);
  if (element) {
    compositingReasons.append(ElementInspector::LocalName(element));
    compositingReasonsIds.append(ElementInspector::NodeId(element));
  }
  content["compositingReasons"] = compositingReasons;
  content["compositingReasonsIds"] = compositingReasonsIds;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
}

Json::Value InspectorLayerTreeAgentNG::GetLayerContentFromElement(
    lynx::tasm::Element* element) {
  Json::Value layer(Json::ValueType::objectValue);
  if (element) {
    layer["layerId"] = std::to_string(ElementInspector::NodeId(element));
    layer["backendNodeId"] = ElementInspector::NodeId(element);
    if (element->parent()) {
      layer["parentLayerId"] =
          std::to_string(ElementInspector::NodeId(element->parent()));
    }
    layer["paintCount"] = 1;
    layer["drawsContent"] = true;
    layer["invisible"] = true;
    layer["name"] = ElementInspector::LocalName(element);
    Json::Value layout = GetLayoutInfoFromElement(element);
    layer["offsetX"] = layout["offsetX"];
    layer["offsetY"] = layout["offsetY"];
    layer["width"] = layout["width"];
    layer["height"] = layout["height"];
  }
  return layer;
}

Json::Value InspectorLayerTreeAgentNG::GetLayoutInfoFromElement(
    lynx::tasm::Element* element) {
  Json::Value layout(Json::ValueType::objectValue);
  if (element) {
    std::vector<double> box_model = ElementInspector::GetBoxModel(element);
    if (!box_model.empty()) {
      layout["width"] = box_model[28] - box_model[26];
      layout["height"] = box_model[31] - box_model[29];
      if (element->parent() == nullptr) {
        layout["offsetX"] = box_model[26];
        layout["offsetY"] = box_model[27];
      } else {
        std::vector<double> parent_box_model =
            ElementInspector::GetBoxModel(element->parent());
        if (parent_box_model.empty()) {
          layout["offsetX"] = box_model[26];
          layout["offsetY"] = box_model[27];
        } else {
          layout["offsetX"] = box_model[26] - parent_box_model[26];
          layout["offsetY"] = box_model[27] - parent_box_model[27];
        }
      }
    }
  }
  return layout;
}

Json::Value InspectorLayerTreeAgentNG::BuildLayerTreeFromElement(
    lynx::tasm::Element* root_element) {
  Json::Value layers(Json::ValueType::arrayValue);
  if (root_element) {
    std::queue<lynx::tasm::Element*> element_queue;
    element_queue.push(root_element);
    while (!element_queue.empty()) {
      lynx::tasm::Element* element = element_queue.front();
      element_queue.pop();
      Json::Value layer = GetLayerContentFromElement(element);
      layers.append(layer);
      for (auto& child : element->GetChild()) {
        element_queue.push(child);
      }
    }
  }
  return layers;
}

void InspectorLayerTreeAgentNG::CallMethod(
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
}  // namespace devtool
}  // namespace lynxdev
