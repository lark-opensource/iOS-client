// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_dom_agent_ng.h"

#include "agent/devtool_agent_ng.h"
#include "base/lynx_env.h"
#include "element/element_helper.h"

namespace lynxdev {
namespace devtool {

InspectorDOMAgentNG::InspectorDOMAgentNG() {
  functions_map_["DOM.enable"] = &InspectorDOMAgentNG::Enable;
  functions_map_["DOM.disable"] = &InspectorDOMAgentNG::Disable;
  functions_map_["DOM.enableDomTree"] = &InspectorDOMAgentNG::EnableDomTree;
  functions_map_["DOM.disableDomTree"] = &InspectorDOMAgentNG::DisableDomTree;
  functions_map_["DOM.getDocument"] = &InspectorDOMAgentNG::GetDocument;
  functions_map_["DOM.getDocumentWithBoxModel"] =
      &InspectorDOMAgentNG::GetDocumentWithBoxModel;
  functions_map_["DOM.requestChildNodes"] =
      &InspectorDOMAgentNG::RequestChildNodes;
  functions_map_["DOM.getBoxModel"] = &InspectorDOMAgentNG::GetBoxModel;
  functions_map_["DOM.setAttributesAsText"] =
      &InspectorDOMAgentNG::SetAttributesAsText;
  functions_map_["DOM.attributeModified"] =
      &InspectorDOMAgentNG::AttributeModified;
  functions_map_["DOM.markUndoableState"] =
      &InspectorDOMAgentNG::MarkUndoableState;
  functions_map_["DOM.characterDataModified"] =
      &InspectorDOMAgentNG::CharacterDataModified;
  functions_map_["DOM.documentUpdated"] = &InspectorDOMAgentNG::DocumentUpdated;
  functions_map_["DOM.attributeRemoved"] =
      &InspectorDOMAgentNG::AttributeRemoved;
  functions_map_["DOM.childNodeRemoved"] =
      &InspectorDOMAgentNG::ChildNodeRemoved;
  functions_map_["DOM.childNodeInserted"] =
      &InspectorDOMAgentNG::ChildNodeInserted;
  functions_map_["DOM.getNodeForLocation"] =
      &InspectorDOMAgentNG::GetNodeForLocation;
  functions_map_["DOM.pushNodesByBackendIdsToFrontend"] =
      &InspectorDOMAgentNG::PushNodesByBackendIdsToFrontend;
  functions_map_["DOM.removeNode"] = &InspectorDOMAgentNG::RemoveNode;
  functions_map_["DOM.moveTo"] = &InspectorDOMAgentNG::MoveTo;
  functions_map_["DOM.copyTo"] = &InspectorDOMAgentNG::CopyTo;
  functions_map_["DOM.getOuterHTML"] = &InspectorDOMAgentNG::GetOuterHTML;
  functions_map_["DOM.setOuterHTML"] = &InspectorDOMAgentNG::SetOuterHTML;
  functions_map_["DOM.setInspectedNode"] =
      &InspectorDOMAgentNG::SetInspectedNode;
  functions_map_["DOM.querySelector"] = &InspectorDOMAgentNG::QuerySelector;
  functions_map_["DOM.querySelectorAll"] =
      &InspectorDOMAgentNG::QuerySelectorAll;
  functions_map_["DOM.innerText"] = &InspectorDOMAgentNG::InnerText;
  functions_map_["DOM.getAttributes"] = &InspectorDOMAgentNG::GetAttributes;
  functions_map_["DOM.performSearch"] = &InspectorDOMAgentNG::PerformSearch;
  functions_map_["DOM.getSearchResults"] =
      &InspectorDOMAgentNG::GetSearchResults;
  functions_map_["DOM.discardSearchResults"] =
      &InspectorDOMAgentNG::DiscardSearchResults;
  functions_map_["DOM.scrollIntoViewIfNeeded"] =
      &InspectorDOMAgentNG::ScrollIntoViewIfNeeded;
}

InspectorDOMAgentNG::~InspectorDOMAgentNG() = default;

void InspectorDOMAgentNG::QuerySelector(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string selector = params["selector"].asString();
  Element* start_node;
  if (params.isMember("nodeId")) {
    size_t node_id = static_cast<size_t>(params["nodeId"].asInt64());
    start_node =
        devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
  } else {
    start_node = devtool_agent->GetRoot();
  }
  content["nodeId"] =
      start_node ? ElementHelper::QuerySelector(start_node, selector) : -1;

  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::GetAttributes(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t node_id = static_cast<size_t>(params["nodeId"].asInt64());
  content["attributes"] = GetAttributesImpl(devtool_agent, node_id);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

Json::Value InspectorDOMAgentNG::GetAttributesImpl(
    std::shared_ptr<DevToolAgentNG> devtool_agent, size_t node_id) {
  Json::Value attrs_array(Json::ValueType::arrayValue);
  auto element =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
  if (element) {
    for (auto& attr_name : ElementInspector::AttrOrder(element)) {
      attrs_array.append(Json::Value(attr_name.c_str()));
      attrs_array.append(
          Json::Value(ElementInspector::AttrMap(element).at(attr_name)));
    }
    if (!ElementInspector::ClassOrder(element).empty()) {
      attrs_array.append(Json::Value("class"));
      attrs_array.append(
          ElementHelper::GetAttributesAsTextOfNode(element, "class"));
    }
    if (!ElementInspector::GetInlineStyleSheet(element).css_text_.empty()) {
      attrs_array.append(Json::Value("style"));
      attrs_array.append(
          ElementHelper::GetAttributesAsTextOfNode(element, "style"));
    }
  }
  return attrs_array;
}

void InspectorDOMAgentNG::InnerText(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t nodeId = static_cast<size_t>(params["nodeId"].asInt64());
  auto element =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), nodeId);
  Json::Value raw_text_value_array(Json::ValueType::arrayValue);
  // find all raw-text on text element
  if (element && !ElementInspector::LocalName(element).compare("text")) {
    for (auto& raw_text_child : element->GetChild()) {
      if (ElementInspector::LocalName(raw_text_child).compare("raw-text")) {
        continue;
      }
      auto itr = ElementInspector::AttrMap(raw_text_child).find("text");
      if (itr != ElementInspector::AttrMap(element).end()) {
        Json::Value attr_text_value(Json::ValueType::objectValue);
        attr_text_value["nodeId"] = ElementInspector::NodeId(raw_text_child);
        attr_text_value["text"] = itr->second;
        raw_text_value_array.append(attr_text_value);
      }
    }
  }
  content["nodeId"] = static_cast<int>(nodeId);
  content["rawTextValues"] = raw_text_value_array;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::QuerySelectorAll(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string selector = params["selector"].asString();
  Element* start_node;
  if (params.isMember("nodeId")) {
    size_t node_id = static_cast<size_t>(params["nodeId"].asInt64());
    start_node =
        devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
  } else {
    start_node = devtool_agent->GetRoot();
  }
  content["nodeIds"] =
      start_node ? ElementHelper::QuerySelectorAll(start_node, selector)
                 : Json::Value(Json::ValueType::arrayValue);

  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                 const Json::Value& message) {
  Json::Value params = message["params"];
  if (params.isMember("useCompression")) {
    use_compression_ = params["useCompression"].asBool();
  }
  if (params.isMember("compressionThreshold")) {
    compression_threshold_ = params["compressionThreshold"].asBool();
  }

  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::EnableDomTree(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  devtool_agent->SetLynxEnv(lynx::base::LynxEnv::kLynxEnableDomTree, true);
  Json::Value params = message["params"];
  bool ignore_cache = false;
  if (!params.empty()) {
    ignore_cache = params["ignoreCache"].asBool();
  }
  devtool_agent->PageReload(ignore_cache);
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::DisableDomTree(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  devtool_agent->SetLynxEnv(lynx::base::LynxEnv::kLynxEnableDomTree, false);
  Json::Value params = message["params"];
  bool ignore_cache = false;
  if (!params.empty()) {
    ignore_cache = params["ignoreCache"].asBool();
  }
  devtool_agent->PageReload(ignore_cache);
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::GetDocument(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  auto* root = devtool_agent->GetRoot();
  if (root == nullptr) {
    response["result"] = content;
    response["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(response);
    return;
  }

  content["root"] = ElementHelper::GetDocumentBodyFromNode(root, false);
  content["compress"] = false;

  devtool_agent->SendResponseAsync([devtool_agent, this, content, response,
                                    message]() mutable {
    std::string root_str = content["root"].toStyledString();
    if (this->use_compression_ &&
        root_str.size() > static_cast<size_t>(this->compression_threshold_)) {
      this->CompressData("getDocument", root_str, content, "root");
    }
    response["result"] = content;
    response["id"] = message["id"].asInt64();
    devtool_agent->SendJsonResponse(response);
  });
}

void InspectorDOMAgentNG::GetDocumentWithBoxModel(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  auto* root = devtool_agent->GetRoot();
  if (root == nullptr) {
    return;
  }

  content["root"] = ElementHelper::GetDocumentBodyFromNode(root, false, true);
  content["compress"] = false;

  devtool_agent->SendResponseAsync([devtool_agent, this, content, response,
                                    message]() mutable {
    std::string root_str = content["root"].toStyledString();
    if (this->use_compression_ &&
        root_str.size() > static_cast<size_t>(this->compression_threshold_)) {
      this->CompressData("getDocumentWithBoxModel", root_str, content, "root");
    }
    response["result"] = content;
    response["id"] = message["id"].asInt64();
    devtool_agent->SendJsonResponse(response);
  });
}

void InspectorDOMAgentNG::RequestChildNodes(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int node_id = params["nodeId"].asInt();
  [[maybe_unused]] int depth = 1;
  if (params.isMember("depth")) {
    depth = params["depth"].asInt();
  }
  Json::Value nodes(Json::ValueType::arrayValue);
  auto cur_node =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
  if (cur_node != nullptr) {
    for (auto& child : cur_node->GetChild()) {
      Json::Value node_info(Json::ValueType::objectValue);
      node_info["parentId"] = ElementInspector::NodeId(child->parent());
      node_info["backendNodeId"] = 0;
      node_info["childNodeCount"] = static_cast<int>(child->GetChild().size());
      node_info["localName"] = ElementInspector::LocalName(child);
      node_info["nodeId"] = ElementInspector::NodeId(child);
      node_info["nodeName"] = ElementInspector::NodeName(child);
      node_info["nodeType"] = ElementInspector::NodeType(child);
      node_info["nodeValue"] = ElementInspector::NodeValue(child);
      node_info["attributes"] =
          GetAttributesImpl(devtool_agent, ElementInspector::NodeId(child));
      nodes.append(node_info);
    }
  }

  content["parentId"] = node_id;
  content["nodes"] = nodes;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  // call method

  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::GetBoxModel(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int index = params["nodeId"].asInt();
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  double screen_scale_factor = 1.0f;
#if OS_OSX || OS_WIN
  // view may move between screens on pc,so its pos and size
  //  need multiply by current screen scale factor
  screen_scale_factor = devtool_agent->GetScreenScaleFactor();
#endif
  if (ptr != nullptr &&
      ElementInspector::Type(ptr) == InspectorElementType::SHADOWROOT) {
    content =
        ElementHelper::GetBoxModelOfNode(ptr->parent(), screen_scale_factor);
  } else if (ptr != nullptr) {
    content = ElementHelper::GetBoxModelOfNode(ptr, screen_scale_factor);
  }
  if (content.empty()) {
    auto error = Json::Value(Json::ValueType::objectValue);
    error["code"] = Json::Value(-32000);
    error["message"] = Json::Value("Could not compute box model.");
    content["error"] = error;
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::SetAttributesAsText(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::vector<Json::Value> msg_v;
  int index = params["nodeId"].asInt();
  std::string name = params["name"].asString();
  std::string text = params["text"].asString();
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    msg_v = ElementHelper::SetAttributesAsText(ptr, name, text);
  }
  for (const auto& msg : msg_v) {
    devtool_agent->DispatchJsonMessage(msg);
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::AttributeModified(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value res(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int index_id = params["nodeId"].asInt();
  std::string name = params["name"].asString();
  res["name"] = name;
  res["nodeId"] = index_id;
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index_id);
  if (ptr != nullptr) {
    res["value"] = ElementHelper::GetAttributesAsTextOfNode(ptr, name);
  }
  content["method"] = "DOM.attributeModified";
  content["params"] = res;
  devtool_agent->SendResponseAsync(content);
}

void InspectorDOMAgentNG::MarkUndoableState(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::CharacterDataModified(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value res(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int index_id = params["nodeId"].asInt();
  content["method"] = "DOM.characterDataModified";
  res["nodeId"] = index_id;
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index_id);
  if (ptr != nullptr) {
    res["characterData"] = ElementHelper::GetStyleNodeText(ptr);
  }
  content["params"] = res;
  devtool_agent->SendResponseAsync(content);
}

void InspectorDOMAgentNG::DocumentUpdated(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  content["method"] = "DOM.documentUpdated";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

void InspectorDOMAgentNG::AttributeRemoved(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  content["method"] = "DOM.attributeRemoved";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

void InspectorDOMAgentNG::ChildNodeInserted(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  auto index = params["nodeId"].asInt();
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr && ptr->parent() != nullptr) {
    content["method"] = "DOM.childNodeInserted";
    content["params"] = params;
    content["params"].removeMember("nodeId");

    // when set removeComponentElement, previous node should be fake component
    // element for component's unique child
    Element* previous_node = ElementHelper::GetPreviousNode(ptr);
    if (!previous_node) {
      content["params"]["previousNodeId"] = 0;
    } else if (ElementInspector::GetParentComponentElementFromDataModel(
                   previous_node) &&
               ElementInspector::IsNeedEraseId(
                   ElementInspector::GetParentComponentElementFromDataModel(
                       previous_node))) {
      content["params"]["previousNodeId"] = ElementInspector::NodeId(
          ElementInspector::GetParentComponentElementFromDataModel(
              previous_node));
    } else {
      content["params"]["previousNodeId"] =
          ElementInspector::NodeId(previous_node);
    }

    // if add plug to component
    auto parent_id = params["parentNodeId"].asInt();
    Element* parent =
        devtool_agent->GetElementById(devtool_agent->GetRoot(), parent_id);
    if (parent && ElementInspector::SelectorTag(parent) == "component") {
      content["params"]["node"] =
          ElementHelper::GetDocumentBodyFromNode(ptr, true);
    } else {
      content["params"]["node"] =
          ElementHelper::GetDocumentBodyFromNode(ptr, false);
    }

    content["compress"] = false;

    devtool_agent->SendResponseAsync([content, this, devtool_agent]() mutable {
      std::string params_str = content["params"].toStyledString();
      if (this->use_compression_ &&
          params_str.size() >
              static_cast<size_t>(this->compression_threshold_)) {
        this->CompressData("childNodeInserted",
                           content["params"].toStyledString(), content,
                           "params");
      }
      devtool_agent->SendJsonResponse(content);
    });
  }
}

void InspectorDOMAgentNG::ChildNodeRemoved(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  content["method"] = "DOM.childNodeRemoved";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

void InspectorDOMAgentNG::GetNodeForLocation(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  int x = params["x"].asInt();
  int y = params["y"].asInt();
#if OS_OSX || OS_WIN
  double scale_factor = devtool_agent->GetScreenScaleFactor();
  x = x / scale_factor;
  y = y / scale_factor;
#endif

  Element* root = devtool_agent->GetRoot();
  if (root != nullptr) {
    x = x * ElementInspector::GetDeviceDensity();
    y = y * ElementInspector::GetDeviceDensity();
    int id = 0;
#if !ENABLE_RENDERKIT
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
#else
    // if enable renderkit, we will use renderkit api to get node id.
    // in renderkit, GetNodeForLocation is implemented by hittest.
    // the coordinates should be relative to lynx view rather than window or
    // screen.
    id = ElementInspector::GetNodeForLocation(root, x, y);
#endif
    content["backendNodeId"] = id;
    content["nodeId"] = id;
  }

  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::PushNodesByBackendIdsToFrontend(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value nodeIds(Json::ValueType::arrayValue);
  Json::Value params = message["params"];
  nodeIds = params["backendNodeIds"];
  content["nodeIds"] = nodeIds;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::RemoveNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
}

void InspectorDOMAgentNG::MoveTo(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                 const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
}

void InspectorDOMAgentNG::CopyTo(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                 const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
}

void InspectorDOMAgentNG::GetOuterHTML(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr != nullptr) {
    content["outerHTML"] = ElementHelper::GetElementContent(ptr, 0);
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::SetOuterHTML(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
}

void InspectorDOMAgentNG::SetInspectedNode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorDOMAgentNG::PerformSearch(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  std::string query = params["query"].asString();
  uint64_t searchId = lynx::base::CurrentTimeMilliseconds();
  std::vector<int> searchResults;
  ElementHelper::PerformSearchFromNode(devtool_agent->GetRoot(), query,
                                       searchResults);
  search_results_[searchId] = searchResults;
  content["searchId"] = searchId;
  content["resultCount"] = static_cast<int>(searchResults.size());
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
}

void InspectorDOMAgentNG::GetSearchResults(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  uint64_t searchId = params["searchId"].asUInt64();
  int fromIndex = params["fromIndex"].asInt();
  int toIndex = params["toIndex"].asInt();
  Json::Value nodeIds(Json::ValueType::arrayValue);
  auto iter = search_results_.find(searchId);
  if (iter != search_results_.end()) {
    std::vector<int> searchResults = iter->second;
    for (int index = fromIndex; index < toIndex; ++index) {
      nodeIds.append(Json::Value(searchResults[index]));
    }
    content["nodeIds"] = nodeIds;
    response["result"] = content;
  } else {
    Json::Value error(Json::ValueType::objectValue);
    error["code"] = 32000;
    error["message"] = "SearchId not found.";
    response["error"] = error;
  }
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
}

void InspectorDOMAgentNG::DiscardSearchResults(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  uint64_t searchId = params["searchId"].asUInt64();
  if (search_results_.find(searchId) != search_results_.end()) {
    search_results_.erase(searchId);
    response["result"] = content;
  } else {
    Json::Value error(Json::ValueType::objectValue);
    error["code"] = 32000;
    error["message"] = "SearchId not found.";
    response["error"] = error;
  }
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
}

void InspectorDOMAgentNG::ScrollIntoViewIfNeeded(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);

  Json::Value params = message["params"];
  size_t node_id = static_cast<size_t>(params["nodeId"].asInt64());

  Element* element =
      devtool_agent->GetElementById(devtool_agent->GetRoot(), node_id);
  if (element != nullptr) {
    ElementInspector::ScrollIntoView(element);
  }

  response["id"] = message["id"].asInt64();
  response["result"] = content;
  devtool_agent->SendResponseAsync(response.toStyledString());
}

void InspectorDOMAgentNG::CallMethod(
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
