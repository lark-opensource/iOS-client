// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_LEPUS_LYNX_LEPUS_MODULE_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_LEPUS_LYNX_LEPUS_MODULE_DARWIN_H_

#include <string>

#import "LynxTemplateRender.h"
#include "lepus/value.h"

@protocol TemplateRenderCallbackProtocol;

namespace lynx {
namespace piper {

extern lepus::Value TriggerLepusMethod(const std::string& js_method_name, const lepus::Value& args,
                                       id<TemplateRenderCallbackProtocol> render);

void TriggerLepusMethodAsync(const std::string& js_method_name, const lepus::Value& args,
                             id<TemplateRenderCallbackProtocol> render);
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_IOS_LEPUS_LYNX_LEPUS_MODULE_DARWIN_H_
