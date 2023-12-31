// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_FACTORY_H_
#define LYNX_TASM_AIR_AIR_FACTORY_H_

#include <memory>
#include <unordered_map>

namespace lynx {
namespace tasm {
class AirElement;
using AirPtrLookUpMap = std::unordered_map<AirElement*, AirElement*>;

namespace air_factory {
std::shared_ptr<AirElement> Copy(const AirElement& node, AirPtrLookUpMap& map);
std::shared_ptr<AirElement> Copy(const AirElement& node);
}  // namespace air_factory
}  // namespace tasm
}  // namespace lynx

#endif  //  LYNX_TASM_AIR_AIR_FACTORY_H_
