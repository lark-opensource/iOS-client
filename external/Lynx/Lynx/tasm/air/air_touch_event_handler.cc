// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/air/air_touch_event_handler.h"

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/json_parser.h"
#include "tasm/air/air_element/air_page_element.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/element_manager.h"
#include "tasm/replay/replay_controller.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {

#define EVENT_TOUCH_START "touchstart"
#define EVENT_TOUCH_MOVE "touchmove"
#define EVENT_TOUCH_CANCEL "touchcancel"
#define EVENT_TOUCH_END "touchend"
#define EVENT_TAP "tap"
#define EVENT_LONG_PRESS "longpress"

// TODO(liukeang): after validation of Air Mode, merge code with
// touch_event_handler.cc
AirTouchEventHandler::AirTouchEventHandler(AirNodeManager *air_node_manager)
    : air_node_manager_(air_node_manager) {}

void AirTouchEventHandler::HandleTouchEvent(TemplateAssembler *tasm,
                                            const std::string &page_name,
                                            const std::string &name, int tag,
                                            float x, float y, float client_x,
                                            float client_y, float page_x,
                                            float page_y) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirTouchEventHandler::HandleTouchEvent");

  if (tasm == nullptr) {
    LOGE("HandleTouchEvent error: tasm is null.");
    return;
  }

  EventOption option = {.bubbles_ = true,
                        .composed_ = true,
                        .capture_phase_ = true,
                        .lepus_event_ = false,
                        .from_frontend_ = false};

  const auto &events = GetEventOperation(
      name, GenerateResponseChain(tag, option), option, long_press_consumed_);
  for (const auto &op : events) {
    FireTouchEvent(tasm, page_name, op.handler, op.target, op.current_target, x,
                   y, client_x, client_y, page_x, page_y);
  }
}

void AirTouchEventHandler::FireTouchEvent(
    TemplateAssembler *tasm, const std::string &page_name,
    const EventHandler *handler, const AirElement *target,
    const AirElement *current_target, float x, float y, float client_x,
    float client_y, float page_x, float page_y) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_FIRE_TOUCH_EVENT);

  const lepus::Value &value =
      GetTouchEventParam(handler->name(), target, current_target, x, y,
                         client_x, client_y, page_x, page_y);

  bool in_component = current_target->InComponent();
  if (!in_component) {
    SendPageEvent(tasm, EventType::kTouch, page_name, handler->name().str(),
                  handler->function().str(), value, target);
  } else {
    SendComponentEvent(tasm, EventType::kTouch,
                       current_target->GetParentComponent()->impl_id(),
                       handler->name().str(), handler->function().str(), value,
                       target);
  }
}

size_t AirTouchEventHandler::TriggerComponentEvent(
    TemplateAssembler *tasm, const std::string &event_name,
    const lepus::Value &data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "AirTouchEventHandler::TriggerComponentEvent");
  constexpr const static char *kDetail = "detail";
  constexpr const static char *kEventDetail = "eventDetail";
  constexpr const static char *kComponentId = "componentId";
  constexpr const static char *kEventOption = "eventOption";
  lepus_value component_id = data.GetProperty(kComponentId);
  auto id =
      static_cast<int>(component_id.IsInt64() ? component_id.Int64() : -1);
  if (id < 0 || !data.IsObject()) {
    LOGE("TriggerComponentEvent error: component id or data is null.");
    return 0;
  }

  bool bubbles = false;
  bool composed = false;
  bool capture_phase = false;
  lepus_value eventOption = data.GetProperty(kEventOption);
  if (eventOption.IsObject()) {
    bubbles = eventOption.GetProperty("bubbles").IsTrue();
    composed = eventOption.GetProperty("composed").IsTrue();
    capture_phase = eventOption.GetProperty("capturePhase").IsTrue();
  }

  EventOption option{bubbles, composed, capture_phase, .lepus_event_ = false,
                     .from_frontend_ = true};
  const auto &chain = GenerateResponseChain(id, option, true);
  std::vector<AirEventOperation> ops{};
  GenerateEventOperation(chain, event_name, option, ops);
  if (tasm) {  // for unittest, tasm will be nullptr;
    HandleEventOperation(tasm, event_name, data.GetProperty(kEventDetail),
                         kDetail, option, ops);
  }
  return ops.size();
}

std::vector<AirElement *> AirTouchEventHandler::GenerateResponseChain(
    int tag, const EventOption &option, bool componentEvent) {
  std::vector<AirElement *> chain{};
  AirElement *target_node = air_node_manager_->Get(tag).get();

  if (target_node == nullptr) {
    return chain;
  }

  if (option.bubbles_ || option.composed_ || componentEvent) {
    auto root = componentEvent && !option.composed_
                    ? target_node->GetParentComponent()
                    : nullptr;
    while (target_node != nullptr && target_node != root) {
      chain.push_back(target_node);
      target_node = static_cast<AirElement *>(target_node->air_parent());
    }
  } else {
    chain.push_back(target_node);
  }
  return chain;
}

lepus::Value AirTouchEventHandler::GetTargetInfo(const AirElement *target) {
  auto dict = lepus::Dictionary::Create();

  auto data_set = lepus::Dictionary::Create();
  for (auto iter = target->data_model().begin();
       iter != target->data_model().end(); ++iter) {
    data_set.Get()->SetValue(iter->first, iter->second);
  }

  dict.Get()->SetValue(lepus::String("dataset"), lepus::Value(data_set));
  dict.Get()->SetValue(lepus::String("uid"), lepus::Value(target->impl_id()));

  return lepus::Value(dict);
}

lepus::Value AirTouchEventHandler::GetCustomEventParam(
    const std::string &name, const std::string &pname,
    const EventOption &option, AirElement *target, AirElement *current_target,
    const lepus::Value &data) const {
  auto dict = lepus::Dictionary::Create();
  lepus::Value para(dict);
  dict.Get()->SetValue(lepus::String("type"),
                       lepus::Value(lepus::StringImpl::Create(name.c_str())));
  int64_t cur = lynx::base::CurrentSystemTimeMilliseconds();
  dict.Get()->SetValue(lepus::String("timestamp"),
                       lepus::Value(static_cast<int64_t>(cur)));
  auto current_target_dict = GetTargetInfo(current_target);
  auto target_dict = GetTargetInfo(target);
  dict.Get()->SetValue(lepus::String("currentTarget"), current_target_dict);
  dict.Get()->SetValue(lepus::String("target"), target_dict);
  dict.Get()->SetValue(lepus::String(pname), data);
  return para;
}

void AirTouchEventHandler::HandleCustomEvent(TemplateAssembler *tasm,
                                             const std::string &name, int tag,
                                             const lepus::Value &params,
                                             const std::string &pname) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirTouchEventHandler::HandleCustomEvent");
  LOGI("SendCustomEvent event name:" << name << " tag:" << tag);

  if (tasm == nullptr) {
    LOGE("HandleCustomEvent error: tasm or page is null.");
    return;
  }

  EventOption option;
  std::vector<AirEventOperation> ops{};
  GenerateEventOperation(GenerateResponseChain(tag, option), name, option, ops);
  HandleEventOperation(tasm, name, params, pname, option, ops);
}

void AirTouchEventHandler::HandleEventOperation(
    TemplateAssembler *tasm, const std::string &name,
    const lepus::Value &params, const std::string &pname,
    const EventOption &option, const std::vector<AirEventOperation> &ops) {
  for (const auto &op : ops) {
    if (!op.target->InComponent()) {
      SendPageEvent(tasm, EventType::kCustom, "", name,
                    op.handler->function().str(),
                    GetCustomEventParam(name, pname, option, op.target,
                                        op.current_target, params),
                    op.current_target);
    } else {
      SendComponentEvent(tasm, EventType::kCustom,
                         op.current_target->GetParentComponent()->impl_id(),
                         name, op.handler->function().str(),
                         GetCustomEventParam(name, pname, option, op.target,
                                             op.current_target, params),
                         op.current_target);
    }
  }
}

lepus::Value AirTouchEventHandler::GetTouchEventParam(
    const lepus::String &handler, const AirElement *target,
    const AirElement *current_target, float x, float y, float client_x,
    float client_y, float page_x, float page_y) const {
  auto dict = lepus::Dictionary::Create();
  dict.Get()->SetValue(lepus::String("type"), lepus::Value(handler.impl()));
  long long cur = lynx::base::CurrentSystemTimeMilliseconds();
  dict.Get()->SetValue(lepus::String("timestamp"),
                       lepus::Value(static_cast<int64_t>(cur)));

  dict.Get()->SetValue(lepus::String("target"), GetTargetInfo(target));
  dict.Get()->SetValue(lepus::String("currentTarget"),
                       GetTargetInfo(current_target));

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

bool AirTouchEventHandler::GenerateEventOperation(
    const std::vector<AirElement *> &response_chain,
    const std::string &event_name, const EventOption &option,
    std::vector<AirEventOperation> &operation) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "HandleEventInternal");
  if (response_chain.empty()) {
    LOGE(
        "Lynx_air HandleEventInternal failed, response_chain empty & "
        "event_name "
        "is" +
        event_name);
    return false;
  }

  AirElement *target = *response_chain.begin();

  bool consume = false;
  bool capture = false;
  // candidate AirElement for handling current event
  AirElement *cur_target = nullptr;
  // handle capture_phase event, namely capture-catch & capture-bind
  if (option.capture_phase_) {
    for (auto iter = response_chain.rbegin(); iter != response_chain.rend();
         ++iter) {
      cur_target = *iter;
      if (cur_target == nullptr) {
        break;
      }
      EventHandler *handler = GetEventHandler(cur_target, event_name);
      if (!handler) {
        continue;
      }
      if (handler->IsCaptureCatchEvent()) {
        operation.push_back({handler, target, cur_target, false});
        capture = true;
        consume = true;
        break;
      } else if (handler->IsCaptureBindEvent()) {
        operation.push_back({handler, target, cur_target, false});
        consume = true;
      }
    }
  }

  // if event is not yet captured, then handle bindEvent & catchEvent
  if (!capture) {
    for (auto iter = response_chain.begin(); iter != response_chain.end();
         ++iter) {
      cur_target = *iter;
      if (cur_target == nullptr) {
        break;
      }
      EventHandler *handler = GetEventHandler(cur_target, event_name);
      if (!handler) {
        continue;
      }
      if (handler->IsCatchEvent()) {
        operation.push_back({handler, target, cur_target, false});
        consume = true;
        break;
      } else if (handler->IsBindEvent()) {
        operation.push_back({handler, target, cur_target, false});
        consume = true;
        if (!option.bubbles_) {
          break;
        }
      }
    }  // for
  }    // if
  return consume;
}

std::string AirTouchEventHandler::GetEventType(const EventType &type) const {
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
      break;
    default:
      str = "UnknownEvent";
      break;
  }
  return str;
}

/// send event to lepus
void AirTouchEventHandler::SendPageEvent(TemplateAssembler *tasm,
                                         const std::string &handler,
                                         const lepus::Value &info) const {
  SendPageEvent(tasm, EventType::kCustom, "card", handler, handler, info,
                nullptr);
}

// use template-api as callback
// e.g.: 'path.function_name'
void AirTouchEventHandler::SendBaseEvent(TemplateAssembler *tasm,
                                         const std::string &event_name,
                                         const std::string &handler,
                                         const lepus::Value &info,
                                         const AirElement *target) const {
  auto context = tasm->FindEntry(DEFAULT_ENTRY_NAME)->GetVm();

  if (context) {
    std::vector<lepus::Value> params;
    auto dot_pos = handler.find('.');
    params.emplace_back(lepus::Value(handler.substr(0, dot_pos).c_str()));
    params.emplace_back(lepus::Value(
        handler.substr(dot_pos + 1, handler.size() - dot_pos - 1).c_str()));

    params.emplace_back(info.IsTrue() ? info : lepus::Value());
    params.emplace_back(
        lepus::Value(GetComponentTarget(tasm, target)->impl_id()));

    // use template-api to handle event
    context->Call("$callBaseEvent", params);
  }
}

void AirTouchEventHandler::SendPageEvent(TemplateAssembler *tasm,
                                         const EventType &type,
                                         const std::string &page_name,
                                         const std::string &event_name,
                                         const std::string &handler,
                                         const lepus::Value &info,
                                         const AirElement *target) const {
  auto context = tasm->FindEntry(DEFAULT_ENTRY_NAME)->GetVm();

  LOGI("lynx_air, SendPageEvent, event_name=" << event_name
                                              << ", handler=" << handler);
  if (context) {
    std::vector<lepus::Value> params;
    // Two kinds of handler functions for air.
    // 1.template-api function, (name pattern would be like
    // 'path.function_name', e.g.:click_event.handleClickEvent). In this case,
    // split by '.' to get path and function name, store params in vector.
    // 2. lepus function, (e.g.: handleClickEvent)
    if (handler.find('.') != std::string::npos) {
      SendBaseEvent(tasm, event_name, handler, info, target);
      return;
    }
    params.emplace_back(lepus_value(lepus::StringImpl::Create(handler)));

    params.emplace_back(info.IsTrue() ? info : lepus::Value());
    params.emplace_back(
        lepus::Value(GetComponentTarget(tasm, target)->impl_id()));

    // use template-api to handle event
    context->Call("$callPageEvent", params);
  }
}

void AirTouchEventHandler::SendComponentEvent(
    TemplateAssembler *tasm, const EventType &type, const int component_id,
    const std::string &event_name, const std::string &handler,
    const lepus::Value &info, const AirElement *target) const {
  auto context = tasm->FindEntry(DEFAULT_ENTRY_NAME)->GetVm();
  if (context) {
    if (handler.find('.') != std::string::npos) {
      SendBaseEvent(tasm, event_name, handler, info, target);
      return;
    }
    std::vector<lepus::Value> params;
    lepus::Value id;
    id.SetNumber(static_cast<int32_t>(component_id));
    params.push_back(id);
    params.push_back(lepus_value(lepus::StringImpl::Create(handler)));
    params.push_back(info);

    params.push_back(
        lepus::Value(GetComponentTarget(tasm, target, false)->impl_id()));
    context->Call("$callComponentEvent", params);
  }
}

void AirTouchEventHandler::SendComponentEvent(TemplateAssembler *tasm,
                                              const std::string &event_name,
                                              const int component_id,
                                              const lepus::Value &params,
                                              const std::string &param_name) {
  auto shared_component = air_node_manager_->Get(component_id);
  if (!shared_component) {
    return;
  }

  SendComponentEvent(tasm, EventType::kCustom, component_id, event_name,
                     event_name, lepus::Value(), shared_component.get());
}

EventHandler *AirTouchEventHandler::GetEventHandler(
    AirElement *cur_target, const std::string &event_name) {
  auto &map = cur_target->event_map();
  auto event_handler = map.find(event_name);
  if (event_handler == map.end()) {
    return nullptr;
  }
  return (*event_handler).second.get();
}

std::vector<AirEventOperation> AirTouchEventHandler::GetEventOperation(
    const std::string &event_name, const std::vector<AirElement *> &chain,
    const EventOption &option, bool &long_press_consumed) {
  if (event_name == EVENT_TOUCH_START) {
    long_press_consumed = false;
  }
  std::vector<AirEventOperation> ops{};
  if (long_press_consumed && event_name == EVENT_TAP) {
    LOGE("Lynx_air, Send Tap Event failed, long press consumed");
    return ops;
  }

  const auto &consume = GenerateEventOperation(chain, event_name, option, ops);
  if (event_name == EVENT_LONG_PRESS) {
    long_press_consumed = consume;
  }
  return ops;
}

// Get target related component AirElement. If target is component and
// ignore_target is false, return itself; else return its parent component. If
// target is nullptr, return page element.
const AirElement *AirTouchEventHandler::GetComponentTarget(
    TemplateAssembler *tasm, const AirElement *target,
    bool ignore_target) const {
  if (target) {
    if (!ignore_target && target->is_component()) {
      return target;
    } else {
      return target->GetParentComponent();
    }
  } else {
    return static_cast<AirElement *>(
        tasm->page_proxy()->element_manager()->AirRoot());
  }
}

}  // namespace tasm
}  // namespace lynx
