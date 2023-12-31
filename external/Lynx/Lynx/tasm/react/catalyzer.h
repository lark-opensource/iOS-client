// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_CATALYZER_H_
#define LYNX_TASM_REACT_CATALYZER_H_

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {

class NodeIndexPair;
class Element;
class PaintingContext;
class AirElement;

class Catalyzer {
 public:
  Catalyzer(std::unique_ptr<PaintingContext> painting_context);

  virtual ~Catalyzer() = default;

  inline PaintingContext* painting_context() { return painting_context_.get(); }

  inline void set_root(Element* root) { root_ = root; }
  inline Element* get_root() { return root_; }
  inline void set_air_root(AirElement* root) { air_root_ = root; }
  inline AirElement* get_air_root() { return air_root_; }
  void UpdateLayoutRecursively();
  void UpdateLayoutRecursivelyWithoutChange();

  BASE_EXPORT_FOR_DEVTOOL std::vector<float> getBoundingClientOrigin(
      Element* node);
  BASE_EXPORT_FOR_DEVTOOL std::vector<float> GetRectToWindow(Element* node);
  BASE_EXPORT_FOR_DEVTOOL std::vector<int> getVisibleOverlayView();
  BASE_EXPORT_FOR_DEVTOOL std::vector<float> getTransformValue(
      Element* node, std::vector<float> pad_border_margin_layout);
  BASE_EXPORT_FOR_DEVTOOL std::vector<float> getWindowSize(Element* node);

  std::vector<float> GetRectToLynxView(Element* node);
  std::vector<float> ScrollBy(int64_t id, float width, float height);
  void Invoke(int64_t id, const std::string& method, const lepus::Value& params,
              const std::function<void(int32_t code, const lepus::Value& data)>&
                  callback);
  BASE_EXPORT_FOR_DEVTOOL int GetCurrentIndex(Element* node);
  BASE_EXPORT_FOR_DEVTOOL bool IsViewVisible(Element* node);
  BASE_EXPORT_FOR_DEVTOOL int GetNodeForLocation(int x, int y);
  BASE_EXPORT_FOR_DEVTOOL void ScrollIntoView(Element* node);

 private:
  std::unique_ptr<PaintingContext> painting_context_;
  Element* root_ = nullptr;
  AirElement* air_root_ = nullptr;
  Catalyzer(const Catalyzer&) = delete;
  Catalyzer& operator=(const Catalyzer&) = delete;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_CATALYZER_H_
