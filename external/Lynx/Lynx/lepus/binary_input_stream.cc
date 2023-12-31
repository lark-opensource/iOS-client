// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus/binary_input_stream.h"

namespace lynx {
namespace lepus {

bool ByteArrayInputStream::ReadFromFile(const char* file) {
  FILE* pf = fopen(file, "r");
  if (pf == nullptr) {
    return false;
  }

  fseek(pf, 0, SEEK_END);
  long size = ftell(pf);
  buf_->data.resize(size);
  uint8_t* text = &buf_->data[0];
  if (text != nullptr) {
    rewind(pf);
    fread(text, sizeof(char), size, pf);
    return true;
  }

  return false;
}

#undef LEB128_LOOP_UNTIL

#define BYTE_AT(type, i, shift) \
  ((static_cast<type>(cursor()[i]) & 0x7f) << (shift))

#define LEB128_1(type) (BYTE_AT(type, 0, 0))
#define LEB128_2(type) (BYTE_AT(type, 1, 7) | LEB128_1(type))
#define LEB128_3(type) (BYTE_AT(type, 2, 14) | LEB128_2(type))
#define LEB128_4(type) (BYTE_AT(type, 3, 21) | LEB128_3(type))
#define LEB128_5(type) (BYTE_AT(type, 4, 28) | LEB128_4(type))
#define LEB128_6(type) (BYTE_AT(type, 5, 35) | LEB128_5(type))
#define LEB128_7(type) (BYTE_AT(type, 6, 42) | LEB128_6(type))
#define LEB128_8(type) (BYTE_AT(type, 7, 49) | LEB128_7(type))
#define LEB128_9(type) (BYTE_AT(type, 8, 56) | LEB128_8(type))
#define LEB128_10(type) (BYTE_AT(type, 9, 63) | LEB128_9(type))

#define SHIFT_AMOUNT(type, sign_bit) (sizeof(type) * 8 - 1 - (sign_bit))
#define SIGN_EXTEND(type, value, sign_bit)                       \
  (static_cast<type>((value) << SHIFT_AMOUNT(type, sign_bit)) >> \
   SHIFT_AMOUNT(type, sign_bit))

size_t InputStream::ReadU32Leb128(uint32_t* out_value) {
  if (!CheckSize(1)) {
    return 0;
  }

  if (cursor() < end() && (cursor()[0] & 0x80) == 0) {
    *out_value = LEB128_1(uint32_t);
    offset_ += 1;
    return 1;
  } else if (cursor() + 1 < end() && (cursor()[1] & 0x80) == 0) {
    *out_value = LEB128_2(uint32_t);
    offset_ += 2;
    return 2;
  } else if (cursor() + 2 < end() && (cursor()[2] & 0x80) == 0) {
    *out_value = LEB128_3(uint32_t);
    offset_ += 3;
    return 3;
  } else if (cursor() + 3 < end() && (cursor()[3] & 0x80) == 0) {
    *out_value = LEB128_4(uint32_t);
    offset_ += 4;
    return 4;
  } else if (cursor() + 4 < end() && (cursor()[4] & 0x80) == 0) {
    // The top bits set represent values > 32 bits.
    if (cursor()[4] & 0xf0) {
      return 0;
    }
    *out_value = LEB128_5(uint32_t);
    offset_ += 5;
    return 5;
  } else {
    // past the end().
    *out_value = 0;
    return 0;
  }
}

size_t InputStream::ReadS32Leb128(int32_t* out_value) {
  if (!CheckSize(1)) {
    return 0;
  }

  if (cursor() < end() && (cursor()[0] & 0x80) == 0) {
    uint32_t result = LEB128_1(uint32_t);
    *out_value = SIGN_EXTEND(int32_t, result, 6);
    offset_ += 1;
    return 1;
  } else if (cursor() + 1 < end() && (cursor()[1] & 0x80) == 0) {
    uint32_t result = LEB128_2(uint32_t);
    *out_value = SIGN_EXTEND(int32_t, result, 13);
    offset_ += 2;
    return 2;
  } else if (cursor() + 2 < end() && (cursor()[2] & 0x80) == 0) {
    uint32_t result = LEB128_3(uint32_t);
    *out_value = SIGN_EXTEND(int32_t, result, 20);
    offset_ += 3;
    return 3;
  } else if (cursor() + 3 < end() && (cursor()[3] & 0x80) == 0) {
    uint32_t result = LEB128_4(uint32_t);
    *out_value = SIGN_EXTEND(int32_t, result, 27);
    offset_ += 4;
    return 4;
  } else if (cursor() + 4 < end() && (cursor()[4] & 0x80) == 0) {
    // The top bits should be a sign-extension of the sign bit.
    bool sign_bit_set = (cursor()[4] & 0x8);
    int top_bits = cursor()[4] & 0xf0;
    if ((sign_bit_set && top_bits != 0x70) ||
        (!sign_bit_set && top_bits != 0)) {
      return 0;
    }
    uint32_t result = LEB128_5(uint32_t);
    *out_value = result;
    offset_ += 5;
    return 5;
  } else {
    // Past the end.
    return 0;
  }
}

size_t InputStream::ReadU64Leb128(uint64_t* out_value) {
  if (!CheckSize(1)) {
    return 0;
  }

  if (cursor() < end() && (cursor()[0] & 0x80) == 0) {
    *out_value = LEB128_1(uint64_t);
    offset_ += 1;
    return 1;
  } else if (cursor() + 1 < end() && (cursor()[1] & 0x80) == 0) {
    *out_value = LEB128_2(uint64_t);
    offset_ += 2;
    return 2;
  } else if (cursor() + 2 < end() && (cursor()[2] & 0x80) == 0) {
    *out_value = LEB128_3(uint64_t);
    offset_ += 3;
    return 3;
  } else if (cursor() + 3 < end() && (cursor()[3] & 0x80) == 0) {
    *out_value = LEB128_4(uint64_t);
    offset_ += 4;
    return 4;
  } else if (cursor() + 4 < end() && (cursor()[4] & 0x80) == 0) {
    *out_value = LEB128_5(uint64_t);
    offset_ += 5;
    return 5;
  } else if (cursor() + 5 < end() && (cursor()[5] & 0x80) == 0) {
    *out_value = LEB128_6(uint64_t);
    offset_ += 6;
    return 6;
  } else if (cursor() + 6 < end() && (cursor()[6] & 0x80) == 0) {
    *out_value = LEB128_7(uint64_t);
    offset_ += 7;
    return 7;
  } else if (cursor() + 7 < end() && (cursor()[7] & 0x80) == 0) {
    *out_value = LEB128_8(uint64_t);
    offset_ += 8;
    return 8;
  } else if (cursor() + 8 < end() && (cursor()[8] & 0x80) == 0) {
    *out_value = LEB128_9(uint64_t);
    offset_ += 9;
    return 9;
  } else if (cursor() + 9 < end() && (cursor()[9] & 0x80) == 0) {
    // The top bits set represent values > 32 bits.
    if (cursor()[9] & 0xf0) {
      return 0;
    }
    *out_value = LEB128_10(uint64_t);
    offset_ += 10;
    return 10;
  } else {
    // past the end().
    *out_value = 0;
    return 0;
  }
  return 0;
}

}  // namespace lepus
}  // namespace lynx
