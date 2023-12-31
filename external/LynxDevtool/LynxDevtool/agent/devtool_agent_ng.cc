// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool_agent_ng.h"

#include <functional>

#include "agent/agent_constants.h"
#include "agent/domain_agent/inspector_agent.h"
#include "agent/domain_agent/inspector_ark_recorder_agent.h"
#include "agent/domain_agent/inspector_ark_replay_agent.h"
#include "agent/domain_agent/inspector_component_agent.h"
#include "agent/domain_agent/inspector_css_agent_ng.h"
#include "agent/domain_agent/inspector_debugger_agent.h"
#include "agent/domain_agent/inspector_dom_agent_ng.h"
#include "agent/domain_agent/inspector_heap_profiler_agent.h"
#include "agent/domain_agent/inspector_input_agent.h"
#include "agent/domain_agent/inspector_io_agent.h"
#include "agent/domain_agent/inspector_layer_tree_agent_ng.h"
#include "agent/domain_agent/inspector_layout_agent.h"
#include "agent/domain_agent/inspector_log_agent.h"
#include "agent/domain_agent/inspector_lynx_agent_ng.h"
#include "agent/domain_agent/inspector_memory_agent.h"
#include "agent/domain_agent/inspector_overlay_agent_ng.h"
#include "agent/domain_agent/inspector_page_agent_ng.h"
#include "agent/domain_agent/inspector_performance_agent.h"
#include "agent/domain_agent/inspector_profiler_agent.h"
#include "agent/domain_agent/inspector_runtime_agent.h"
#include "agent/domain_agent/inspector_template_agent.h"
#include "agent/domain_agent/inspector_tracing_agent.h"
#include "agent/domain_agent/inspector_ui_tree_agent.h"
#include "agent/domain_agent/system_info_agent.h"
#include "base/any.h"
#include "base/lynx_env.h"
#include "base/no_destructor.h"
#include "css/css_decoder.h"
#include "css/css_value.h"
#include "css/css_variable_handler.h"
#include "element/element_helper.h"
#include "element/inspector_css_helper.h"
#include "inspector/style_sheet.h"
#include "tasm/attribute_holder.h"
#include "tasm/base/tasm_constants.h"
#include "tasm/react/element.h"
#include "tasm/replay/replay_controller.h"

#if !defined(OS_WIN)
#include <unistd.h>
#endif

#if LYNX_ENABLE_TRACING
#include "base/trace_event/perfetto_trace_backend.h"
#include "tracing/instance_counter_trace_impl.h"
#endif

namespace {
static const char kDomainDot = '.';
}  // namespace

using namespace lynx::tasm;

namespace lynxdev {
namespace devtool {
static constexpr char kDomainKeyPrefix[] = "enable_cdp_domain_";

std::map<DevtoolFunction, std::function<void(const lynx::base::any&)>>
GetFunctionForElementMap() {
  static std::map<DevtoolFunction, std::function<void(const lynx::base::any&)>>
      function_map = {
          {DevtoolFunction::InitForInspector,
           &ElementInspector::InitForInspector},
          {DevtoolFunction::InitStyleValueElement,
           &ElementInspector::InitStyleValueElement},
          {DevtoolFunction::InitSlotElement,
           &ElementInspector::InitSlotElement},
          {DevtoolFunction::InitStyleRoot, &ElementInspector::InitStyleRoot},
          {DevtoolFunction::SetDocElement, &ElementInspector::SetDocElement},
          {DevtoolFunction::SetShadowRootElement,
           &ElementInspector::SetShadowRootElement},
          {DevtoolFunction::SetStyleElement,
           &ElementInspector::SetStyleElement},
          {DevtoolFunction::SetStyleValueElement,
           &ElementInspector::SetStyleValueElement},
          {DevtoolFunction::SetStyleRoot, &ElementInspector::SetStyleRoot},
          {DevtoolFunction::InsertPlug, &ElementInspector::InsertPlug},
          {DevtoolFunction::SetSlotElement, &ElementInspector::SetSlotElement},
          {DevtoolFunction::SetPlugElement, &ElementInspector::SetPlugElement},
          {DevtoolFunction::SetSlotComponentElement,
           &ElementInspector::SetSlotComponentElement}};
  return function_map;
}

DevToolAgentNG::DevToolAgentNG() : element_root_(nullptr) {
  if (lynx::base::LynxEnv::GetInstance().IsDevtoolEnabled() ||
      lynx::base::LynxEnv::GetInstance().IsDebugModeEnabled()) {
    Attach();
  } else if (lynx::base::LynxEnv::GetInstance()
                 .IsDevtoolEnabledForDebuggableView()) {
    std::unordered_set<std::string> activated_domains =
        lynx::base::LynxEnv::GetInstance().GetActivatedCDPDomains();
    for (const auto& domain : activated_domains) {
      Attach(domain);
    }
  }
}

Element* DevToolAgentNG::GetRoot() { return element_root_; }

lynx::fml::Thread& DevToolAgentNG::GetAgentThread() {
  static lynx::base::NoDestructor<lynx::fml::Thread> agent_thread(
      "AgentThread");
  return *agent_thread;
}

void DevToolAgentNG::DispatchJsonMessage(const Json::Value& msg) {
  std::string method = msg["method"].asString();
  std::string domain = method.substr(0, method.find(kDomainDot));
  Json::Value content;
  Json::Value callback;

  auto iter = agent_map_.find(domain);
  if (iter == agent_map_.end()) {
    Json::Value error;
    error["code"] = kLynxInspectorErrorCode;
    error["message"] = "Not implemented: " + method;
    content["error"] = error;
    content["id"] = msg["id"].asInt64();
    SendResponseAsync(content);
  } else {
    iter->second->CallMethod(shared_from_this(), msg);
  }
}

void DevToolAgentNG::DispatchConsoleMessage(
    const lynx::piper::ConsoleMessage& message) {
  auto iter = agent_map_.find("Log");
  if (iter != agent_map_.end()) {
    InspectorLogAgent* agent =
        static_cast<InspectorLogAgent*>(iter->second.get());
    agent->SendLog(shared_from_this(), message);
  }
}

Element* DevToolAgentNG::GetElementById(Element* root, size_t indexId) {
  if (root) {
    return ElementInspector::GetElementByID(root, static_cast<int>(indexId));
  } else {
    return nullptr;
  }
}

void DevToolAgentNG::GetElementPtrMatchingStyleSheet(
    std::vector<Element*>& res, Element* root,
    const std::string& style_sheet_name) {
  if (root == nullptr) return;
  if (style_sheet_name.empty()) return;
  if (style_sheet_name == "*" ||
      style_sheet_name == ElementInspector::SelectorId(root) ||
      style_sheet_name == ElementInspector::SelectorTag(root)) {
    res.push_back(root);
  } else if (ElementInspector::Type(root) != InspectorElementType::HTMLBODY &&
             style_sheet_name == "body *") {
    res.push_back(root);
  } else {
    for (const auto& name : ElementInspector::ClassOrder(root)) {
      if (style_sheet_name == name) {
        res.push_back(root);
        break;
      } else {
        bool found = GetElementPtrMatchingForCascadedStyleSheet(
            res, root, name, style_sheet_name);
        if (found) break;
      }
    }
    if (!ElementInspector::SelectorId(root).empty())
      GetElementPtrMatchingForCascadedStyleSheet(
          res, root, ElementInspector::SelectorId(root), style_sheet_name);
  }
  if (!root->GetChild().empty()) {
    for (const auto& child : root->GetChild()) {
      GetElementPtrMatchingStyleSheet(res, child, style_sheet_name);
    }
  }
}

bool DevToolAgentNG::GetElementPtrMatchingForCascadedStyleSheet(
    std::vector<lynx::tasm::Element*>& res, lynx::tasm::Element* root,
    const std::string& name, const std::string& style_sheet_name) {
  auto* parent = root->parent();
  while (parent) {
    for (const auto& parent_name : ElementInspector::ClassOrder(parent)) {
      if (style_sheet_name == name + parent_name) {
        res.push_back(root);
        return true;
      }
    }
    parent = parent->parent();
  }

  parent = root->parent();
  while (parent) {
    if (!ElementInspector::SelectorId(parent).empty()) {
      if (style_sheet_name == name + ElementInspector::SelectorId(parent)) {
        res.push_back(root);
        return true;
      }
    }
    parent = parent->parent();
  }
  return false;
}

void DevToolAgentNG::GetElementByType(InspectorElementType type,
                                      std::vector<Element*>& res,
                                      Element* root) {
  if (root == nullptr) return;
  if (ElementInspector::Type(root) == type) {
    res.push_back(root);
  }

  if (ElementInspector::Type(root) == InspectorElementType::COMPONENT) {
    auto* shadow_root = ElementInspector::ShadowRootElement(root);
    GetElementByType(type, res, shadow_root);
  } else if (ElementInspector::Type(root) == InspectorElementType::SHADOWROOT) {
    auto* style = ElementInspector::StyleElement(root);
    GetElementByType(type, res, style);
  } else if (ElementInspector::Type(root) == InspectorElementType::STYLE) {
    auto* style_value = ElementInspector::StyleValueElement(root);
    GetElementByType(type, res, style_value);
  }

  if (!root->GetChild().empty()) {
    for (const auto& child : root->GetChild()) {
      GetElementByType(type, res, child);
    }
  }
}

void DevToolAgentNG::Call(const std::string& function,
                          const std::string& params) {
  if (function == "OnLayoutPerformanceCollected") {
    OnLayoutPerformanceCollected(params);
    return;
  } else if (function == "EndReplayTest") {
    EndReplayTest(params);
    return;
  } else if (function == "SendLayoutTree") {
    SendLayoutTree();
    return;
  }

  Json::Value para;
  Json::Reader reader;
  reader.parse(params, para);

  if (function == "OnComponentUselessUpdate") {
    const std::string* const component_name = reinterpret_cast<std::string*>(
        static_cast<intptr_t>(para[0].asInt64()));
    const lynx::lepus::Value* const properties =
        reinterpret_cast<lynx::lepus::Value*>(
            static_cast<intptr_t>(para[1].asInt64()));
    OnComponentUselessUpdate(component_name, properties);
  } else if (function == lynx::tasm::kOnDocumentUpdated) {
    OnDocumentUpdated();
  } else {
    Element* ptr =
        reinterpret_cast<Element*>(static_cast<intptr_t>(para[0].asInt64()));
    if (ptr) {
      if (function == "OnElementNodeAdded") {
        OnElementNodeAdded(ptr);
      } else if (function == "OnElementNodeRemoved") {
        OnElementNodeRemoved(ptr);
      } else if (function == "OnElementNodeMoved") {
        OnElementNodeMoved(ptr);
      } else if (function == "OnElementDataModelSetted") {
        OnElementDataModelSetted(ptr, static_cast<intptr_t>(para[1].asInt64()));
      } else if (function == "OnCSSStyleSheetAdded") {
        OnCSSStyleSheetAdded(ptr);
      } else if (function == "OnSetNativeProps") {
        const std::string* name_ptr = reinterpret_cast<std::string*>(
            static_cast<intptr_t>(para[1].asInt64()));
        const std::string* value_ptr = reinterpret_cast<std::string*>(
            static_cast<intptr_t>(para[2].asInt64()));
        bool* is_style_ptr =
            reinterpret_cast<bool*>(static_cast<intptr_t>(para[3].asInt64()));
        OnSetNativeProps(ptr, *name_ptr, *value_ptr, *is_style_ptr);
      }
    }
  }
}

void DevToolAgentNG::SendJsonResponse(const Json::Value& data) {
  SendResponse(data.toStyledString());
}

void DevToolAgentNG::SendResponseAsync(const Json::Value& data) {
  RunOnAgentThread(
      [self = shared_from_this(), data]() { self->SendJsonResponse(data); });
}

void DevToolAgentNG::SendResponseAsync(lynx::base::closure closure) {
  RunOnAgentThread(std::move(closure));
}

void DevToolAgentNG::OnDocumentUpdated() {
  Json::Value msg(Json::ValueType::objectValue);
  msg[kMethod] = kDOMDocumentUpdated;
  DispatchJsonMessage(msg);
}

void DevToolAgentNG::OnElementNodeAdded(Element* ptr) {
  if (ElementInspector::SelectorTag(ptr) == "page") {
    element_root_ = ptr;
#if LYNX_ENABLE_TRACING
    lynx::base::tracing::InstanceCounterTraceImpl::InitNodeCounter();
#endif
  } else {
    auto* parent = ptr->parent();
    if (parent != nullptr) {
      if (ElementInspector::Type(parent) == InspectorElementType::COMPONENT) {
        parent = ElementInspector::ShadowRootElement(parent);
      }

      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.childNodeInserted";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      DispatchJsonMessage(msg);

      if (ElementInspector::SlotElement(ptr) != nullptr) {
        auto* component = ElementInspector::SlotComponentElement(
            ElementInspector::SlotElement(ptr));
        Json::Value msg_plug(Json::ValueType::objectValue);
        msg["method"] = "DOM.childNodeInserted";
        msg["params"] = Json::ValueType::objectValue;
        msg["params"]["parentNodeId"] = ElementInspector::NodeId(component);
        msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
        DispatchJsonMessage(msg);
      }
    }
  }
#if LYNX_ENABLE_TRACING
  lynx::base::tracing::InstanceCounterTraceImpl::IncrementNodeCounter(ptr);
#endif
}

void DevToolAgentNG::OnElementNodeRemoved(Element* ptr) {
  auto* parent = ptr->parent();
  if (parent) {
    if (ElementInspector::Type(parent) == InspectorElementType::COMPONENT) {
      parent = ElementInspector::ShadowRootElement(parent);
    }
    if (!ElementInspector::SlotElement(ptr)) {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.childNodeRemoved";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      DispatchJsonMessage(msg);
    } else {
      Json::Value msg(Json::ValueType::objectValue);
      auto* slot = ElementInspector::SlotElement(ptr);
      msg["method"] = "DOM.childNodeRemoved";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
      msg["params"]["nodeId"] = ElementInspector::NodeId(slot);
      DispatchJsonMessage(msg);
    }
#if LYNX_ENABLE_TRACING
    lynx::base::tracing::InstanceCounterTraceImpl::DecrementNodeCounter(ptr);
#endif
  } else if (ElementInspector::IsNeedEraseId(ptr)) {
    parent = ElementInspector::GetParentElementForComponentRemoveView(ptr);
    if (parent) {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.childNodeRemoved";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      DispatchJsonMessage(msg);
    }
  }
  if (ElementInspector::SlotElement(ptr)) {
    Json::Value msg(Json::ValueType::objectValue);
    auto* component = ElementInspector::SlotComponentElement(
        ElementInspector::SlotElement(ptr));
    msg["method"] = "DOM.childNodeRemoved";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["parentNodeId"] = ElementInspector::NodeId(component);
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    DispatchJsonMessage(msg);
    ElementInspector::ErasePlug(component, ptr);
  }
}

void DevToolAgentNG::OnElementNodeMoved(Element* ptr) {
  auto* parent = ptr->parent();
  if (parent != nullptr) {
    if (ElementInspector::Type(parent) == InspectorElementType::COMPONENT) {
      parent = ElementInspector::ShadowRootElement(parent);
    }
    Json::Value msg(Json::ValueType::objectValue);
    msg["method"] = "DOM.childNodeRemoved";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    DispatchJsonMessage(msg);
    msg["method"] = "DOM.childNodeInserted";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["parentNodeId"] = ElementInspector::NodeId(parent);
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    DispatchJsonMessage(msg);
  }
}

void DevToolAgentNG::OnElementDataModelSetted(Element* ptr,
                                              intptr_t new_node_ptr) {
  DiffID(ptr, new_node_ptr);
  DiffAttr(ptr, new_node_ptr);
  DiffClass(ptr, new_node_ptr);
  DiffStyle(ptr, new_node_ptr);
}

void DevToolAgentNG::OnCSSStyleSheetAdded(Element* ptr) {
  Json::Value msg(Json::ValueType::objectValue);
  msg["method"] = "CSS.styleSheetAdded";
  msg["params"] = Json::Value(Json::ValueType::objectValue);
  msg["params"]["header"] = ElementHelper::GetStyleSheetHeader(ptr);
  DispatchJsonMessage(msg);
}

void DevToolAgentNG::OnComponentUselessUpdate(
    const std::string* const component_name,
    const lynx::lepus::Value* const properties) {
  Json::Value result(Json::ValueType::objectValue);
  result["componentName"] = *component_name;
  std::ostringstream s;
  properties->PrintValue(s);
  result["properties"] = s.str();
  Json::Value msg(Json::ValueType::objectValue);
  msg["method"] = "Component.uselessUpdate";
  msg["params"] = result;
  DispatchJsonMessage(msg);
}

void DevToolAgentNG::OnSetNativeProps(lynx::tasm::Element* ptr,
                                      const std::string& name,
                                      const std::string& value, bool is_style) {
  if (is_style) {
    ElementInspector::UpdateStyle(ptr, name, value);
    {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.attributeModified";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      msg["params"]["name"] = "style";
      DispatchJsonMessage(msg);
    }
  } else {
    ElementInspector::UpdateAttr(ptr, name, value);
    {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.attributeModified";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      msg["params"]["name"] = name;
      DispatchJsonMessage(msg);
    }
  }
}

void DevToolAgentNG::OnLayoutPerformanceCollected(
    const std::string& performanceStr) {
  Json::Value para;
  Json::Reader reader;
  reader.parse(performanceStr, para);
  Json::Value msg(Json::ValueType::objectValue);
  msg["method"] = "Layout.dataCollected";
  msg["params"] = para;
  DispatchJsonMessage(msg);
}

void DevToolAgentNG::EndReplayTest(const std::string& file_path) {
  Json::Value msg(Json::ValueType::objectValue);
  msg["method"] = "Replay.end";
  msg["params"] = file_path;
  DispatchJsonMessage(msg);
}

void DevToolAgentNG::SendLayoutTree() {
  auto root = GetRoot();
  if (root) {
    lynx::tasm::replay::ReplayController::SendFileByAgent(
        "Layout", ElementInspector::GetLayoutTree(root));
  }
}

void DevToolAgentNG::DiffID(Element* ptr, intptr_t new_node_ptr) {
  auto old_id = ElementInspector::SelectorId(ptr);
  auto new_id =
      ElementInspector::GetSelectorIDFromAttributeHolder(ptr, new_node_ptr);
  ElementInspector::SetSelectorId(ptr, new_id);
  if (!old_id.empty()) {
    ElementInspector::DeleteAttr(ptr, "id");
    Json::Value msg(Json::ValueType::objectValue);
    msg["method"] = "DOM.attributeRemoved";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    msg["params"]["name"] = "id";
    DispatchJsonMessage(msg);
  }
  if (!new_id.empty()) {
    ElementInspector::UpdateAttr(ptr, "id", new_id);
    Json::Value msg(Json::ValueType::objectValue);
    msg["method"] = "DOM.attributeModified";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
    msg["params"]["name"] = "id";
    DispatchJsonMessage(msg);
  }
}

void DevToolAgentNG::DiffAttr(Element* ptr, intptr_t new_node_ptr) {
  const auto& old_attr =
      ElementInspector::GetAttrFromAttributeHolder(ptr, kElementPtr).second;
  const auto& new_attr =
      ElementInspector::GetAttrFromAttributeHolder(ptr, new_node_ptr).second;

  // Events are also a type of attribute, so when DiffAttr is performed, events
  // are also diffed.
  const auto& old_event_attr =
      ElementInspector::GetEventMapFromAttributeHolder(ptr, kElementPtr).second;
  const auto& new_event_attr =
      ElementInspector::GetEventMapFromAttributeHolder(ptr, new_node_ptr)
          .second;

  const auto& old_data_attr =
      ElementInspector::GetDataSetFromAttributeHolder(ptr, kElementPtr).second;
  const auto& new_data_attr =
      ElementInspector::GetDataSetFromAttributeHolder(ptr, new_node_ptr).second;

  const auto& diff_attr_map_function = [this, ptr](const auto& new_attr,
                                                   const auto& old_attr) {
    for (const auto& pair : new_attr) {
      auto iter = old_attr.find(pair.first);
      if (iter == old_attr.end() || iter->second != pair.second) {
        ElementInspector::UpdateAttr(ptr, pair.first, pair.second);
        Json::Value msg(Json::ValueType::objectValue);
        msg["method"] = "DOM.attributeModified";
        msg["params"] = Json::ValueType::objectValue;
        msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
        msg["params"]["name"] = pair.first;
        DispatchJsonMessage(msg);
      }
    }
    for (const auto& pair : old_attr) {
      if (new_attr.find(pair.first) == new_attr.end()) {
        ElementInspector::DeleteAttr(ptr, pair.first);
        Json::Value msg(Json::ValueType::objectValue);
        msg["method"] = "DOM.attributeRemoved";
        msg["params"] = Json::ValueType::objectValue;
        msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
        msg["params"]["name"] = pair.first;
        DispatchJsonMessage(msg);
      }
    }
  };

  diff_attr_map_function(new_attr, old_attr);
  diff_attr_map_function(new_event_attr, old_event_attr);
  diff_attr_map_function(new_data_attr, old_data_attr);
}

void DevToolAgentNG::DiffClass(Element* ptr, intptr_t new_node_ptr) {
  auto old_class =
      ElementInspector::GetClassOrderFromAttributeHolder(ptr, kElementPtr);
  auto new_class =
      ElementInspector::GetClassOrderFromAttributeHolder(ptr, new_node_ptr);
  if (old_class != new_class) {
    ElementInspector::DeleteClasses(ptr);
    {
      Json::Value msg(Json::ValueType::objectValue);
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      msg["params"]["name"] = "class";
      msg["method"] = "DOM.attributeRemoved";
      DispatchJsonMessage(msg);
    }

    ElementInspector::UpdateClasses(ptr, new_class);
    {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.attributeModified";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      msg["params"]["name"] = "class";
      DispatchJsonMessage(msg);
    }
  }
}

void DevToolAgentNG::DiffStyle(Element* ptr, intptr_t new_node_ptr) {
  auto old_style =
      ElementInspector::GetInlineStylesFromAttributeHolder(ptr, kElementPtr);
  auto new_style =
      ElementInspector::GetInlineStylesFromAttributeHolder(ptr, new_node_ptr);
  for (const auto& pair : new_style) {
    ElementInspector::UpdateStyle(ptr, pair.first, pair.second);
    {
      Json::Value msg(Json::ValueType::objectValue);
      msg["method"] = "DOM.attributeModified";
      msg["params"] = Json::ValueType::objectValue;
      msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
      msg["params"]["name"] = "style";
      DispatchJsonMessage(msg);
    }
  }
  for (const auto& pair : old_style) {
    if (new_style.find(pair.first) == new_style.end()) {
      ElementInspector::DeleteStyle(ptr, pair.first);
      {
        Json::Value msg(Json::ValueType::objectValue);
        msg["params"] = Json::ValueType::objectValue;
        msg["params"]["nodeId"] = ElementInspector::NodeId(ptr);
        msg["params"]["name"] = "style";
        if (ElementInspector::GetInlineStyleSheet(ptr)
                .css_properties_.empty()) {
          msg["method"] = "DOM.attributeRemoved";
        } else {
          msg["method"] = "DOM.attributeModified";
        }
        DispatchJsonMessage(msg);
      }
    }
  }
}

void DevToolAgentNG::Attach() {
  agent_map_["Inspector"] = std::make_unique<InspectorAgent>();
  agent_map_["CSS"] = std::make_unique<InspectorCSSAgentNG>();
  agent_map_["Debugger"] = std::make_unique<InspectorDebuggerAgent>();
  agent_map_["DOM"] = std::make_unique<InspectorDOMAgentNG>();
  agent_map_["Overlay"] = std::make_unique<InspectorOverlayAgentNG>();
  agent_map_["Input"] = std::make_unique<InspectorInputAgent>();
  agent_map_["Log"] = std::make_unique<InspectorLogAgent>();
  agent_map_["Page"] = std::make_unique<InspectorPageAgentNG>();
  agent_map_["Runtime"] = std::make_unique<InspectorRuntimeAgent>();
  agent_map_["Tracing"] = std::make_unique<InspectorTracingAgent>();
  agent_map_["Recording"] = std::make_unique<InspectorArkRecorderAgent>();
  agent_map_["Replay"] = std::make_unique<InspectorArkReplayAgent>();
  agent_map_["IO"] = std::make_unique<InspectorIOAgent>();
  agent_map_["HeapProfiler"] = std::make_unique<InspectorHeapProfilerAgent>();
  agent_map_["Performance"] = std::make_unique<InspectorPerformanceAgent>();
  agent_map_["Memory"] = std::make_unique<InspectorMemoryAgent>();
  agent_map_["Layout"] = std::make_unique<InspectorLayoutAgent>();
  agent_map_["SystemInfo"] = std::make_unique<SystemInfoAgent>();
  agent_map_["Lynx"] = std::make_unique<InspectorLynxAgentNG>();
  agent_map_["Template"] = std::make_unique<InspectorTemplateAgent>();
  agent_map_["Profiler"] = std::make_unique<InspectorProfilerAgent>();
  agent_map_["Component"] = std::make_unique<InspectorComponentAgent>();
  agent_map_["LayerTree"] = std::make_unique<InspectorLayerTreeAgentNG>();
  agent_map_["UITree"] = std::make_unique<InspectorUITreeAgent>();
}

void DevToolAgentNG::Attach(const std::string& domain_key) {
  std::string domain_key_prefix(kDomainKeyPrefix);
  if (!domain_key.compare(domain_key_prefix + "dom")) {
    agent_map_["DOM"] = std::make_unique<InspectorDOMAgentNG>();
  } else if (!domain_key.compare(domain_key_prefix + "css")) {
    agent_map_["CSS"] = std::make_unique<InspectorCSSAgentNG>();
  } else if (!domain_key.compare(domain_key_prefix + "page")) {
    agent_map_["Page"] = std::make_unique<InspectorPageAgentNG>();
  } else if (!domain_key.compare(domain_key_prefix + "inspector")) {
    agent_map_["Inspector"] = std::make_unique<InspectorAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "debugger")) {
    agent_map_["Debugger"] = std::make_unique<InspectorDebuggerAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "overlay")) {
    agent_map_["Overlay"] = std::make_unique<InspectorOverlayAgentNG>();
  } else if (!domain_key.compare(domain_key_prefix + "input")) {
    agent_map_["Input"] = std::make_unique<InspectorInputAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "log")) {
    agent_map_["Log"] = std::make_unique<InspectorLogAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "runtime")) {
    agent_map_["Runtime"] = std::make_unique<InspectorRuntimeAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "tracing")) {
    agent_map_["Tracing"] = std::make_unique<InspectorTracingAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "recording")) {
    agent_map_["Recording"] = std::make_unique<InspectorArkRecorderAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "replay")) {
    agent_map_["Replay"] = std::make_unique<InspectorArkReplayAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "io")) {
    agent_map_["IO"] = std::make_unique<InspectorIOAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "heapprofiler")) {
    agent_map_["HeapProfiler"] = std::make_unique<InspectorHeapProfilerAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "performance")) {
    agent_map_["Performance"] = std::make_unique<InspectorPerformanceAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "layout")) {
    agent_map_["Layout"] = std::make_unique<InspectorLayoutAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "systeminfo")) {
    agent_map_["SystemInfo"] = std::make_unique<SystemInfoAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "lynx")) {
    agent_map_["Lynx"] = std::make_unique<InspectorLynxAgentNG>();
  } else if (!domain_key.compare(domain_key_prefix + "template")) {
    agent_map_["Template"] = std::make_unique<InspectorTemplateAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "profiler")) {
    agent_map_["Profiler"] = std::make_unique<InspectorProfilerAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "component")) {
    agent_map_["Component"] = std::make_unique<InspectorComponentAgent>();
  } else if (!domain_key.compare(domain_key_prefix + "layertree")) {
    agent_map_["LayerTree"] = std::make_unique<InspectorLayerTreeAgentNG>();
  }
}

void DevToolAgentNG::ResponseError(int id, const std::string& error) {
  Json::Value res;
  res["error"]["code"] = kLynxInspectorErrorCode;
  res["error"]["message"] = error;
  res["id"] = id;
  SendResponseAsync(res);
}

void DevToolAgentNG::ResponseOK(int id) {
  Json::Value res;
  res["result"] = Json::Value(Json::ValueType::objectValue);
  res["id"] = id;
  SendResponseAsync(res);
}

intptr_t DevToolAgentNG::GetLynxDevtoolFunction() {
  return reinterpret_cast<intptr_t>(&GetFunctionForElementMap);
}

void DevToolAgentNG::ResetTreeRoot() { element_root_ = nullptr; }

void DevToolAgentNG::RunOnAgentThread(lynx::base::closure closure) {
  GetAgentThread().GetTaskRunner()->PostTask(std::move(closure));
}

}  // namespace devtool
}  // namespace lynxdev
