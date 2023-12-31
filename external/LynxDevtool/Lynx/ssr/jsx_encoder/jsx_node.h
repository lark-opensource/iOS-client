// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SSR_JSX_ENCODER_JSX_NODE_H_
#define LYNX_SSR_JSX_ENCODER_JSX_NODE_H_

#include <string>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "napi.h"
#include "ssr/ssr_node_key.h"
#include "tasm/attribute_holder.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_types.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {

namespace ssr {

class JSXNodeFactory;
class JSXNode {
 public:
  static std::vector<JSXNode> ParseNApiObjectToJSXNode(
      const Napi::Value&, bool is_root, bool is_in_text,
      const tasm::CSSParserConfigs& configs);

  const std::vector<std::pair<std::string, lepus::Value>>& GetProperties()
      const {
    return properties_;
  }
  const std::vector<std::pair<tasm::CSSPropertyID, tasm::CSSValue>>&
  GetParsedInlineStyles() const {
    return inline_styles_;
  }
  const std::vector<std::string>& GetClassNames() const { return class_names_; }
  const std::string& GetTagName() const { return tag_name_; }
  const std::vector<JSXNode>& GetChildren() const { return children_; }
  bool IsRawText() const { return tag_name_ == "raw-text"; }
  // get node index
  bool IsComponentNode() const { return is_component_node_; }
  bool IsPageNode() const { return is_page_node_; }
  bool IsBlock() const {
    return tag_name_ == "block" || tag_name_ == "React.Fragment";
  }
  bool IsText() const {
    return tag_name_ == "text" || tag_name_ == "inline-text" || IsRawText();
  }

  uint32_t GetNodeIndex() const { return node_index_; }
  // List
  friend JSXNodeFactory;

 private:
  JSXNode() {}
  std::vector<std::pair<std::string, lepus::Value>> properties_;
  std::vector<std::pair<tasm::CSSPropertyID, tasm::CSSValue>> inline_styles_;
  std::vector<std::string> class_names_;
  std::vector<JSXNode> children_;
  uint32_t node_index_ = -1;
  std::string tag_name_;
  bool is_component_node_ = false;
  bool is_page_node_ = false;
};

}  // namespace ssr
}  // namespace lynx
#endif  // LYNX_SSR_JSX_ENCODER_JSX_NODE_H_
