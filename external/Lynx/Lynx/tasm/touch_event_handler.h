// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TOUCH_EVENT_HANDLER_H_
#define LYNX_TASM_TOUCH_EVENT_HANDLER_H_

#include <memory>
#include <set>
#include <string>
#include <vector>

#include "tasm/page_proxy.h"
#include "tasm/react/element.h"

namespace lynx {
namespace worklet {
class LepusApiHandler;
class LepusComponent;

}  // namespace worklet
namespace tasm {

class AttributeHolder;
class NodeManager;
class BaseComponent;
class RadonPage;
class RadonComponent;
class RadonNode;
class TemplateAssembler;

// This struct is used to record event-related operations. After execing
// HandleEventInternal function, the event-related operations will be stored in
// a stc::vector<EventOperation>.
struct EventOperation {
  EventOperation(EventHandler *handler, Element *target,
                 Element *current_target, bool global_event)
      : handler_(handler),
        target_(target),
        current_target_(current_target),
        global_event_(global_event) {}
  EventHandler *handler_;
  Element *target_;
  Element *current_target_;
  bool global_event_;
};

class TouchEventHandler {
 public:
  class Delegate {
   public:
    Delegate() = default;
    virtual ~Delegate() = default;

    virtual void SendPageEvent(const std::string &page_name,
                               const std::string &handler,
                               const lepus::Value &info) = 0;

    virtual void PublicComponentEvent(const std::string &component_id,
                                      const std::string &handler,
                                      const lepus::Value &info) = 0;
    virtual void SendGlobalEvent(const std::string &name,
                                 const lepus::Value &info) = 0;

    virtual void CallJSFunctionInLepusEvent(const int64_t component_id,
                                            const std::string &name,
                                            const lepus::Value &params) = 0;
  };

  TouchEventHandler(NodeManager *node_manager, Delegate &delegate,
                    bool support_component_js, bool use_lepus_ng,
                    const std::string &version);

  // TODO(songshourui.null) : unify the following three functions.
  void HandleTouchEvent(TemplateAssembler *tasm, const std::string &page_name,
                        const std::string &name, int tag, float x, float y,
                        float client_x, float client_y, float page_x,
                        float page_y);

  void HandleBubbleEvent(TemplateAssembler *tasm, const std::string &page_name,
                         const std::string &event_name, int tag,
                         lepus::DictionaryPtr params);

  void HandleTriggerComponentEvent(TemplateAssembler *tasm,
                                   const std::string &event_name,
                                   const lepus::Value &data);
  // in lepus event, this is used to call js function
  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string &name,
                                  const lepus::Value &params);
  // in lepus event, this is used to callback js function return value
  void HandleJSCallbackLepusEvent(const int64_t callback_id,
                                  TemplateAssembler *tasm,
                                  const lepus::Value &data);

  void HandleCustomEvent(TemplateAssembler *tasm, const std::string &name,
                         int tag, const lepus::Value &params,
                         const std::string &pname);
  void HandlePseudoStatusChanged(int32_t id, PseudoState pre_status,
                                 PseudoState current_status);
  static lepus::Value GetTargetInfo(int32_t impl_id,
                                    const AttributeHolder *holder);

 private:
  enum class EventType { kTouch, kCustom, kComponent, kBubble };

  std::vector<Element *> GenerateResponseChain(int tag,
                                               const EventOption &option);
  std::vector<Element *> GenerateResponseChain(PageProxy *proxy,
                                               Element *component_element,
                                               const EventOption &option);

  void FireTouchEvent(const std::string &page_name, const EventHandler *handler,
                      const Element *target, const Element *current_target,
                      float x, float y, float client_x, float client_y,
                      float page_x, float page_y);

  void ApplyEventTargetParams(lepus::DictionaryPtr params,
                              const Element *target,
                              const Element *currentTarget) const;
  void FireEvent(const EventType &type, const std::string &page_name,
                 const EventHandler *handler, const Element *target,
                 const Element *current_target,
                 const lepus::Value &params) const;

  void FireTriggerComponentEvent(PageProxy *proxy, const EventHandler *handler,
                                 Element *target, Element *current_target,
                                 const lepus::Value &data);

  lepus::Value GetCustomEventParam(const std::string &name,
                                   const std::string &pname,
                                   const EventOption &option, Element *target,
                                   Element *current_target,
                                   const lepus::Value &data) const;

  lepus::Value GetTouchEventParam(const lepus::String &handler,
                                  const Element *target,
                                  const Element *currentTarget, float x,
                                  float y, float client_x, float client_y,
                                  float page_x, float page_y) const;

  bool HandleEventInternal(const std::vector<Element *> &response_chain,
                           const std::string &event_name,
                           const EventOption &option,
                           std::vector<EventOperation> &operation);

  std::string GetEventType(const EventType &type) const;

  void SendPageEvent(const EventType &type, const std::string &page_name,
                     const std::string &event_name, const std::string &handler,
                     const lepus::Value &info) const;
  void PublicComponentEvent(const EventType &type,
                            const std::string &component_id,
                            const std::string &event_name,
                            const std::string &handler,
                            const lepus::Value &info) const;
  void SendGlobalEvent(const EventType &type, const std::string &name,
                       const lepus::Value &info) const;
  void TriggerLepusBridgesAsync(
      const EventType &type, TemplateAssembler *tasm,
      const std::string &event_name,
      const std::vector<PiperEventContent> &piper_event_vec) const;

  void FireElementWorklet(const EventType &type, tasm::TemplateAssembler *tasm,
                          tasm::BaseComponent *component,
                          const std::string &event_name, EventHandler *handler,
                          const lepus::Value &value,
                          worklet::LepusComponent *lepus_component) const;
#if ENABLE_LEPUSNG_WORKLET
  lynx::worklet::LepusComponent *CreateLepusComponent(
      tasm::TemplateAssembler *tasm, tasm::BaseComponent *component) const;
#endif  // ENABLE_LEPUSNG_WORKLET

  NodeManager *node_manager_;

  Delegate &delegate_;
  bool support_component_js_;
  bool long_press_consumed_{false};

  bool use_lepus_ng_{false};
  std::string version_;
#if ENABLE_LEPUSNG_WORKLET
  lynx::worklet::LepusComponent *lepus_component_;
  std::shared_ptr<worklet::LepusApiHandler> task_handler_;
#endif  // ENABLE_LEPUSNG_WORKLET
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TOUCH_EVENT_HANDLER_H_
