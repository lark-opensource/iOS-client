// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SERVER_DOM_CONSTRUCTOR_H_
#define LYNX_SSR_SERVER_DOM_CONSTRUCTOR_H_

#include <map>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "ssr/jsx_encoder/jsx_node.h"
#include "ssr/ssr_node_key.h"
#include "tasm/attribute_holder.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_slot.h"
#include "tasm/radon/radon_types.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {
class TemplateAssembler;
}
namespace ssr {

struct EventDescriptor {
  // event descriptor id.k
  tasm::RadonNode* node_;
  lepus::String name_;
  lepus::String type_;
  EventDescriptor(tasm::RadonNode* node, const lepus::String& name,
                  const lepus::String& type)
      : node_(node), name_(name), type_(type) {}
};

enum EventType : uint8_t {
  kBind = 0,
  kCatch = 1,
  kCaptureBind = 2,
  kCaptureCatch = 3
};

// Map from the event function name to the description how a node holds the
// event;
class ServerEventsStorage {
 public:
  ServerEventsStorage(Napi::Env env) : env_(env) {}
  class ComponentEventsInfo {
   public:
    ComponentEventsInfo(Napi::Env env, tasm::RadonComponent* component,
                        ServerEventsStorage* storage);

    uint32_t InsertEvent(tasm::RadonNode* node, const lepus::String& name,
                         const lepus::String& type,
                         Napi::Value event_descriptor);
    void InsertComponentEvent(const lepus::String& name,
                              Napi::Value event_descriptor);
    void InsertChildDescriptor(const Napi::Value child);
    Napi::Object& GetComponentDescriptor() { return component_descriptor_; }

   private:
    Napi::Object component_descriptor_;
    Napi::Object children_;
    Napi::Object events_;
    Napi::Object component_events_;
    uint32_t children_length_ = 0;
    uint32_t events_array_length_ = 0;
    ServerEventsStorage* storage_;
  };

  ComponentEventsInfo* GetAndConstructComponentEventsInfo(
      tasm::RadonComponent* component);
  const EventDescriptor& GetEventDescriptor(uint32_t id) const {
    return events_storage_[id];
  }
  Napi::Value GetFormattedInfo() { return event_descriptor_; }

 private:
  std::vector<EventDescriptor> events_storage_;
  Napi::Value event_descriptor_;
  Napi::Env env_;
  std::unordered_map<const tasm::RadonComponent*,
                     ServerEventsStorage::ComponentEventsInfo>
      component_info_map_;
};

class ServerDomConstructor {
  ServerDomConstructor() = delete;

 public:
  class ConstructorContext {
   public:
    uint32_t AddComponentToIdMap(tasm::RadonComponent* comp);
    uint32_t GetComponentId(tasm::RadonComponent* comp);
    base::scoped_refptr<lepus::CArray> placeholders_ = lepus::CArray::Create();

   private:
    static constexpr uint32_t kInvalidId = 0;
    uint32_t current_component_ssr_id_ = 0;
    std::map<tasm::RadonComponent*, uint32_t> component_to_id_map_;
  };

  static lepus::Value SSRRadon(tasm::RadonBase* node, ConstructorContext*,
                               const tasm::CSSParserConfigs& configs);
  static lepus::Value SSRPageConfig(tasm::TemplateAssembler*);

  static void SSRLoadPropertiesFromJSXNode(tasm::RadonNode& node,
                                           const JSXNode& jsx_node);

  static void HarvestNodeInfo(Napi::Env env, tasm::RadonBase* base,
                              ServerEventsStorage* storage);

  static void AttachEventPredictions(const ServerEventsStorage& storage,
                                     const Napi::Value& predictions,
                                     lepus::Value* ssr_script);

 private:
  static lepus::Value SSRRadonSlot(tasm::RadonSlot* node);
  static lepus::Value SSRRadonPlug(tasm::RadonPlug* node, ConstructorContext*);
  static lepus::Value SSRRadonNode(tasm::RadonNode* node, ConstructorContext*,
                                   const tasm::CSSParserConfigs& configs);
  static lepus::Value SSRRadonComponent(tasm::RadonComponent* node,
                                        ConstructorContext*,
                                        const tasm::CSSParserConfigs& configs);
  static void FormatEvents(
      Napi::Env env, tasm::RadonNode* node,
      ServerEventsStorage::ComponentEventsInfo* info,
      ServerEventsStorage::ComponentEventsInfo* current_info);
};

}  // namespace ssr
}  // namespace lynx
#endif  // LYNX_SSR_SERVER_DOM_CONSTRUCTOR_H_
