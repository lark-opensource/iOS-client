// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/catalyzer.h"

#include <utility>

#include "base/trace_event/trace_event.h"
#include "starlight/layout/layout_object.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/element.h"
#include "tasm/react/painting_context.h"
#if ENABLE_AIR
#include "tasm/air/air_element/air_element.h"
#endif

namespace lynx {
namespace tasm {

class NodeIndexPair {
 public:
  Element* node;
  int index;
  NodeIndexPair(Element* node, int index) {
    this->node = node;
    this->index = index;
  }
};

Catalyzer::Catalyzer(std::unique_ptr<PaintingContext> painting_context)
    : painting_context_(std::move(painting_context)) {}

void Catalyzer::UpdateLayoutRecursively() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, UPDATE_LAYOUT_RECURSIVELY);
  if (root_) {
    root_->element_container()->UpdateLayout(root_->left(), root_->top());
  }
#if ENABLE_AIR
  else if (air_root_) {
    air_root_->element_container()->UpdateLayout(air_root_->left(),
                                                 air_root_->top());
  }
#endif
}

void Catalyzer::UpdateLayoutRecursivelyWithoutChange() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CATALYZER_TRIGGER_ON_NODE_READY);
  if (root_ && root_->element_container()) {
    root_->element_container()->UpdateLayoutWithoutChange();
  }
#if ENABLE_AIR
  else if (air_root_ && air_root_->element_container()) {
    air_root_->element_container()->UpdateLayoutWithoutChange();
  }
#endif
}

std::vector<float> Catalyzer::getBoundingClientOrigin(Element* node) {
  return painting_context_->getBoundingClientOrigin(node->impl_id());
}

std::vector<float> Catalyzer::getTransformValue(
    Element* node, std::vector<float> pad_border_margin_layout) {
  return painting_context_->getTransformValue(node->impl_id(),
                                              pad_border_margin_layout);
}

std::vector<float> Catalyzer::getWindowSize(Element* node) {
  return painting_context_->getWindowSize(node->impl_id());
}

std::vector<float> Catalyzer::GetRectToWindow(Element* node) {
  return painting_context_->GetRectToWindow(node->impl_id());
}

std::vector<int> Catalyzer::getVisibleOverlayView() {
  return painting_context_->getVisibleOverlayView();
}

std::vector<float> Catalyzer::GetRectToLynxView(Element* node) {
  return painting_context_->GetRectToLynxView(node->impl_id());
}

std::vector<float> Catalyzer::ScrollBy(int64_t id, float width, float height) {
  return painting_context_->ScrollBy(id, width, height);
}

int Catalyzer::GetCurrentIndex(Element* node) {
  return painting_context_->GetCurrentIndex(node->impl_id());
}

bool Catalyzer::IsViewVisible(Element* node) {
  return painting_context_->IsViewVisible(node->impl_id());
}

int Catalyzer::GetNodeForLocation(int x, int y) {
  return painting_context_->GetNodeForLocation(x, y);
}

void Catalyzer::ScrollIntoView(Element* node) {
  painting_context_->ScrollIntoView(node->impl_id());
}

void Catalyzer::Invoke(
    int64_t id, const std::string& method, const lepus::Value& params,
    const std::function<void(int32_t code, const lepus::Value& data)>&
        callback) {
  return painting_context_->Invoke(id, method, params, callback);
}

}  // namespace tasm
}  // namespace lynx
