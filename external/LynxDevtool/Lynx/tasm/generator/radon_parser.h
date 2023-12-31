// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_RADON_PARSER_H_
#define LYNX_TASM_GENERATOR_RADON_PARSER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "lepus/lepus_string.h"
#include "tasm/generator/source_generator.h"
#include "tasm/generator/ttml_holder.h"
#include "tasm/moulds.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {

using StringVector = std::vector<std::string>;
using RadonCreateAndUpdateMap =
    std::unordered_map<std::string, std::vector<std::string>>;

class RadonParser : public SourceGenerator {
  using FunctionPointer = std::vector<std::string> (RadonParser::*)(
      const rapidjson::Value& instruction);

 public:
  RadonParser(const EncoderOptions& encoder_options);
  virtual ~RadonParser() override;

  virtual void Parse() override{};

 protected:
  // Renderer function generator
  StringVector GenTemplateDynamicRendererInFragment(Fragment* fragment);
  StringVector GenTemplateCreateAndUpdateFunc(Template* tem);
  StringVector GenComponentCreateAndUpdate(Component* component);
  std::string GenDependentComponentInfoMapDefinition(Component* component);

  // Instruction generator
  StringVector GenInstruction(const rapidjson::Value& instruction);
  StringVector GenIf(const rapidjson::Value& content);
  StringVector GenRepeat(const rapidjson::Value& repeat);
  StringVector GenTemplate(const rapidjson::Value& tem);
  StringVector GenTemplateNode(const rapidjson::Value& template_node);
  StringVector GenImport(const rapidjson::Value& import);
  StringVector GenInclude(const rapidjson::Value& include);
  StringVector GenComponentPlug(const rapidjson::Value& element);
  StringVector GenComponentNode(const rapidjson::Value& json_component);
  StringVector GenChildrenInComponentElement(const rapidjson::Value& children);
  StringVector GenDynamicComponentNode(const rapidjson::Value& component);

  StringVector GenComponentPlugInTemplate(const rapidjson::Value& element);
  StringVector GenComponentNodeInTemplate(const rapidjson::Value& component);
  StringVector GenList(const rapidjson::Value& element);
  StringVector GenListChildren(const rapidjson::Value& element);
  StringVector GenListChild(const rapidjson::Value& element);
  StringVector GenListRawChild(
      const rapidjson::Value& element,
      ListComponentType type = ListComponentType::Default);

  std::string GenComponentProps(const rapidjson::Value& element);
  std::string GenComponentEvent(const rapidjson::Value& element);

  // Element generator
  StringVector GenElement(const rapidjson::Value& element);
  StringVector GenRawElement(const rapidjson::Value& element);
  StringVector GenElementSlot(const rapidjson::Value& slot);
  StringVector GenElementPlug(const rapidjson::Value& element);
  StringVector GenElementNode(const rapidjson::Value& element,
                              bool should_gen_children = true);
  StringVector GenClasses(const rapidjson::Value& classes);
  StringVector GenStyles(const rapidjson::Value& styles);
  StringVector GenId(const rapidjson::Value& attrs);
  StringVector GenAttributes(const rapidjson::Value& attrs);
  StringVector GenDataSet(const rapidjson::Value& attrs);
  StringVector GenChildrenInElement(const rapidjson::Value& children);
  StringVector GenRawText(const rapidjson::Value& element);
  std::string GenEvents(const rapidjson::Value& element);

  std::string GenCreateList(const rapidjson::Value& element, std::string& eid);
  std::string GenUpdateList(const rapidjson::Value& element, std::string& eid);

  RadonCreateAndUpdateMap GenNecessaryCreateAndUpdate(Component* component);
  void GenComponentMouldForCompilerNG(Component* component);

  int dynamic_node_index_{0};
  std::vector<std::string> gen_record_;

 private:
  bool IsSubRoot();
  // if a "component" node is the child of a "for", "if", "elif" or "else" node,
  // add a "block" node child between them
  void AddBlockNodeAboveComponentNode(const rapidjson::Value& component_val);

  friend class RadonListParser;
  friend class TemplateScope;
  friend class FragmentScope;
  friend class ComponentScope;
  friend class PageScope;

  int text_count_{0};
  bool allow_gen_slot_content_{false};
  std::vector<int> if_branch_index_record_;
  std::unordered_map<std::string, FunctionPointer> instruction_map_;

  // `document` needs to have the same lifetime as the `TemplateParser` itself
  // because JSON values allocated during parsing have their allocation roots
  // here.
  rapidjson::Document document_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_RADON_PARSER_H_
