// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus/output_stream.h"

#include <cstring>
#include <string>

namespace lynx {
namespace lepus {

void OutputStream::WriteData(const uint8_t* src, size_t size,
                             const char* desc) {
  WriteImpl(src, offset_, size);
  offset_ += size;
}

void ByteArrayOutputStream::WriteImpl(const uint8_t* buffer, size_t offset,
                                      size_t length) {
  if (length == 0) {
    return;
  }
  size_t end = offset + length;
  if (end > buf_->data.size()) {
    buf_->data.resize(end);
  }
  uint8_t* dst = &buf_->data[offset];
  memcpy(dst, buffer, length);
}
const std::vector<uint8_t>& ByteArrayOutputStream::byte_array() {
  return buf_->data;
}

bool ByteArrayOutputStream::WriteToFile(const std::string& filename) {
  FILE* pf = fopen(filename.c_str(), "wb");
  if (pf == nullptr) {
    return false;
  }
  size_t size = buf_->size() + sizeof(uint32_t);
  (void)fwrite((uint8_t*)&size, sizeof(uint32_t), 1, pf);
  (void)fwrite(&buf_->data[0], buf_->size(), 1, pf);
  fclose(pf);

  return true;
}

void ByteArrayOutputStream::Move(uint32_t insert_pos, uint32_t start,
                                 uint32_t size) {
  OutputBuffer* new_buf = new OutputBuffer();
  new_buf->data.resize(buf_->size());

  uint8_t* dst_pos = &new_buf->data[0];
  const uint8_t* src_pos = &buf_->data[0];
  const size_t src_size = buf_->size();

  memcpy(dst_pos, src_pos, insert_pos);
  dst_pos += insert_pos;
  memcpy(dst_pos, src_pos + start, size);
  dst_pos += size;
  memcpy(dst_pos, src_pos + insert_pos, src_size - insert_pos - size);
  buf_.reset(new_buf);
}

#define MAX_U32_LEB128_BYTES 5
#define MAX_U64_LEB128_BYTES 10

#define LEB128_LOOP_UNTIL(end_cond) \
  do {                              \
    uint8_t byte = value & 0x7f;    \
    value >>= 7;                    \
    if (end_cond) {                 \
      data[length++] = byte;        \
      break;                        \
    } else {                        \
      data[length++] = byte | 0x80; \
    }                               \
  } while (1)

void OutputStream::WriteU32Leb128(uint32_t value) {
  uint8_t data[MAX_U32_LEB128_BYTES];
  size_t length = 0;
  LEB128_LOOP_UNTIL(value == 0);
  WriteData(data, length);
}

void OutputStream::WriteS32Leb128(int32_t value) {
  uint8_t data[MAX_U32_LEB128_BYTES];
  size_t length = 0;
  if (value < 0) {
    LEB128_LOOP_UNTIL(value == -1 && (byte & 0x40));
  } else {
    LEB128_LOOP_UNTIL(value == 0 && !(byte & 0x40));
  }

  WriteData(data, length);
}

void OutputStream::WriteU64Leb128(uint64_t value) {
  uint8_t data[MAX_U64_LEB128_BYTES];
  size_t length = 0;
  LEB128_LOOP_UNTIL(value == 0);
  WriteData(data, length);
}

void OutputStream::WriteD64Leb128(double value) {
  double local_value = value;
  uint64_t* p_uint_value = (uint64_t*)&local_value;
  uint64_t uint_value = *p_uint_value;
  WriteU64Leb128(uint_value);
}

size_t OutputStream::Offset() { return offset_; }
}  // namespace lepus
}  // namespace lynx
