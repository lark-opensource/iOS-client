// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPACK_BINARY_WRITER_H_
#define LYNX_TASM_REPACK_BINARY_WRITER_H_

#include <map>
#include <vector>

#include "lepus/context_binary_writer.h"
#include "tasm/header_ext_info.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

class RepackBinaryWriter : public lepus::ContextBinaryWriter {
 public:
  RepackBinaryWriter(lepus::Context* context,
                     const tasm::CompileOptions& compile_options = {})
      : ContextBinaryWriter(context, compile_options) {}

  const std::vector<uint8_t>& GetDataBuffer() { return data_vec_; }

  void EncodeString();
  void EncodePageRoute(const PageRoute& route);
  void EncodeDynamicComponentRoute(const DynamicComponentRoute& route);
  void EncodeValue(const lepus::Value* value);
  void EncodeHeaderInfo(const CompileOptions& compile_options);

  void AssembleNewTemplate(const uint8_t* ptr, size_t buf_len,
                           size_t suffix_size, size_t string_offset,
                           std::map<uint8_t, Range>& map, bool is_card,
                           std::vector<uint8_t>& new_template);
  void AssembleTemplateWithNewHeaderInfo(const uint8_t* ptr, size_t buf_len,
                                         size_t header_ext_info_offset,
                                         size_t header_ext_info_size,
                                         std::vector<uint8_t>& new_template);

 protected:
  void EncodeHeaderInfoField(
      const HeaderExtInfo::HeaderExtInfoField& header_info_field);

 private:
  std::vector<uint8_t> string_count_vec_;
  std::vector<uint8_t> string_vec_;
  std::vector<uint8_t> route_vec_;
  std::vector<uint8_t> data_vec_;
  std::vector<uint8_t> header_ext_info_vec_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REPACK_BINARY_WRITER_H_
