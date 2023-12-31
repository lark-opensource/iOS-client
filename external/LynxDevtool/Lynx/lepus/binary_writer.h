// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_BINARY_WRITER_H_
#define LYNX_LEPUS_BINARY_WRITER_H_

#include <stdlib.h>

#include <cstdint>
#include <map>
#include <memory>
#include <vector>

#include "lepus/output_stream.h"

namespace lynx {
namespace lepus {

class BinaryWriter {
 public:
  BinaryWriter() { stream_.reset(new ByteArrayOutputStream()); }
  virtual ~BinaryWriter() {}

  void WriteU8(uint8_t value);
  void WriteByte(uint8_t value);
  void WriteU32(uint32_t value);
  void WriteU32Leb128(uint32_t value);
  void WriteS32Leb128(int32_t value);
  void WriteU64Leb128(uint64_t value);
  void WriteD64Leb128(double value);
  void WriteStringDirectly(const char* str);

  void Move(uint32_t insert_pos, uint32_t start, uint32_t size);
  int Offset();

  const OutputStream* stream() const { return stream_.get(); }

  void WriteData(const uint8_t* src, size_t size, const char* desc) {
    stream_->WriteData(src, size, desc);
  }

 protected:
  std::unique_ptr<OutputStream> stream_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BINARY_WRITER_H_
