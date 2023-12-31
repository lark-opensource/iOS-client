// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/util/nanovg_util.h"

#include <errno.h>

#include <cmath>
#include <sstream>

#include "base/compiler_specific.h"
#include "base/string/string_number_convert.h"

namespace lynx {
namespace canvas {

class HexColorParser {
 public:
  HexColorParser(const char* s, const char* e) : s_(s), e_(e), len_(e - s) {}

  bool Parse(nanovg::NVGcolor& result) {
    int old_error = errno;
    errno = 0;
    char* endptr = nullptr;
    int64_t i = strtoll(s_ + 1, &endptr, 16);
    bool valid = (errno == 0 && endptr == e_);
    if (errno == 0) errno = old_error;
    if (!valid) {
      return false;
    }
    iv_ = i;
    return GetColor(result);
  }

 private:
  bool GetColor(nanovg::NVGcolor& result) {
    switch (len_) {
      case 4:
        if (iv_ >= 0 && iv_ <= 0xfff) {
          result = nanovg::nvgRGB(
              static_cast<unsigned char>(((iv_ & 0xf00) >> 4) |
                                         ((iv_ & 0xf00) >> 8)),
              static_cast<unsigned char>((iv_ & 0xf0) | ((iv_ & 0xf0) >> 4)),
              static_cast<unsigned char>((iv_ & 0xf) | ((iv_ & 0xf) << 4)));
          return true;
        }
        break;
      case 5:
        if (iv_ >= 0 && iv_ <= 0xffff) {
          result = nanovg::nvgRGBA(
              static_cast<unsigned char>(((iv_ & 0xf000) >> 8) |
                                         ((iv_ & 0xf000) >> 12)),
              static_cast<unsigned char>(((iv_ & 0xf00) >> 4) |
                                         ((iv_ & 0xf00) >> 8)),
              static_cast<unsigned char>((iv_ & 0xf0) | ((iv_ & 0xf0) >> 4)),
              static_cast<unsigned char>((iv_ & 0xf) | ((iv_ & 0xf) << 4)));
          return true;
        }
        break;
      case 7:
        if (iv_ >= 0 && iv_ <= 0xffffff) {
          result =
              nanovg::nvgRGB(static_cast<unsigned char>((iv_ & 0xff0000) >> 16),
                             static_cast<unsigned char>((iv_ & 0xff00) >> 8),
                             static_cast<unsigned char>(iv_ & 0xff));
          return true;
        }
        break;
      case 9:
        if (iv_ >= 0 && iv_ <= 0xffffffff) {
          result = nanovg::nvgRGBA(
              static_cast<unsigned char>((iv_ & 0xff000000) >> 24),
              static_cast<unsigned char>((iv_ & 0xff0000) >> 16),
              static_cast<unsigned char>((iv_ & 0xff00) >> 8),
              static_cast<unsigned char>(iv_ & 0xff));
          return true;
        }
        break;
      default:
        break;
    }
    return false;
  }
  const char *s_, *e_;
  int64_t iv_, len_;
};

class CommaArrayColorParser {
 public:
  CommaArrayColorParser(const char* s, const char* e)
      : s_(s), e_(e), max_count_(4), type_(COLOR_NONE) {}

  bool Parse(nanovg::NVGcolor& result) {
    if (!ParseType() || !ParseDoubleArray()) {
      return false;
    }

    if (type_ == COLOR_RGB || type_ == COLOR_RGBA) {
      if (type_ == COLOR_RGB &&
          (arr_[0].percent || arr_[1].percent || arr_[2].percent)) {
        return false;
      }
      result = nanovg::nvgTransRGBAf(
          nanovg::nvgRGB(arr_[0].ClampByte(), arr_[1].ClampByte(),
                         arr_[2].ClampByte()),
          arr_[3].ClampFloat());
    } else {
      if (arr_[0].percent || !arr_[1].percent || !arr_[2].percent) {
        return false;
      }
      auto css_color = tasm::CSSColor::CreateFromHSLA(
          arr_[0].val, arr_[1].ClampFloat() * 100, arr_[2].ClampFloat() * 100,
          arr_[3].ClampFloat());
      result = nanovg::nvgTransRGBAf(
          nanovg::nvgRGB(css_color.r_, css_color.g_, css_color.b_),
          css_color.a_);
    }
    return true;
  }

 private:
  const char *s_, *e_;
  uint8_t min_count_;
  const uint8_t max_count_;
  enum ColorType {
    COLOR_NONE = 0,
    COLOR_RGB,
    COLOR_RGBA,
    COLOR_HSL,
    COLOR_HSLA
  } type_;
  struct DoubleData {
    double val;
    bool percent;
    unsigned char ClampByte() {
      double tmp = round(percent ? (val / 100.0f * 255.0f) : val);
      return tmp < 0 ? 0 : tmp > 255 ? 255 : tmp;
    }
    float ClampFloat() {
      double tmp = percent ? (val / 100.0f) : val;
      return tmp < 0 ? 0 : tmp > 1 ? 1 : tmp;
    }
  } arr_[4];

  bool ParseType() {
    --e_;  // remove )
    if (strncasecmp(s_, "rgb(", 4) == 0) {
      type_ = COLOR_RGB;
      min_count_ = 3;
      s_ += 4;
    } else if (strncasecmp(s_, "rgba(", 5) == 0) {
      type_ = COLOR_RGBA;
      min_count_ = 4;
      s_ += 5;
    } else if (strncasecmp(s_, "hsl(", 4) == 0) {
      type_ = COLOR_HSL;
      min_count_ = 3;
      s_ += 4;
    } else if (strncasecmp(s_, "hsla(", 5) == 0) {
      type_ = COLOR_HSLA;
      min_count_ = 4;
      s_ += 5;
    } else {
      return false;
    }
    return true;
  }

  bool ParseDoubleIgnoreSpace(const char* s, const char* e,
                              DoubleData& output) {
    while (isspace(*s)) ++s;
    while (e > s && isspace(*(e - 1))) {
      --e;
    }
    bool percent = false;
    if (e > s && *(e - 1) == '%') {
      percent = true;
      --e;
    }
    if (e <= s) return false;
    int old_error = errno;
    errno = 0;
    char* endptr = nullptr;
    double d = strtod(s, &endptr);
    bool valid = (errno == 0 && endptr == e);
    if (errno == 0) errno = old_error;
    if (!valid || std::isnan(d) || std::isinf(d)) {
      return false;
    }
    output.val = d;
    output.percent = percent;
    return true;
  }

  bool ParseDoubleArray() {
    uint8_t i = 0;
    const char* sep = strchr(s_, ',');
    if (sep == nullptr) {
      sep = e_;
    }
    while (s_ < sep) {
      if (i >= max_count_) {
        return false;
      }
      if (!ParseDoubleIgnoreSpace(s_, sep, arr_[i])) {
        return false;
      }
      ++i;
      s_ = sep + 1;
      sep = strchr(s_, ',');
      if (sep == nullptr) {
        sep = e_;
      }
    }

    if (i < 4) {
      // set alpha to 1
      auto& last = arr_[3];
      last.val = 1;
      last.percent = 0;
    }
    return i >= min_count_;
  }
};

class NamedColorParser {
 public:
  NamedColorParser(const char* s, const char* e) : str_(s, e - s) {
    std::transform(str_.begin(), str_.end(), str_.begin(), ::tolower);
  }

  bool Parse(nanovg::NVGcolor& result) {
    tasm::CSSColor color;
    if (!tasm::CSSColor::ParseNamedColor(str_, color)) {
      return false;
    }
    result = nanovg::nvgTransRGBAf(nanovg::nvgRGB(color.r_, color.g_, color.b_),
                                   color.a_);
    return true;
  }

 private:
  std::string str_;
};

bool ParseColorString(const std::string& color, nanovg::NVGcolor& result) {
  if (color.empty()) {
    return false;
  }
  const char* s = color.c_str();
  const char* e = s + color.length();
  while (isspace(*s)) ++s;
  while (e > s && isspace(*(e - 1))) {
    --e;
  }
  if (e == s) {
    return false;
  }

  if (*s == '#') {
    return HexColorParser(s, e).Parse(result);
  } else if (*(e - 1) == ')') {
    return CommaArrayColorParser(s, e).Parse(result);
  } else {
    return NamedColorParser(s, e).Parse(result);
  }
}

std::string SerializeNVGcolor(nanovg::NVGcolor color) {
  unsigned int r = color.r * 255;
  unsigned int g = color.g * 255;
  unsigned int b = color.b * 255;
  unsigned int a = color.a * 255;
  if (a == 255) {
    char buff[10];
    snprintf(buff, sizeof(buff), "#%02x%02x%02x", r, g, b);
    return std::string(buff);
  }

  std::ostringstream string_stream;
  string_stream << "rgba(" << r << ", " << g << ", " << b << ", " << color.a
                << ")";

  return string_stream.str();
}

}  // namespace canvas
}  // namespace lynx
