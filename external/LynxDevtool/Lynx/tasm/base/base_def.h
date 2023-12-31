// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_BASE_BASE_DEF_H_
#define LYNX_TASM_BASE_BASE_DEF_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "config/config.h"
#include "lepus/value-inl.h"
#include "tasm/react/event.h"

namespace lynx {
namespace tasm {

#ifndef LYNX_TASM_BASE_BASE_INNER_DEF_H_
#define LYNX_TASM_BASE_BASE_INNER_DEF_H_

using ClassList = std::vector<lepus::String>;
using IsDynamic = bool;
using AttrMap =
    std::unordered_map<lepus::String, std::pair<lepus::Value, IsDynamic>>;
using DataMap = std::unordered_map<lepus::String, lepus::Value>;
using EventMap =
    std::unordered_map<lepus::String, std::unique_ptr<EventHandler>>;
using AttrUMap = std::unordered_map<lepus::String, lepus::Value>;

static constexpr const char* kListNodeTag = "list";
static constexpr const char* kGlobalBind = "global-bindEvent";
static constexpr const char* kSystemInfo = "SystemInfo";
static constexpr const char* kGlobalPropsKey = "__globalProps";

// invalid element impl id
static constexpr int32_t kInvalidImplId = 0;

// initial element impl id
static constexpr int32_t kInitialImplId = 10;

using PseudoState = uint32_t;
static constexpr PseudoState kPseudoStateNone = 0;
static constexpr PseudoState kPseudoStateHover = 1;
static constexpr PseudoState kPseudoStateHoverTransition = 1 << 1;
static constexpr PseudoState kPseudoStateActive = 1 << 3;
static constexpr PseudoState kPseudoStateActiveTransition = 1 << 4;
static constexpr PseudoState kPseudoStateFocus = 1 << 6;
static constexpr PseudoState kPseudoStateFocusTransition = 1 << 7;
static constexpr PseudoState kPseudoStatePlaceHolder = 1 << 8;
static constexpr PseudoState kPseudoStateBefore = 1 << 9;
static constexpr PseudoState kPseudoStateAfter = 1 << 10;
static constexpr PseudoState kPseudoStateSelection = 1 << 11;

// Enlarge `PseudoState` if has more states...

#endif  // LYNX_TASM_BASE_BASE_INNER_DEF_H_

/*
To make the code more concise, add the following macro for inspector. Only exec
expression when ENABLE_INSPECTOR == 1. For example, the following code
```
#if ENABLE_INSPECTOR
if (GetDevtoolFlag() && GetRadonPlug()) {
    create_plug_element_ = true;
}
#endif
```
can be refactored as

```
EXEC_EXPR_FOR_INSPECTOR(
    if (GetDevtoolFlag() && GetRadonPlug()) {
        create_plug_element_ = true;
    }
);
```
*/
#if ENABLE_INSPECTOR
#define EXEC_EXPR_FOR_INSPECTOR(expr) \
  do {                                \
    expr;                             \
  } while (0)
#else
#define EXEC_EXPR_FOR_INSPECTOR(expr)
#endif  // ENABLE_INSPECTOR

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BASE_BASE_DEF_H_
