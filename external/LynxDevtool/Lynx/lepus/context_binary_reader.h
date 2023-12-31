// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_CONTEXT_BINARY_READER_H_
#define LYNX_LEPUS_CONTEXT_BINARY_READER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "config/config.h"
#include "css/css_value.h"
#include "lepus/base_binary_reader.h"
#include "lepus/binary_reader.h"
#include "lepus/lepus_string.h"
#include "lepus/regexp.h"
#include "tasm/compile_options.h"

namespace lynx {
namespace lepus {

class InputStream;
class Value;
class Function;
class Context;

class ContextBinaryReader : public BaseBinaryReader {
 public:
  ContextBinaryReader(Context* context, std::unique_ptr<InputStream> stream)
      : BaseBinaryReader(std::move(stream)), context_(context) {}
  bool Decode();

  inline const tasm::CompileOptions& compile_options() const {
    return compile_options_;
  }

  void SetCompileOptions(tasm::CompileOptions compile_options) {
    compile_options_ = compile_options;
  }

 protected:
  Context* context_;
  lepus::Value trial_options_;
  bool enable_css_variable_ = false;
  bool enable_css_parser_ = false;
  std::string absetting_disable_css_lazy_decode_;

  std::string version_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_CONTEXT_BINARY_READER_H_
