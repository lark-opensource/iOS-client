// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_VALUE_CONVERT_H_
#define LYNX_JSBRIDGE_RENDERKIT_VALUE_CONVERT_H_

#include "jsbridge/jsi/jsi.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {
std::optional<EncodableValue> Convert(piper::Runtime &rt,
                                      const piper::Value &value);

std::optional<piper::Value> Convert(piper::Runtime &rt,
                                    const EncodableValue &value);

std::optional<piper::Array> ConvertEncodableList(
    piper::Runtime &rt, const EncodableList &encodable_list);
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_VALUE_CONVERT_H_
