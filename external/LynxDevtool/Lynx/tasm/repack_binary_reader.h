// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPACK_BINARY_READER_H_
#define LYNX_TASM_REPACK_BINARY_READER_H_

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "lepus/binary_reader.h"
#include "tasm/compile_options.h"
#include "tasm/encoder.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace lepus {
class Context;
class InputStream;
}  // namespace lepus

namespace tasm {

class RepackBinaryReader : public lepus::BinaryReader {
 public:
  RepackBinaryReader(lepus::Context* context,
                     std::unique_ptr<lepus::InputStream> stream)
      : BinaryReader(std::move(stream)), context_(context) {}

  bool DecodeHeader();
  bool DecodeHeaderInfo();
  bool DecodeString();
  bool DecodeSuffix();
  bool DecodePageRoute(PageRoute& route);
  bool DecodeDynamicComponentRoute(DynamicComponentRoute& route);

  inline bool is_card() const { return is_card_; }
  inline size_t suffix_size() const { return suffix_size_; }
  inline size_t string_offset() const { return string_offset_; }
  inline size_t header_ext_info_offset() const {
    return header_ext_info_offset_;
  }
  inline size_t header_ext_info_size() const { return header_ext_info_size_; }
  inline EncodeSSRError error_code() const { return error_code_; }
  inline lepus::Context* context() const { return context_; }
  inline const CompileOptions& compile_options() const {
    return compile_options_;
  }
  const std::map<uint8_t, Range>& offset_map() const {
    return type_offset_map_;
  }

 protected:
  template <typename T>
  void ReinterpretValue(T& tgt, std::vector<uint8_t> src);
  bool DecodeHeaderInfoField();

 private:
  size_t size() { return stream_->size(); }
  bool CheckLynxVersion(const std::string& binary_version);

 private:
  lepus::Context* context_;

  bool is_card_ = true;
  size_t suffix_size_ = 0;
  size_t string_offset_ = 0;
  size_t header_ext_info_offset_ = 0;
  size_t header_ext_info_size_ = 0;
  EncodeSSRError error_code_ = ERR_DECODE;
  CompileOptions compile_options_;
  std::map<uint8_t, Range> type_offset_map_;
  std::unordered_map<uint32_t, std::vector<uint8_t>> header_info_map_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REPACK_BINARY_READER_H_
