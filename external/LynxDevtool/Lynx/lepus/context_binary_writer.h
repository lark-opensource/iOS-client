// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_CONTEXT_BINARY_WRITER_H_
#define LYNX_LEPUS_CONTEXT_BINARY_WRITER_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "css/css_value.h"
#include "lepus/binary_writer.h"
#include "lepus/function.h"
#include "tasm/compile_options.h"
#include "tasm/generator/version.h"

namespace lynx {
namespace lepus {

class Closure;
class Dictionary;
class CArray;
class CDate;
class Value;
class Function;
class Context;

class ContextBinaryWriter : public BinaryWriter {
 public:
  ContextBinaryWriter(Context* context,
                      const tasm::CompileOptions& compile_options = {},
                      const lepus::Value& trial_options = lepus::Value{},
                      bool enableDebugInfo = false);
  virtual ~ContextBinaryWriter();
  void encode();

  // protected:
  void SerializeGlobal();

  void SetFunctionIgnoreList(const std::vector<std::string>& ignored_funcs);
  void SerializeFunction(lynx::base::scoped_refptr<Function> function);
  void EncodeExpr();

  void SerializeTopVariables();
  void EncodeClosure(const base::scoped_refptr<Closure>& value);
  void EncodeTable(lynx::base::scoped_refptr<Dictionary> dictionary,
                   bool is_header = false);
  void EncodeArray(base::scoped_refptr<CArray> ary);
  void EncodeDate(base::scoped_refptr<CDate> date);
  void EncodeUtf8Str(const char* value, size_t length);
  void EncodeUtf8Str(const char* value);
  void EncodeValue(const Value* value, bool is_header = false);
  void EncodeCSSValue(const tasm::CSSValue& css_value);
  void EncodeCSSValue(const tasm::CSSValue& css_value, bool enable_css_parser,
                      bool enable_css_variable);

  inline Context* context() { return context_; }
  bool NeedLepusDebugInfo() { return need_lepus_debug_info_; }
  void GetLepusNGDebugInfo();

 protected:
  Context* context_;
  const tasm::CompileOptions compile_options_;
  const lepus_value trial_options_;
  bool need_lepus_debug_info_;
  // for serialize/deserialize
  std::unordered_map<lynx::base::scoped_refptr<Function>, int> func_map;
  std::vector<lynx::base::scoped_refptr<Function>> func_vec;

  std::string lepusNG_source_code_;
  int32_t end_line_num_;
  LEPUSValue top_level_function_;

  // functions inside the list will not be serialized (reduce output file size)
  std::vector<std::string> ignored_funcs_;

 private:
  // if target_sdk_version > FEATURE_CONTROL_VERSION;
  bool feature_control_variables_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_CONTEXT_BINARY_WRITER_H_
