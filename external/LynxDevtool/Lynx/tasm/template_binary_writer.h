// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TEMPLATE_BINARY_WRITER_H_
#define LYNX_TASM_TEMPLATE_BINARY_WRITER_H_

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "css/css_parser.h"
#include "lepus/context_binary_writer.h"
#include "tasm/encode_util.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/header_ext_info.h"
#include "tasm/moulds.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

class CSSParseToken;
class CSSSheet;
struct CSSRoute;
struct ComponentRoute;
struct DynamicComponentRoute;
struct PageRoute;
class PageMould;
class VirtualNode;
class VirtualComponent;

class TemplateAssembler;
class SourceGenerator;

class TemplateBinaryWriter : public lepus::ContextBinaryWriter {
 public:
  TemplateBinaryWriter(
      lepus::Context* context, bool use_lepusng, bool silence,
      SourceGenerator* parser, CSSParser* css_parser,
      rapidjson::Value* air_styles, rapidjson::Value* parsed_styles,
      rapidjson::Document* element_template, const char* lepus_version,
      const std::string& cli_version, const std::string& app_type,
      const std::string& config, const std::string& lepus_code,
      const std::unordered_map<std::string, std::string>& sub_lepus_code,
      const CompileOptions& compile_options, const lepus::Value& trial_options,
      const lepus::Value& template_info,
      const std::unordered_map<std::string, std::string> js_code,
      bool enableDebugInfo = false)
      : ContextBinaryWriter(context, compile_options, trial_options,
                            enableDebugInfo),
        context_(context),
        use_lepusng_(use_lepusng),
        parser_(parser),
        css_parser_(css_parser),
        air_styles_(air_styles),
        parsed_styles_(parsed_styles),
        element_template_(element_template),
        binary_info_(lepus_version, cli_version),
        app_type_(app_type),
        config_(config),
        lepus_code_(lepus_code),
        sub_lepus_code_(sub_lepus_code),
        silence_(silence),
        template_info_(template_info),
        js_code_(js_code) {}
  size_t Encode();
  bool WriteToFile(const char* file_name);
  const std::vector<uint8_t> WriteToVector();

  LepusDebugInfo GetDebugInfo();
  std::vector<lynx::base::scoped_refptr<lynx::lepus::Function>>
  GetContextFunc();
  const std::map<uint8_t, Range>& OffsetMap() const { return offset_map_; }
  const std::map<BinarySection, uint32_t>& SectionSizeInfo() const {
    return section_size_info_;
  }
  uint32_t HeaderSize() const { return header_size_; }

  std::string GetLepusNGSourceCode() { return lepusNG_source_code_; }
  int32_t GetLepusNGEndLineNum() { return end_line_num_; }
  LEPUSValue GetLepusNGTopLevelFunction() { return top_level_function_; }

 protected:
  size_t EncodeNonFlexibleTemplateBody(std::function<void()> encode_func);
  size_t EncodeFlexibleTemplateBody(std::function<void()> encode_func);

  // For flexible template
  void EncodeSectionRoute();
  void MoveLastSectionToFirst(const BinarySection& section);

  // Header Info
  bool EncodeHeaderInfo(const CompileOptions& compile_options);
  bool EncodeHeaderInfoField(
      const HeaderExtInfo::HeaderExtInfoField& header_info_field);

  // CSS Descriptor
  void EncodeCSSDescriptor();
  void EncodeCSSRoute(const CSSRoute& css_route);
  void EncodeCSSFragment(SharedCSSFragment* fragment);
  bool EncodeCSSParseToken(CSSParseToken* token);
  bool EncodeCSSKeyframesToken(CSSKeyframesToken* token);
  bool EncodeCSSSheet(CSSSheet* sheet);
  bool EncodeCSSAttributes(const StyleMap& attrs);
  bool EncodeCSSStyleVariables(const CSSVariableMap& style_variables);
  bool EncodeCSSKeyframesMap(const CSSKeyframesMap& keyframes);
  bool EncodeCSSFontFaceToken(CSSFontFaceToken* token);
  bool EncodeCSSFontFaceTokenList(
      const std::vector<std::shared_ptr<CSSFontFaceToken>>& tokenList);
  bool EncodeLynxCSSSelectorTuple(const LynxCSSSelectorTuple& selector_tuple);
  bool EncodeCSSSelector(const css::LynxCSSSelector* selector);
  // Component Descriptor
  void EncodeComponentDescriptor();
  void EncodeComponentRoute(const ComponentRoute& route);
  void EncodeComponentMould(const ComponentMould* mould);

  // Dynamic Component Descriptor
  void EncodeDynamicComponentDescriptor();
  void EncodeDynamicComponentRoute(const DynamicComponentRoute& route);
  void EncodeDynamicComponentMould(const DynamicComponentMould* mould);
  void EncodeDynamicComponentConfig(const DynamicComponentMould* mould);

  // Page Descriptor
  void EncodePageDescriptor();
  void EncodePageRoute(const PageRoute& route);
  void EncodePageMould(const PageMould* mould);
  void EncodeContext();

  // Using Dynamic Component Info
  void EncodeUsingDynamicComponentInfo(
      const std::unordered_map<std::string, std::string>& infos);

  // Page config
  void EncodePageConfig();

  // App descriptor
  void EncodeAppDescriptor();

  // String section
  void SerializeStringTable();
  void MoveStringTableToFirst();

  // JS section
  void SerializeJSSource();

  // Themed section
  void SerializeThemedSection();
  bool CheckHasThemedSection();
  bool CheckHasUsingDynamicComponentsSection();

  // Encode Header
  void EncodeHeader();
  void EncodeSectionCount(const std::string& app_type);

  // Encode Page config
  void EncodeConfig();
  void EncodeLepusSection();

  // Encode Element Template
  void EncodeElementTemplateSection();
  void EncodeTemplateRoute(const ElementTemplateRoute& route);
  void EncodeTemplate(const rapidjson::Value& value);
  void EncodeElement(const rapidjson::Value& value);
  void EncodeEvent(const rapidjson::Value& value);

  // Encode ParsedStyle
  void EncodeParsedStyles();
  void EncodeParsedStylesRoute(const ParsedStylesRoute& route);

  // Encode Air Styles
  void EncodeAirParsedStyles();
  void EncodeAirParsedStylesRoute(const AirParsedStylesRoute& route);

 private:
  static int FindJSFileInDirectory(
      const char* path, const char* relationPath,
      std::unordered_map<std::string, std::string>& js_map);
  static bool IsDir(const char* path);

 protected:
  lepus::Context* context_;
  bool use_lepusng_;
  SourceGenerator* parser_;
  CSSParser* css_parser_;

  // air styles
  rapidjson::Value* air_styles_{};

  // parsed style
  rapidjson::Value* parsed_styles_{};
  // element template
  rapidjson::Document* element_template_{nullptr};

  TemplateBinary binary_info_;
  std::string app_type_;
  std::string config_;
  std::string lepus_code_;
  std::unordered_map<std::string, std::string> sub_lepus_code_;

  bool silence_;
  PackageInstanceBundleModuleMode bundle_module_mode_;
  HeaderExtInfo header_ext_info_;
  std::map<uint8_t, Range> offset_map_;
  std::map<BinarySection, uint32_t> section_size_info_;
  uint32_t header_size_{0};
  lepus::Value template_info_{};
  std::unordered_map<std::string, std::string> js_code_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_BINARY_WRITER_H_
