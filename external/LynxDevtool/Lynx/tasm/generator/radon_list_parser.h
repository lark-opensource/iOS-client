// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_RADON_LIST_PARSER_H_
#define LYNX_TASM_GENERATOR_RADON_LIST_PARSER_H_

#include <string>
#include <unordered_map>

#include "tasm/generator/radon_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {

class RadonListParser {
 public:
  enum class ListComponentType : size_t {
    DEFAULT = 0,
    HEADER = 1,
    FOOTER = 2,
    LIST_ROW = 3
  };
  using ListNodeType = std::array<std::string, 3>;
  RadonListParser(RadonParser &parser, int32_t dynamic_node_index,
                  std::string &eid)
      : parser_{parser}, dynamic_node_index_{dynamic_node_index}, eid_{eid} {}
  std::string GenList(const rapidjson::Value &child);

 private:
  RadonParser &parser_;
  int32_t dynamic_node_index_;
  std::string eid_;

  RadonListParser::ListNodeType Generate(const rapidjson::Value &child,
                                         ListComponentType list_component_type,
                                         size_t depth);

  RadonListParser::ListNodeType GenerateList(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateIf(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateRepeat(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateNode(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateNodeBlock(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateNodeHeader(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateNodeFooter(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateNodeListRow(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);

  RadonListParser::ListNodeType GenerateComponent(
      const rapidjson::Value &child, ListComponentType list_component_type,
      size_t depth);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_RADON_LIST_PARSER_H_
