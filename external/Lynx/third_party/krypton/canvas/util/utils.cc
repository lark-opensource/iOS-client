// Copyright 2021 The Lynx Authors. All rights reserved.

#include "utils.h"

namespace lynx {
namespace canvas {
static constexpr char kPadding = '=';
/* clang-format off */
static const signed char base64de[] = {
        /* '+', ',', '-', '.', '/', '0', '1', '2', */
        62, -1, -1, -1, 63, 52, 53, 54,

        /* '3', '4', '5', '6', '7', '8', '9', ':', */
        55, 56, 57, 58, 59, 60, 61, -1,

        /* ';', '<', '=', '>', '?', '@', 'A', 'B', */
        -1, -1, 0, -1, -1, -1, 0, 1,

        /* 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', */
        2, 3, 4, 5, 6, 7, 8, 9,

        /* 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', */
        10, 11, 12, 13, 14, 15, 16, 17,

        /* 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', */
        18, 19, 20, 21, 22, 23, 24, 25,

        /* '[', '\', ']', '^', '_', '`', 'a', 'b', */
        -1, -1, -1, -1, -1, -1, 26, 27,

        /* 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', */
        28, 29, 30, 31, 32, 33, 34, 35,

        /* 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', */
        36, 37, 38, 39, 40, 41, 42, 43,

        /* 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', */
        44, 45, 46, 47, 48, 49, 50, 51,
};
/* clang-format on */

// Returns -1 in case of failure.
int Base64::decode(const char *str, uint32_t len, uint8_t *ret,
                   uint32_t dst_size) {
  if (!len || str == nullptr) {
    return -1;
  }
  const size_t min_dst_size = dec_size(len);
  if (dst_size < min_dst_size) {
    return -1;
  }
  size_t wr_size = 0;
#pragma omp parallel for
  for (int j = 0; j < len; j += 4) {
    uint32_t val =
        (base64de[str[j] - '+'] << 18) | (base64de[str[j + 1] - '+'] << 12) |
        (base64de[str[j + 2] - '+'] << 6) | (base64de[str[j + 3] - '+']);
    wr_size = (j >> 2) * 3;
    ret[wr_size] = val >> 16;
    ret[wr_size + 1] = val >> 8;
    ret[wr_size + 2] = val;
  }
  DCHECK(wr_size <= dst_size);

  if (str[len - 1] == kPadding) {
    wr_size--;
  } else if (str[len - 2] == kPadding) {
    wr_size -= 2;
  }
  return wr_size;
}

void Base64::encode(const uint8_t *bytes, uint32_t len, char *chars) {
  uint32_t end = len / 3;
  const char *b64_chars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
#pragma omp parallel for
  for (uint32_t i = 0; i < end; i++) {
    int j = i + (i << 1), k = i << 2;
    uint32_t three_bytes = bytes[j] << 16 | bytes[j + 1] << 8 | bytes[j + 2];
    chars[k] = b64_chars[three_bytes >> 18 & 63];
    chars[k + 1] = b64_chars[three_bytes >> 12 & 63];
    chars[k + 2] = b64_chars[three_bytes >> 6 & 63];
    chars[k + 3] = b64_chars[three_bytes & 63];
  }

  int loc = end << 2;
  end += end << 1;
  switch (len - end) {
    case 0:
      break;
    case 1: {
      uint32_t last = bytes[end] << 4;
      chars[loc++] = b64_chars[last >> 6 & 63];
      chars[loc++] = b64_chars[last & 63];
      chars[loc++] = '=';
      chars[loc++] = '=';
      break;
    }
    case 2: {
      uint32_t last = bytes[end] << 10 | bytes[end + 1] << 2;

      chars[loc++] = b64_chars[last >> 12 & 63];
      chars[loc++] = b64_chars[last >> 6 & 63];
      chars[loc++] = b64_chars[last & 63];
      chars[loc++] = '=';
      break;
    }
    default:
      break;
  }
  chars[loc] = 0;
}

namespace string_util {
uint32_t GetLongestValidSubStringLength(const std::u16string &str) {
  for (uint32_t i = 0; i < str.size(); ++i) {
    if (str[i] >= 0xD800 && str[i] <= 0xDBFF) {
      if (i + 1 < str.size() && str[i + 1] >= 0xDC00 && str[i + 1] <= 0xDFFF) {
        ++i;
        continue;
      } else {
        return i;
      }
    } else if (str[i] >= 0xDC00 && str[i] <= 0xDFFF) {
      return i;
    }
  }
  return static_cast<uint32_t>(str.size());
}
}  // namespace string_util

}  // namespace canvas
}  // namespace lynx
