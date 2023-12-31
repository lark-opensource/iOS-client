// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_BINARY_READER_H_
#define LYNX_LEPUS_BINARY_READER_H_

#include <stdlib.h>

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "lepus/binary_input_stream.h"

#define ERROR_UNLESS_CODE(expr, code, errorCode)               \
  do {                                                         \
    if (!(expr)) {                                             \
      PrintError("Function:%s, %d\n", __FUNCTION__, __LINE__); \
      code = errorCode;                                        \
      return false;                                            \
    }                                                          \
  } while (0)

#define ERROR_UNLESS(expr)                                     \
  do {                                                         \
    if (!(expr)) {                                             \
      PrintError("Function:%s, %d\n", __FUNCTION__, __LINE__); \
      return false;                                            \
    }                                                          \
  } while (0)

namespace lynx {
namespace lepus {

class BinaryReader {
 public:
  explicit BinaryReader(std::unique_ptr<InputStream> stream)
      : error_message_("UnKnow Decode Error \n"), stream_(std::move(stream)) {}

  bool ReadU8(uint8_t* out_value);
  bool ReadU32(uint32_t* out_value);
  bool ReadU32Leb128(uint32_t* out_value);
  bool ReadS32Leb128(int32_t* out_value);
  bool ReadU64Leb128(uint64_t* out_value);
  bool ReadD64Leb128(double* value);
  bool ReadStringDirectly(std::string* out_value);
  void PrintError(const char* format, const char* func, int line);
  bool CheckSize(int len, uint32_t maxOffset = 0);
  void Skip(uint32_t size);
  int Offset();

  bool ReadData(uint8_t* dst, int len) { return stream_->ReadData(dst, len); }

  std::string error_message_;

 protected:
  std::unique_ptr<InputStream> stream_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BINARY_READER_H_
