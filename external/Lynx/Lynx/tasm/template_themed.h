// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TEMPLATE_THEMED_H_
#define LYNX_TASM_TEMPLATE_THEMED_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "lepus/value.h"

namespace lynx {
namespace tasm {

typedef std::unordered_map<std::string, std::string> ThemedRes;
typedef std::unordered_map<std::string, std::shared_ptr<ThemedRes>> ThemeResMap;

struct Themed {
  typedef struct _TransMap {
    std::string name_, default_, fallback_;
    ThemeResMap resMap_;
    std::shared_ptr<ThemedRes> currentRes_, curFallbackRes_;
  } TransMap;
  using PageTransMaps =
      std::unordered_map<uint32_t, std::shared_ptr<std::vector<TransMap>>>;
  PageTransMaps pageTransMaps;
  std::shared_ptr<std::vector<TransMap>> currentTransMap;
  bool hasTransConfig = false, hasAnyCurRes = false, hasAnyFallback = false;

  void reset() {
    hasTransConfig = hasAnyCurRes = hasAnyFallback = false;
    pageTransMaps.clear();
    currentTransMap = nullptr;
  }
};

struct ThemedTrans {
  ThemeResMap fileMap_;
  typedef struct _TransMap {
    ThemeResMap pathMap_;
    ThemedRes default_, fallback_;
    std::vector<std::string> priority_;
  } TransMap;
  std::unordered_map<uint32_t, std::shared_ptr<TransMap>> pageTransMap_;
  friend class TemplateBinaryWriter;
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_THEMED_H_
