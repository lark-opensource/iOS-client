// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_TEMPLATE_PARSER_H_
#define LYNX_TASM_GENERATOR_TEMPLATE_PARSER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "lepus/lepus_string.h"
#include "tasm/generator/source_generator.h"
#include "tasm/generator/ttml_holder.h"
#include "tasm/moulds.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {

typedef std::unordered_map<std::string, std::pair<std::string, std::string>>
    TemplateRenderMap;

class TemplateParser : public SourceGenerator {
  friend class ListParser;

 public:
  TemplateParser(const EncoderOptions& encoder_options);
  virtual ~TemplateParser() override;

  virtual void Parse() override{};

 protected:
  std::string AddAttributes(std::string& source, std::string key,
                            std::string value);

  // Renderer function generator
  TemplateRenderMap GenNecessaryRenders(Component* component);
  std::string GenTemplateDynamicRendererInFragment(Fragment* fragment);
  std::string GenTemplateRenderer(Template* tem);
  std::string GenComponentRenderer(Component* component);
  std::string GenDependentComponentInfoMapDefinition(Component* component);

  // Instruction generator
  std::string GenInstruction(const rapidjson::Value& instruction,
                             const TemplateMap* const templates = nullptr);
  std::string GenIf(const rapidjson::Value& content);
  std::string GenRepeat(const rapidjson::Value& repeat);
  std::string GenTemplate(const rapidjson::Value& tem, bool is_include = false);
  std::string GenTemplateNode(const rapidjson::Value& template_node,
                              const TemplateMap* const templates);
  std::string GenImport(const rapidjson::Value& import,
                        bool is_include = false);
  void GenFragment(const rapidjson::Value& import);
  std::string GenInclude(const rapidjson::Value& include);
  std::string GenComponentPlug(const rapidjson::Value& component);
  std::string GenComponentNode(const rapidjson::Value& component);
  std::string GenChildrenInComponentElement(const rapidjson::Value& children);
  std::string GenDynamicComponentPlug(const rapidjson::Value& component);
  std::string GenDynamicComponentNode(const rapidjson::Value& component,
                                      const std::string& gen_slot_content);

  std::string GenComponentPlugInTemplate(const rapidjson::Value& component);
  std::string GenComponentNodeInTemplate(const rapidjson::Value& component);

  std::string GenList(const rapidjson::Value& element);
  std::string GenComponentProps(const rapidjson::Value& element);
  std::string GenComponentEvent(const rapidjson::Value& element);

  // Element generator
  std::string GenElement(const rapidjson::Value& element);
  std::string GenRawElement(const rapidjson::Value& element);
  std::string GenElementSlot(const rapidjson::Value& slot);
  std::string GenElementPlug(const rapidjson::Value& element);
  std::string GenElementNode(const rapidjson::Value& element,
                             bool should_gen_children = true);
  std::string GenClasses(const rapidjson::Value& classes);
  std::string GenStyles(const rapidjson::Value& styles);
  std::string GenId(const rapidjson::Value& attrs);
  std::string GenAttributes(const rapidjson::Value& attrs);
  std::string GenDataSet(const rapidjson::Value& attrs);
  std::string GenEvents(const rapidjson::Value& element);
  std::string GenChildrenInElement(const rapidjson::Value& children);
  std::string GenRawText(const rapidjson::Value& element);

  void GenComponentMouldForCompilerNG(Component* component);

  rapidjson::Value SegregateAttrsFromPropsForComponent(
      const rapidjson::Value& props, std::stringstream& set_props_content,
      bool component_is = true, Component* component = nullptr);

 private:
  friend TemplateScope;
  friend FragmentScope;
  friend ComponentScope;
  friend PageScope;

  int text_count_{0};
  bool allow_gen_slot_content_{false};
  std::unordered_set<std::string> opening_files_;
  std::unordered_set<std::string> including_chain_;

  // `document` needs to have the same lifetime as the `TemplateParser` itself
  // because JSON values allocated during parsing have their allocation roots
  // here.
  rapidjson::Document document;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_TEMPLATE_PARSER_H_
