#include "lepus/binary_reader.h"

#include <assert.h>
#include <base/log/logging.h>

#include "base/trace_event/trace_event.h"
#include "lepus/binary_input_stream.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace lepus {

bool BinaryReader::ReadU32(uint32_t* out_value) {
  ERROR_UNLESS(stream_->ReadUx<uint32_t>(out_value));
  return true;
}

bool BinaryReader::ReadU8(uint8_t* out_value) {
  ERROR_UNLESS(stream_->ReadUx<uint8_t>(out_value));
  return true;
}

bool BinaryReader::ReadU32Leb128(uint32_t* out_value) {
  ERROR_UNLESS(stream_->ReadU32Leb128(out_value));
  return true;
}

bool BinaryReader::ReadS32Leb128(int32_t* out_value) {
  ERROR_UNLESS(stream_->ReadS32Leb128(out_value));
  return true;
}

bool BinaryReader::ReadU64Leb128(uint64_t* out_value) {
  ERROR_UNLESS(stream_->ReadU64Leb128(out_value));
  return true;
}

bool BinaryReader::ReadD64Leb128(double* out_value) {
  uint64_t data = 0;
  ERROR_UNLESS(stream_->ReadU64Leb128(&data));
  *out_value = BitCast<double>(data);
  return true;
}

bool BinaryReader::ReadStringDirectly(std::string* out_value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ReadStringDirectly");
  uint32_t length = 0;
  ERROR_UNLESS(ReadU32Leb128(&length));
  ERROR_UNLESS(stream_->ReadString(*out_value, length));
  return true;
}

void BinaryReader::PrintError(const char* format, const char* func, int line) {
  char buffer[1024];
  snprintf(buffer, sizeof(buffer), format, func, line);
  printf(format, func, line);
  error_message_ = error_message_ + buffer;
  LOGE(buffer);
  // TODO ...
}

bool BinaryReader::CheckSize(int len, uint32_t maxOffset) {
  size_t curMax = stream_->size();
  if (maxOffset > 0 && maxOffset < curMax) {
    curMax = maxOffset;
  }
  if (stream_->offset() + len > curMax) {
    return false;
  }
  return true;
}

void BinaryReader::Skip(uint32_t size) {
  size_t offset = stream_->offset();
  stream_->Seek(offset + size);
}

int BinaryReader::Offset() { return static_cast<int>(stream_->offset()); }

}  // namespace lepus
}  // namespace lynx
