// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SSR_BINARY_READER_H_
#define LYNX_SSR_SSR_BINARY_READER_H_

#include <string>
#include <vector>

#include "lepus/context_binary_reader.h"

namespace lynx {

namespace ssr {
bool DecodeSSRData(std::vector<uint8_t> ssr_byte_array, lepus::Value *output);
}

}  // namespace lynx
#endif  // LYNX_SSR_SSR_BINARY_READER_H_
