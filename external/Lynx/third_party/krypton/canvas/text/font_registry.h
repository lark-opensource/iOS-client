// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXT_FONT_REGISTRY_H_
#define CANVAS_TEXT_FONT_REGISTRY_H_

#include <list>
#include <map>
#include <mutex>
#include <string>

#include "canvas/base/log.h"
#include "canvas/util/string_utils.h"

namespace lynx {
namespace canvas {

class FontRegistry {
 public:
  static constexpr int DEFAULT_WEITHT = 400, DEFAULT_STYLE = 0;
  struct Item {
    std::string name, url;
    int weight = DEFAULT_WEITHT;
    int style = DEFAULT_STYLE;
    int Diff(int w, int s) const {
      return abs(weight - w) + abs(style - s) * 1e4;
    }
  };

  static FontRegistry& Instance();

  bool Add(const char* name, const char* url, int weight = DEFAULT_WEITHT,
           int style = DEFAULT_STYLE);

  std::string GetFontUrl(const std::string& name, int weight = DEFAULT_WEITHT,
                         int style = DEFAULT_STYLE);

  virtual bool GetAssetData(const std::string& path, uint8_t*& out,
                            size_t& out_size);

  virtual void OnFirstUseComplexLayout(){};

 protected:
  FontRegistry() = default;
  FontRegistry(const FontRegistry&) = delete;

 private:
  std::map<std::string, std::list<Item>> items_;
  std::mutex mutex_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_TEXT_FONT_REGISTRY_H_
