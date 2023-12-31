// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_RICHTEXT_RICH_TEXT_PARSER_H_
#define LYNX_RICHTEXT_RICH_TEXT_PARSER_H_

#include <memory>
#include <vector>

#include "third_party/little-xml/include/lxml.hpp"

namespace lynx {
namespace tasm {

class RichTextNode;

class RichTextParser : public lxml::XMLReader::ReaderDelegate {
 public:
  RichTextParser() = default;
  ~RichTextParser() override = default;

  bool Parse(const char *content, size_t len);

  void HandleBeginTag(const char *name, size_t len) override;

  void HandleEndTag(const char *name, size_t len) override;

  void HandleAttribute(const char *name, size_t n_len, const char *value,
                       size_t v_len) override;

  void HandleContent(const char *content, size_t len) override;

  void HandleError(const char *index, size_t offset, size_t total) override;

  void HandleEnd() override;

  std::vector<std::shared_ptr<RichTextNode>> GetParseResult() const {
    return nodes_;
  }

 private:
  std::vector<std::shared_ptr<RichTextNode>> nodes_ = {};
  RichTextNode *current_node_ = nullptr;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_RICHTEXT_RICH_TEXT_PARSER_H_
