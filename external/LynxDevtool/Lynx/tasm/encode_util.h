// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_ENCODE_UTIL_H_
#define LYNX_TASM_ENCODE_UTIL_H_

#include <memory>
#include <string>
#include <vector>

#include "lepus/value.h"
#include "tasm/encoder.h"
#include "tasm/generator/ttml_holder.h"
#include "tasm/template_binary.h"
#include "third_party/rapidjson/document.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "LynxDevtool/jsbridge/js_debug/lepusng/interface.h"
#include "lepus/quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {
class Function;
}
namespace tasm {
class SourceGenerator;
}
}  // namespace lynx

namespace lynx {
namespace tasm {

typedef lynx::base::scoped_refptr<lynx::lepus::Function> LepusFunction;

typedef struct LepusNGDebugInfo {
  std::string source_code;
  int32_t end_line_num;
  LEPUSValue top_level_function;
} LepusNGDebugInfo;

struct LepusDebugInfo {
  std::vector<LepusFunction> lepus_funcs_{};
  LepusNGDebugInfo debug_info_{"", -1, LEPUS_UNDEFINED};
};

struct BufferPool {
  std::vector<std::vector<uint8_t>> buffers;
};

void GetScopeInfo(lynx::lepus::Value& scopes, rapidjson::Value& function_scope,
                  rapidjson::Document::AllocatorType& allocator);

void GetLineColInfo(const LepusFunction& current_func,
                    rapidjson::Value& function,
                    rapidjson::Document::AllocatorType& allocator);

void GetChildFunctionInfo(const LepusFunction& current_func,
                          rapidjson::Value& function,
                          rapidjson::Document::AllocatorType& allocator);

void GetDebugInfo(const LepusNGDebugInfo debug_info,
                  rapidjson::Value& template_debug_data,
                  rapidjson::Document::AllocatorType& allocator);

void GetDebugInfo(const std::vector<LepusFunction>& funcs,
                  rapidjson::Value& template_debug_data,
                  rapidjson::Document::AllocatorType& allocator);

void CheckPackageInstance(const PackageInstanceType inst_type,
                          rapidjson::Document& document, std::string& error);

std::string MakeSuccessResult();
std::string MakeErrorResult(const char* errorMessage, const char* file,
                            const char* location);

std::string MakeRepackBufferResult(std::vector<uint8_t>&& data,
                                   BufferPool* pool);

lynx::tasm::EncodeResult CreateSuccessResult(
    const std::vector<uint8_t>& buffer, const std::string& code,
    std::shared_ptr<lepus::Context> context = nullptr,
    LepusDebugInfo info = LepusDebugInfo(),
    const std::string& section_size = "");
lynx::tasm::EncodeResult CreateErrorResult(const std::string& error_msg);

lynx::tasm::EncodeResult CreateSSRSuccessResult(
    const std::vector<uint8_t>& buffer);
lynx::tasm::EncodeResult CreateSSRErrorResult(int status,
                                              const std::string& error_msg);

std::string BinarySectionTypeToString(BinarySection section);

bool writefile(const std::string& filename, const std::string& src);

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_ENCODE_UTIL_H_
