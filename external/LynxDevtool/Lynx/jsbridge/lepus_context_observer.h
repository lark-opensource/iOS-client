// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_LEPUS_CONTEXT_OBSERVER_H_
#define LYNX_JSBRIDGE_LEPUS_CONTEXT_OBSERVER_H_

#include <memory>
#include <string>

namespace lynx {
namespace tasm {
class LepusContextObserver {
 public:
  LepusContextObserver() = default;
  virtual ~LepusContextObserver() = default;

  virtual intptr_t CreateJavascriptDebugger(const std::string& url) = 0;
  virtual void OnConsoleMessage(const std::string& level,
                                const std::string& msg) = 0;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_LEPUS_CONTEXT_OBSERVER_H_
