// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/touch_event_handler.h"

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/json_parser.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_node.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element_manager.h"
#include "tasm/replay/replay_controller.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"
#include "third_party/rapidjson/document.h"

#if ENABLE_LEPUSNG_WORKLET
#include "jsbridge/bindings/worklet/napi_func_callback.h"
#include "worklet/lepus_component.h"
#include "worklet/lepus_element.h"
#include "worklet/lepus_raf_handler.h"
#endif  // ENABLE_LEPUSNG_WORKLET

namespace lynx {
namespace tasm {

#define EVENT_TOUCH_START "touchstart"
#define EVENT_TOUCH_MOVE "touchmove"
#define EVENT_TOUCH_CANCEL "touchcancel"
#define EVENT_TOUCH_END "touchend"
#define EVENT_TAP "tap"
#define EVENT_LONG_PRESS "longpress"

constexpr const static char *kDetail = "detail";

namespace {
#if ENABLE_LEPUSNG_WORKLET
BaseComponent *GetBaseComponentFromTarget(Element *target,
                                          TemplateAssembler *tasm) {
  auto parent_component_id = target->ParentComponentId();
  auto *component = tasm->page_proxy()->ComponentWithId(parent_component_id);
  if (component != nullptr) {
    return component;
  }
  return tasm->page_proxy()->Page();
}
#endif  // ENABLE_LEPUSNG_WORKLET
}  // namespace

TouchEventHandler::TouchEventHandler(NodeManager *node_manager,
                                     Delegate &delegate,
                                     bool support_component_js,
                                     bool use_lepus_ng,
                                     const std::string &version)
    : node_manager_(node_manager),
      delegate_(delegate),
      support_component_js_(support_component_js),
      use_lepus_ng_(use_lepus_ng),
      version_(version) {
#if ENABLE_LEPUSNG_WORKLET
  task_handler_ = std::make_shared<worklet::LepusApiHandler>();
#endif  // ENABLE_LEPUSNG_WORKLET
  LOGI("TouchEventHandler init: support_component_js_: "
       << (support_component_js_ ? "true" : "false")
       << "; use_lepus_ng_: " << (use_lepus_ng_ ? "true" : "false"));
}

void TouchEventHandler::HandleTouchEvent(TemplateAssembler *tasm,
                                         const std::string &page_name,
                                         const std::string &name, int tag,
                                         float x, float y, float client_x,
                                         float client_y, float page_x,
                                         float page_y) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TouchEventHandler::HandleTouchEvent");
  LOGI("HandleTouchEvent page:" << page_name << " ;event: " << name
                                << " tag:" << tag);
  if (tasm == nullptr || tasm->page_proxy() == nullptr) {
    LOGE("HandleTouchEvent error: tasm or page is null.");
    return;
  }

  const auto &f = [this, name](const auto &chain, const auto &option,
                               bool &long_press_consumed) {
    if (name == EVENT_TOUCH_START) {
      long_press_consumed = false;
    }
    std::vector<EventOperation> ops{};
    if (long_press_consumed && name == EVENT_TAP) {
      LOGI("Lynx Send Tap Event failed, longpress consumed");
      return ops;
    }
    const auto &consume = HandleEventInternal(chain, name, option, ops);
    if (name == EVENT_LONG_PRESS) {
      long_press_consumed = consume;
    }
    return ops;
  };

  EventOption option = {.bubbles_ = true,
                        .composed_ = true,
                        .capture_phase_ = true,
                        .lepus_event_ = false,
                        .from_frontend_ = false};
  const auto &chain = GenerateResponseChain(tag, option);
  for (const auto &op : f(chain, option, long_press_consumed_)) {
    // get method here
    if (op.global_event_) {
      SendGlobalEvent(
          EventType::kTouch, name,
          GetTouchEventParam(name, op.target_, op.current_target_, x, y,
                             client_x, client_y, page_x, page_y));
    } else {
      // trigger jsb event
      if (op.handler_->is_piper_event()) {
        TriggerLepusBridgesAsync(EventType::kTouch, tasm, name,
                                 *(op.handler_->piper_event_vec()));

        continue;
      }

      if (!op.handler_->is_js_event() && use_lepus_ng_) {
#if ENABLE_LEPUSNG_WORKLET
        auto component = GetBaseComponentFromTarget(op.current_target_, tasm);
        lepus_component_ = CreateLepusComponent(tasm, component);
        FireElementWorklet(
            EventType::kTouch, tasm, component, name, op.handler_,
            GetTouchEventParam(name, op.target_, op.current_target_, x, y,
                               client_x, client_y, page_x, page_y),
            lepus_component_);
#endif  // ENABLE_LEPUSNG_WORKLET
        continue;
      }

      FireTouchEvent(page_name, op.handler_, op.target_, op.current_target_, x,
                     y, client_x, client_y, page_x, page_y);
    }
  }
  return;
}

void TouchEventHandler::HandleCustomEvent(TemplateAssembler *tasm,
                                          const std::string &name, int tag,
                                          const lepus::Value &params,
                                          const std::string &pname) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TouchEventHandler::HandleCustomEvent");
  LOGI("SendCustomEvent event name:" << name << " tag:" << tag);

  if (tasm == nullptr || tasm->page_proxy() == nullptr) {
    LOGE("HandleCustomEvent error: tasm or page is null.");
    return;
  }

  EventOption option = {.bubbles_ = false,
                        .composed_ = false,
                        .capture_phase_ = false,
                        .lepus_event_ = false,
                        .from_frontend_ = false};
  std::vector<EventOperation> ops{};
  const auto &chain = GenerateResponseChain(tag, option);
  HandleEventInternal(chain, name, option, ops);
  for (const auto &op : ops) {
    if (op.global_event_) {
      SendGlobalEvent(EventType::kCustom, name,
                      GetCustomEventParam(name, pname, option, op.target_,
                                          op.current_target_, params));
    } else {
      // trigger jsb event
      if (op.handler_->is_piper_event()) {
        TriggerLepusBridgesAsync(EventType::kCustom, tasm, name,
                                 *(op.handler_->piper_event_vec()));
        continue;
      }

      if (!op.handler_->is_js_event() && use_lepus_ng_) {
#if ENABLE_LEPUSNG_WORKLET
        auto component = GetBaseComponentFromTarget(op.current_target_, tasm);
        lepus_component_ = CreateLepusComponent(tasm, component);
        FireElementWorklet(EventType::kCustom, tasm, component, name,
                           op.handler_,
                           GetCustomEventParam(name, pname, option, op.target_,
                                               op.current_target_, params),
                           lepus_component_);
#endif  // ENABLE_LEPUSNG_WORKLET
        continue;
      }

      if (!op.current_target_->InComponent()) {
        SendPageEvent(EventType::kCustom, "", name,
                      op.handler_->function().str(),
                      GetCustomEventParam(name, pname, option, op.target_,
                                          op.current_target_, params));
      } else {
        PublicComponentEvent(
            EventType::kCustom, op.current_target_->ParentComponentIdString(),
            name, op.handler_->function().str(),
            GetCustomEventParam(name, pname, option, op.target_,
                                op.current_target_, params));
      }
    }
  }
  return;
}

void TouchEventHandler::HandlePseudoStatusChanged(int32_t id,
                                                  PseudoState pre_status,
                                                  PseudoState current_status) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "TouchEventHandler::HandlePseudoStatusChanged");
  LOGI("HandlePseudoStatusChanged sign:"
       << id << " , with pre_status: " << pre_status
       << " , and current_status:" << current_status);
  Element *element = node_manager_->Get(id);
  if (element) {
    element->OnPseudoStatusChanged(pre_status, current_status);
  }
}

void TouchEventHandler::FireEvent(const EventType &type,
                                  const std::string &page_name,
                                  const EventHandler *handler,
                                  const Element *target,
                                  const Element *current_target,
                                  const lepus::Value &params) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TouchEventHandler::FireEvent");

  bool in_component = current_target->InComponent();
  if (!support_component_js_ || !in_component) {
    SendPageEvent(type, page_name, handler->name().str(),
                  handler->function().str(), params);
  } else {
    PublicComponentEvent(type, current_target->ParentComponentIdString(),
                         handler->name().str(), handler->function().str(),
                         params);
  }
}

void TouchEventHandler::ApplyEventTargetParams(
    lepus::DictionaryPtr params, const Element *target,
    const Element *current_target) const {
  if (!params || !target || !current_target) {
    return;
  }

  long long cur = std::chrono::duration_cast<std::chrono::milliseconds>(
                      std::chrono::system_clock::now().time_since_epoch())
                      .count();
  params.Get()->SetValue(lepus::String("timestamp"),
                         lepus::Value(static_cast<int64_t>(cur)));

  params->SetValue(lepus::String("target"),
                   GetTargetInfo(target->impl_id(), target->data_model()));
  params->SetValue(
      lepus::String("currentTarget"),
      GetTargetInfo(current_target->impl_id(), current_target->data_model()));
}

void TouchEventHandler::HandleBubbleEvent(TemplateAssembler *tasm,
                                          const std::string &page_name,
                                          const std::string &name, int tag,
                                          lepus::DictionaryPtr params) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TouchEventHandler::HandleBubbleEvent");
  LOGI("HandleBubbleEvent page:" << page_name << " ;event: " << name
                                 << " tag:" << tag);
  if (tasm == nullptr || tasm->page_proxy() == nullptr) {
    LOGE("HandleBubbleEvent error: tasm or page is null.");
    return;
  }

  const auto &f = [this, name](const auto &chain, const auto &option) {
    std::vector<EventOperation> ops{};
    HandleEventInternal(chain, name, option, ops);
    return ops;
  };

  EventOption option = {.bubbles_ = true,
                        .composed_ = true,
                        .capture_phase_ = true,
                        .lepus_event_ = false,
                        .from_frontend_ = false};
  const auto &chain = GenerateResponseChain(tag, option);
  for (const auto &op : f(chain, option)) {
    ApplyEventTargetParams(params, op.target_, op.current_target_);
    lepus::Value val = lepus::Value::Clone(lepus::Value(params));
    if (op.global_event_) {
      SendGlobalEvent(EventType::kBubble, name, val);
    } else {
      if (!op.handler_->is_js_event() && use_lepus_ng_) {
        ApplyEventTargetParams(params, op.target_, op.current_target_);
#if ENABLE_LEPUSNG_WORKLET
        auto component = GetBaseComponentFromTarget(op.current_target_, tasm);
        lepus_component_ = CreateLepusComponent(tasm, component);
        FireElementWorklet(
            EventType::kBubble, tasm, component, name, op.handler_,
            lepus::Value::Clone(lepus::Value(params)), lepus_component_);
#endif  // ENABLE_LEPUSNG_WORKLET
        continue;
      }

      FireEvent(EventType::kBubble, page_name, op.handler_, op.target_,
                op.current_target_, val);
    }
  }

  return;
}

void TouchEventHandler::CallJSFunctionInLepusEvent(const int64_t component_id,
                                                   const std::string &name,
                                                   const lepus::Value &params) {
#if ENABLE_LEPUSNG_WORKLET
  delegate_.CallJSFunctionInLepusEvent(component_id, name, params);
#endif
}

void TouchEventHandler::HandleTriggerComponentEvent(
    TemplateAssembler *tasm, const std::string &event_name,
    const lepus::Value &data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "TouchEventHandler::HandleTriggerComponentEvent");
  LOGI("HandleTriggerComponentEvent event: " << event_name);
  if (tasm == nullptr || tasm->page_proxy() == nullptr) {
    LOGE("TriggerComponentEvent error: page is null.");
    return;
  }
  auto page = tasm->page_proxy();
  if (!data.IsObject()) {
    LOGE("TriggerComponentEvent error: data is not table.");
    return;
  }

  lepus_value msg = data.GetProperty("eventDetail");
  lepus_value component_id = data.GetProperty("componentId");
  std::string id =
      component_id.IsString() ? component_id.String()->c_str() : "";
  if (id.empty()) {
    LOGE("TriggerComponentEvent error: not set component id.");
    return;
  }

  bool bubbles = false;
  bool composed = false;
  bool capture_phase = false;
  if (data.Contains("eventOption")) {
    lepus_value ops = data.GetProperty("eventOption");
    if (ops.IsObject() && ops.GetProperty("bubbles").IsBool()) {
      bubbles = ops.GetProperty("bubbles").Bool();
    }
    if (ops.IsObject() && ops.GetProperty("composed").IsBool()) {
      composed = ops.GetProperty("composed").Bool();
    }
    if (ops.IsObject() && ops.GetProperty("capturePhase").IsBool()) {
      capture_phase = ops.GetProperty("capturePhase").Bool();
    }
  }
  Element *component_element = page->ComponentElementWithStrId(id);
  if (component_element == nullptr) {
    LOGE("TriggerComponentEvent error: can not find component.");
    return;
  }

  EventOption option{bubbles, composed, capture_phase, .lepus_event_ = false,
                     .from_frontend_ = true};
  std::vector<EventOperation> ops{};
  const auto &chain = GenerateResponseChain(page, component_element, option);
  HandleEventInternal(chain, event_name, option, ops);
  for (const auto &op : ops) {
    if (op.global_event_) {
      SendGlobalEvent(EventType::kComponent, event_name,
                      GetCustomEventParam(event_name, kDetail, option,
                                          op.target_, op.current_target_, msg));
    } else {
      // trigger jsb event
      if (op.handler_->is_piper_event()) {
        TriggerLepusBridgesAsync(EventType::kComponent, tasm, event_name,
                                 *(op.handler_->piper_event_vec()));
        continue;
      }

      if (!op.handler_->is_js_event() && use_lepus_ng_) {
#if ENABLE_LEPUSNG_WORKLET
        auto component = GetBaseComponentFromTarget(op.current_target_, tasm);
        lepus_component_ = CreateLepusComponent(tasm, component);
        FireElementWorklet(
            EventType::kComponent, tasm, component, event_name, op.handler_,
            GetCustomEventParam(event_name, kDetail, option, op.target_,
                                op.current_target_, msg),
            lepus_component_);
#endif  // ENABLE_LEPUSNG_WORKLET
        continue;
      }

      FireTriggerComponentEvent(
          page, op.handler_, op.target_, op.current_target_,
          GetCustomEventParam(event_name, kDetail, option, op.target_,
                              op.current_target_, msg));
    }
  }
  return;
}

void TouchEventHandler::HandleJSCallbackLepusEvent(const int64_t callback_id,
                                                   TemplateAssembler *tasm,
                                                   const lepus::Value &data) {
#if ENABLE_LEPUSNG_WORKLET
  if (lepus_component_ == nullptr) {
    return;
  }
  lepus_component_->HandleJSCallbackLepus(callback_id, data);
#endif
}

std::vector<Element *> TouchEventHandler::GenerateResponseChain(
    int tag, const EventOption &option) {
  std::vector<Element *> chain{};
  Element *target_node = node_manager_->Get(tag);

  if (target_node == nullptr) {
    return chain;
  }

  if (option.bubbles_) {
    while (target_node != nullptr) {
      chain.push_back(target_node);
      target_node = static_cast<Element *>(target_node->parent());
    }
  } else {
    chain.push_back(target_node);
  }
  return chain;
}

std::vector<Element *> TouchEventHandler::GenerateResponseChain(
    PageProxy *proxy, Element *component, const EventOption &option) {
  std::vector<Element *> chain{};
  if (component == nullptr) {
    return chain;
  }

  chain.push_back(component);

  auto *root_component = component->GetParentComponentElement();
  auto *current_node = component;

  while (current_node != nullptr) {
    auto *next_node = current_node->parent();
    if (!next_node || current_node == next_node) {
      break;
    }

    current_node = next_node;

    if (current_node == root_component && !option.composed_) {
      break;
    }

    if (current_node->GetParentComponentElement() != root_component &&
        !option.composed_) {
      continue;
    }

    chain.push_back(current_node);
  }

  return chain;
}

void TouchEventHandler::FireTouchEvent(const std::string &page_name,
                                       const EventHandler *handler,
                                       const Element *target,
                                       const Element *current_target, float x,
                                       float y, float client_x, float client_y,
                                       float page_x, float page_y) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_FIRE_TOUCH_EVENT);
  const lepus::Value &value =
      GetTouchEventParam(handler->name(), target, current_target, x, y,
                         client_x, client_y, page_x, page_y);

  bool in_component = current_target->InComponent();
  if (!support_component_js_ || !in_component) {
    SendPageEvent(EventType::kTouch, page_name, handler->name().str(),
                  handler->function().str(), value);
  } else {
    PublicComponentEvent(
        EventType::kTouch, current_target->ParentComponentIdString(),
        handler->name().str(), handler->function().str(), value);
  }
}

lepus::Value TouchEventHandler::GetTouchEventParam(
    const lepus::String &handler, const Element *target,
    const Element *current_target, float x, float y, float client_x,
    float client_y, float page_x, float page_y) const {
  auto dict = lepus::Dictionary::Create();
  dict.Get()->SetValue(lepus::String("type"), lepus::Value(handler.impl()));
  long long cur = std::chrono::duration_cast<std::chrono::milliseconds>(
                      std::chrono::system_clock::now().time_since_epoch())
                      .count();
  dict.Get()->SetValue(lepus::String("timestamp"),
                       lepus::Value(static_cast<int64_t>(cur)));
  dict.Get()->SetValue(lepus::String("target"),
                       GetTargetInfo(target->impl_id(), target->data_model()));
  dict.Get()->SetValue(
      lepus::String("currentTarget"),
      GetTargetInfo(current_target->impl_id(), current_target->data_model()));

  auto detail = lepus::Dictionary::Create();
  detail.Get()->SetValue(lepus::String("x"),
                         lepus::Value(client_x / Config::Density()));
  detail.Get()->SetValue(lepus::String("y"),
                         lepus::Value(client_y / Config::Density()));

  dict.Get()->SetValue(lepus::String("detail"), lepus::Value(detail));

  auto touch = lepus::Dictionary::Create();
  touch.Get()->SetValue(lepus::String("pageX"),
                        lepus::Value(page_x / Config::Density()));
  touch.Get()->SetValue(lepus::String("pageY"),
                        lepus::Value(page_y / Config::Density()));
  touch.Get()->SetValue(lepus::String("clientX"),
                        lepus::Value(client_x / Config::Density()));
  touch.Get()->SetValue(lepus::String("clientY"),
                        lepus::Value(client_y / Config::Density()));

  touch.Get()->SetValue(lepus::String("x"),
                        lepus::Value(x / Config::Density()));
  touch.Get()->SetValue(lepus::String("y"),
                        lepus::Value(y / Config::Density()));
  int64_t identifier = reinterpret_cast<int64_t>(&touch);
  touch.Get()->SetValue(lepus::String("identifier"), lepus::Value(identifier));

  auto touches = lepus::CArray::Create();
  touches.Get()->push_back(lepus_value(touch));

  dict.Get()->SetValue(lepus::String("touches"), lepus_value(touches));

  auto changed_touches = lepus::CArray::Create();
  changed_touches.Get()->push_back(lepus::Value(touch));
  dict.Get()->SetValue(lepus::String("changedTouches"),
                       lepus::Value(changed_touches));

  lepus::Value value(dict);
  return value;
}

lepus::Value TouchEventHandler::GetTargetInfo(
    int32_t impl_id, const lynx::tasm::AttributeHolder *holder) {
  auto dict = lepus::Dictionary::Create();
  if (holder != nullptr) {
    if (holder->idSelector().impl()) {
      dict.Get()->SetValue(lepus::String("id"),
                           lepus::Value(holder->idSelector().impl()));
    } else {
      dict.Get()->SetValue(lepus::String("id"),
                           lepus::Value(lepus::StringImpl::Create("")));
    }
    auto data_set = lepus::Dictionary::Create();
    for (const auto &[key, value] : holder->dataset()) {
      data_set.Get()->SetValue(key, value);
    }
    dict.Get()->SetValue(lepus::String("dataset"), lepus::Value(data_set));
    dict.Get()->SetValue("uid", lepus::Value(impl_id));
  }
  return lepus::Value(dict);
}

void TouchEventHandler::FireTriggerComponentEvent(PageProxy *proxy,
                                                  const EventHandler *handler,
                                                  Element *target,
                                                  Element *current_target,
                                                  const lepus::Value &para) {
  bool in_component = current_target->InComponent();
  if (!support_component_js_ || !in_component) {
    SendPageEvent(EventType::kComponent, "", handler->name().str(),
                  handler->function().str(), para);
  } else {
    auto id_str = current_target->ParentComponentIdString();
    PublicComponentEvent(EventType::kComponent, id_str, handler->name().str(),
                         handler->function().str(), para);
  }
}

lepus::Value TouchEventHandler::GetCustomEventParam(
    const std::string &name, const std::string &pname,
    const EventOption &option, Element *target, Element *current_target,
    const lepus::Value &data) const {
  auto dict = lepus::Dictionary::Create();
  lepus::Value para(dict);
  dict.Get()->SetValue(lepus::String("type"),
                       lepus::Value(lepus::StringImpl::Create(name.c_str())));
  int64_t cur = std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch())
                    .count();
  dict.Get()->SetValue(lepus::String("timestamp"), lepus::Value(cur));
  auto current_target_dict =
      GetTargetInfo(current_target->impl_id(), current_target->data_model());
  auto target_dict = GetTargetInfo(target->impl_id(), target->data_model());
  // CustomEvent should contain type, timestamp, target, currentTarget and
  // detail. In the previous version (<= 2.0), Native CustomEvent contains
  // target.id, target.dataset, target.para. To avoid beak change, when
  // targetSDKVersion <= 2.0, add target.id, target.dataset & target.para to
  // dict.
  if (Version(version_) < Version(LYNX_VERSION_2_1) && !option.from_frontend_) {
    current_target_dict.Table()->SetValue(lepus::String(pname), data);
    target_dict.Table()->SetValue(lepus::String(pname), data);
    dict.Get()->SetValue(lepus::String("id"),
                         target_dict.Table()->GetValue("id"));
    dict.Get()->SetValue(lepus::String("dataset"),
                         target_dict.Table()->GetValue("dataset"));
  }
  dict.Get()->SetValue(lepus::String("currentTarget"), current_target_dict);
  dict.Get()->SetValue(lepus::String("target"), target_dict);
  dict.Get()->SetValue(lepus::String(pname), data);
  // CustomEvent should contain type, timestamp, target, currentTarget and
  // detail. In the previous version (<= 1.5), FeCustomEvent is actually
  // FeCustomEvent.detail. To avoid beak change, when targetSDKVersion < 1.6,
  // use data's key/value pair override the CustomEvent.
  if (Version(version_) < Version(LYNX_VERSION_1_6) && option.from_frontend_) {
    if (data.IsObject()) {
      ForEachLepusValue(
          data, [&dict](const lepus::Value &key, const lepus::Value &value) {
            dict->SetValue(key.String(), value);
          });
    } else {
      para = data;
    }
  }
  return para;
}

bool TouchEventHandler::HandleEventInternal(
    const std::vector<Element *> &response_chain, const std::string &event_name,
    const EventOption &option, std::vector<EventOperation> &operation) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "HandleEventInternal");
  if (response_chain.empty()) {
    LOGI(
        "Lynx HandleEventInternal failed, response_chain empty & event_name "
        "is" +
        event_name);
    return false;
  }

  const auto &find_event_f =
      [](const EventMap &map, const std::string &event_name) -> EventHandler * {
    auto find_iter = map.find(event_name);
    if (find_iter == map.end()) {
      return nullptr;
    }
    return (*find_iter).second.get();
  };

  const auto &get_handler_f =
      [&find_event_f](Element *cur_target, const std::string &event_name,
                      bool lepus_event,
                      bool global_bind_event) -> EventHandler * {
    if (global_bind_event) {
      return find_event_f(cur_target->global_bind_event_map(), event_name);
    } else if (!lepus_event) {
      return find_event_f(cur_target->event_map(), event_name);
    } else {
      return find_event_f(cur_target->lepus_event_map(), event_name);
    }
  };

  Element *target = *response_chain.begin();
  if (!option.lepus_event_) {
    for (const auto &current_target : response_chain) {
      if (current_target && current_target->EnableTriggerGlobalEvent()) {
        operation.emplace_back(nullptr, target, current_target, true);
      }
    }
  }

  const auto &push_global_bind_operation = [&event_name, &option, &operation,
                                            &get_handler_f](Element *cur_target,
                                                            Element *target) {
    EventHandler *handler =
        get_handler_f(cur_target, event_name, option.lepus_event_, true);
    operation.emplace_back(handler, target, cur_target, false);
  };

  const auto &handle_global_bind_target =
      [&push_global_bind_operation](
          Element *cur_target, Element *target,
          std::set<std::string> &global_bind_targets) {
        for (const auto &id_selector : global_bind_targets) {
          // if set not empty, means the target should have not empty id,
          // when data_model is null pointer or element id is empty, then not
          // send event
          if (target->data_model() == nullptr ||
              target->data_model()->idSelector().empty()) {
            continue;
          }
          if (id_selector == target->data_model()->idSelector().str()) {
            push_global_bind_operation(cur_target, target);
          }
        }
      };

  ElementManager *manager = target->element_manager();
  if (manager->GetGlobalBindElementIds(event_name).size() > 0) {
    for (const auto &id : manager->GetGlobalBindElementIds(event_name)) {
      Element *cur_target = node_manager_->Get(id);
      auto set = cur_target->GlobalBindTarget();
      if (set.empty()) {
        // if set is empty, means the target is all other elements
        push_global_bind_operation(cur_target, target);
      } else {
        if (set.size() > 0) {
          if (option.bubbles_) {
            for (const auto &target : response_chain) {
              handle_global_bind_target(cur_target, target, set);
            }
          } else {
            handle_global_bind_target(cur_target, target, set);
          }
        }
      }
    }
  }

  bool consume = false;
  bool capture = false;
  if (option.capture_phase_) {
    Element *cur_target = nullptr;
    for (auto iter = response_chain.rbegin(); iter != response_chain.rend();
         ++iter) {
      cur_target = *iter;
      if (cur_target == nullptr) break;
      EventHandler *handler =
          get_handler_f(cur_target, event_name, option.lepus_event_, false);
      if (!handler) continue;
      if (handler->IsCaptureCatchEvent()) {
        operation.emplace_back(handler, target, cur_target, false);
        capture = true;
        consume = true;
        break;
      } else if (handler->IsCaptureBindEvent()) {
        operation.emplace_back(handler, target, cur_target, false);
        consume = true;
      }
    }
  }

  if (!capture) {
    for (auto *cur_target : response_chain) {
      if (cur_target == nullptr) break;
      EventHandler *handler =
          get_handler_f(cur_target, event_name, option.lepus_event_, false);
      if (!handler) continue;
      if (handler->IsCatchEvent()) {
        operation.emplace_back(handler, target, cur_target, false);
        consume = true;
        break;
      } else if (handler->IsBindEvent()) {
        operation.emplace_back(handler, target, cur_target, false);
        consume = true;
        if (!option.bubbles_) {
          break;
        }
      }
    }  // for
  }    // if
  return consume;
}

std::string TouchEventHandler::GetEventType(const EventType &type) const {
  std::string str;
  switch (type) {
    case EventType::kTouch:
      str = "TouchEvent";
      break;
    case EventType::kCustom:
      str = "CustomEvent";
      break;
    case EventType::kComponent:
      str = "ComponentEvent";
      break;
    case EventType::kBubble:
      str = "BubbleEvent";
    default:
      str = "UnknownEvent";
      break;
  }
  return str;
}

void TouchEventHandler::SendPageEvent(const EventType &type,
                                      const std::string &page_name,
                                      const std::string &event_name,
                                      const std::string &handler,
                                      const lepus::Value &info) const {
  LOGI("SendPageEvent " << GetEventType(type) << ": " << event_name
                        << " with function: " << handler);

  delegate_.SendPageEvent(page_name, handler, info);
  if (type != EventType::kComponent) {
    constexpr const static char *kPrefix = "Page";
    tasm::replay::ReplayController::SendFileByAgent(
        kPrefix + GetEventType(type),
        tasm::replay::ReplayController::ConvertEventInfo(info));
  }
}

void TouchEventHandler::PublicComponentEvent(const EventType &type,
                                             const std::string &component_id,
                                             const std::string &event_name,
                                             const std::string &handler,
                                             const lepus::Value &info) const {
  LOGI("PublicComponentEvent " << GetEventType(type) << ": " << event_name
                               << " with function: " << handler);

  delegate_.PublicComponentEvent(component_id, handler, info);
  if (type != EventType::kComponent) {
    constexpr const static char *kPrefix = "Component";
    tasm::replay::ReplayController::SendFileByAgent(
        kPrefix + GetEventType(type),
        tasm::replay::ReplayController::ConvertEventInfo(info));
  }
}

void TouchEventHandler::SendGlobalEvent(const EventType &type,
                                        const std::string &name,
                                        const lepus::Value &info) const {
  LOGI("SendGlobalEvent " << GetEventType(type) << ": " << name);
  delegate_.SendGlobalEvent(name, info);
  if (type != EventType::kComponent) {
    constexpr const static char *kPrefix = "Global";
    tasm::replay::ReplayController::SendFileByAgent(
        kPrefix + GetEventType(type),
        tasm::replay::ReplayController::ConvertEventInfo(info));
  }
}

void TouchEventHandler::TriggerLepusBridgesAsync(
    const EventType &type, TemplateAssembler *tasm,
    const std::string &event_name,
    const std::vector<PiperEventContent> &piper_event_vec) const {
  for (auto &event : piper_event_vec) {
    auto func_name = event.piper_func_name_.c_str();
    auto func_args = event.piper_func_args_;
    LOGI("TriggerPiperEventAsync " << GetEventType(type) << ": " << event_name
                                   << " with function: " << func_name);

    tasm->TriggerLepusBridgeAsync(func_name, func_args);
    if (type != EventType::kComponent) {
      constexpr const static char *kPrefix = "Bridge";
      tasm::replay::ReplayController::SendFileByAgent(
          kPrefix + GetEventType(type),
          tasm::replay::ReplayController::ConvertEventInfo(func_args));
    }
  }
}

#if ENABLE_LEPUSNG_WORKLET
lynx::worklet::LepusComponent *TouchEventHandler::CreateLepusComponent(
    tasm::TemplateAssembler *tasm, tasm::BaseComponent *component) const {
  return lynx::worklet::LepusComponent::Create(
      component->ComponentId(), tasm->shared_from_this(),
      std::weak_ptr<worklet::LepusApiHandler>(task_handler_));
}
#endif  // ENABLE_LEPUSNG_WORKLET

void TouchEventHandler::FireElementWorklet(
    const EventType &type, tasm::TemplateAssembler *tasm,
    tasm::BaseComponent *component, const std::string &event_name,
    EventHandler *handler, const lepus::Value &value,
    worklet::LepusComponent *lepus_component) const {
#if ENABLE_LEPUSNG_WORKLET
  LOGI("FireLepusEvent " << GetEventType(type) << ": " << event_name);
  lynx::worklet::LepusElement::FireElementWorklet(
      tasm, component, handler->lepus_function(), handler->lepus_script(),
      value, task_handler_, lepus_component);
  // trigger patch finish when a worklet operation is completed
  tasm::PipelineOptions options;
  tasm->page_proxy()->element_manager()->OnPatchFinishInner(options);

  if (type != EventType::kComponent) {
    constexpr const static char *kPrefix = "Lepus";
    tasm::replay::ReplayController::SendFileByAgent(
        kPrefix + GetEventType(type),
        tasm::replay::ReplayController::ConvertEventInfo(value));
  }
#endif  // ENABLE_LEPUSNG_WORKLET
}

}  // namespace tasm
}  // namespace lynx
