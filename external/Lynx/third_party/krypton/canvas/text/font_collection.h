// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXT_FONT_COLLECTION_H_
#define CANVAS_TEXT_FONT_COLLECTION_H_

#include <unordered_map>
#include <vector>

#include "canvas/text/typeface.h"

namespace lynx {
namespace canvas {
class FontCollection {
 public:
  class TypefaceObserver {
   public:
    virtual void OnTypeFaceAdded(Typeface *typeface) = 0;
  };
  FontCollection() = default;
  FontCollection(const FontCollection &) = delete;

  FontCollection &operator=(const FontCollection &) = delete;

  void AddNormalTypeface(std::string name,
                         std::unique_ptr<DataHolder> font_data);

  Typeface *GetTypeface(const std::string &name) const;

  void AddTypefaceObserver(TypefaceObserver *typeface_observer);
  void RemoveTypefaceObserver(TypefaceObserver *typeface_observer);

 private:
  std::unordered_map<std::string, std::unique_ptr<Typeface>> typeface_map_;
  std::vector<TypefaceObserver *> observer_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_TEXT_FONT_COLLECTION_H_
