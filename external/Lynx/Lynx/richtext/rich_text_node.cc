// Copyright 2022 The Lynx Authors. All rights reserved.

#include "Lynx/richtext/rich_text_node.h"

namespace lynx {
namespace tasm {

RichTextNode::RichTextNode(const char *name)
    : tag_name_(name),
      parent_(nullptr),
      style_bundle_(tasm::PropBundle::Create().release()) {}

RichTextNode::RichTextNode(std::string name, std::string content)
    : tag_name_(std::move(name)),
      parent_(nullptr),
      content_(std::move(content)),
      style_bundle_(tasm::PropBundle::Create().release()) {}

RichTextNode::RichTextNode(std::vector<std::shared_ptr<RichTextNode>> children)
    : parent_(),
      style_bundle_(tasm::PropBundle::Create().release()),
      children_(std::move(children)) {}

void RichTextNode::SetProps(const char *key, const lepus::Value &value) {
  style_bundle_->SetProps(key, value);
}

RichTextNode *RichTextNode::GetChildAt(int32_t index) const {
  if (static_cast<size_t>(index) >= children_.size()) {
    return nullptr;
  }

  return children_[index].get();
}

}  // namespace tasm
}  // namespace lynx
