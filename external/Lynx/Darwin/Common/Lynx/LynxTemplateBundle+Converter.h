// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_CONVERTER_H_
#define DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_CONVERTER_H_

#import "LynxTemplateBundle.h"
#include "tasm/binary_decoder/lynx_template_bundle.h"

std::shared_ptr<lynx::tasm::LynxTemplateBundle> LynxGetRawTemplateBundle(
    LynxTemplateBundle *bundle);

#endif  // DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_CONVERTER_H_
