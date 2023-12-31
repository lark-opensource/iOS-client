// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_RICHTEXT_RICH_TEXT_NODE_H_
#define LYNX_RICHTEXT_RICH_TEXT_NODE_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Lynx/tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {

class RichTextNode {
 public:
  RichTextNode(const char *name);
  RichTextNode(std::string name, std::string content);
  RichTextNode(std::vector<std::shared_ptr<RichTextNode>> children);

  ~RichTextNode() = default;

  void SetParent(RichTextNode *parent) { parent_ = parent; }

  RichTextNode *GetParent() const { return parent_; }

  void SetProps(const char *key, lepus::Value const &value);

  void AddChild(std::shared_ptr<RichTextNode> child) {
    children_.emplace_back(std::move(child));
  }

  std::string GetTagName() const { return tag_name_; }
  std::string GetContent() const { return content_; }

  size_t GetChildCount() const { return children_.size(); }

  RichTextNode *GetChildAt(int32_t index) const;

  tasm::PropBundle *GetProps() const { return style_bundle_.get(); }

 private:
  std::string tag_name_;
  RichTextNode *parent_;
  std::string content_;
  std::shared_ptr<tasm::PropBundle> style_bundle_ = {};
  std::vector<std::shared_ptr<RichTextNode>> children_ = {};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_RICHTEXT_RICH_TEXT_NODE_H_
