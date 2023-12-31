// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_SHEET_H_
#define LYNX_CSS_CSS_SHEET_H_

#include <memory>
#include <string>

#include "lepus/lepus_string.h"

namespace lynx {
namespace tasm {

class CSSSheet {
 public:
  enum SheetType {
    CLASS_SELECT = 1,
    ID_SELECT = 1 << 1,
    NAME_SELECT = 1 << 2,
    AFTER_SELECT = 1 << 3,
    BEFORE_SELECT = 1 << 4,
    NOT_SELECT = 1 << 5,
    PLACEHOLDER_SELECT = 1 << 6,
    ALL_SELECT = 1 << 7,
    FIRST_CHILD_SELECT = 1 << 8,
    LAST_CHILD_SELECT = 1 << 9,
    PSEUDO_FOCUS_SELECT = 1 << 10,
    SELECTION_SELECT = 1 << 11,
    PSEUDO_ACTIVE_SELECT = 1 << 12,
    PSEUDO_HOVER_SELECT = 1 << 13,
  };

  CSSSheet(const std::string& str);
  ~CSSSheet() {}

  int GetType() { return type_; }

  const lepus::String& GetSelector() { return selector_; }

  const lepus::String& GetName() { return name_; }

  void SetParent(std::shared_ptr<CSSSheet> ptr) { parent_ = ptr.get(); }

  CSSSheet* GetParent() { return parent_; }

  bool IsTouchPseudo() const;

 private:
  // for desirialize
  CSSSheet() {}
  friend class TemplateBinaryWriter;
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class LynxBinaryBaseCSSReader;

  void ConfirmType();

  int type_;
  // 单一规则，如.info、view
  lepus::String selector_;

  // 去除规则后的字符，例如view、info
  lepus::String name_;
  // std::shared_ptr<CSSSheet> parent_;
  CSSSheet* parent_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_SHEET_H_
