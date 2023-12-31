// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_DATA_DISPATCHER_H_
#define LYNX_SHELL_LYNX_DATA_DISPATCHER_H_

#include "tasm/template_entry.h"

namespace lynx {
namespace shell {

class LynxDataDispatcher {
 public:
  LynxDataDispatcher() = default;
  virtual ~LynxDataDispatcher() = default;

  virtual void OnCardDecoded(tasm::TemplateBundle bundle,
                             const lepus::Value& global_props) = 0;
  virtual void OnComponentDecoded(tasm::TemplateBundle bundle) = 0;

  virtual void OnCardConfigDataChanged(const lepus::Value& data) = 0;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_DATA_DISPATCHER_H_
