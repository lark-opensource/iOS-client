// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_TYPES_H_
#define LYNX_TASM_RADON_RADON_TYPES_H_

#include <string>

namespace lynx {
namespace tasm {

enum RadonNodeType {
  kRadonUnknown = -1,
  kRadonNode = 0,
  kRadonComponent,
  kRadonPage,
  kRadonSlot,
  kRadonPlug,
  kRadonIfNode,
  kRadonForNode,
  kRadonListNode,
  kRadonBlock,
  kRadonDynamicComponent,
};

#ifdef ENABLE_TEST_DUMP
static const std::string RadonNodeTypeStrings[] = {
    "RadonUnknown",  "RadonNode",  "RadonComponent",        "RadonPage",
    "RadonSlot",     "RadonPlug",  "RadonIfNode",           "RadonForNode",
    "RadonListNode", "RadonBlock", "RadonDynamicComponent",
};
#endif

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_TYPES_H_
