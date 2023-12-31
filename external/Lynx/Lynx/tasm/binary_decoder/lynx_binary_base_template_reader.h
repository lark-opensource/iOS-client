//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_TEMPLATE_READER_H_
#define LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_TEMPLATE_READER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "css/css_style_sheet_manager.h"
#include "css/css_value.h"
#include "css/shared_css_fragment.h"
#include "tasm/base/element_template_info.h"
#include "tasm/binary_decoder/lynx_binary_base_css_reader.h"
#include "tasm/binary_decoder/lynx_binary_config_decoder.h"
#include "tasm/header_ext_info.h"
#include "tasm/moulds.h"
#include "tasm/template_binary.h"
#include "tasm/template_themed.h"

namespace lynx {
namespace tasm {

struct PageRoute;
struct ComponentRoute;

class LynxBinaryBaseTemplateReader : public LynxBinaryBaseCSSReader {
 public:
  LynxBinaryBaseTemplateReader(std::unique_ptr<lepus::InputStream> stream)
      : LynxBinaryBaseCSSReader(std::move(stream)),
        need_console_(true),
        support_component_js_(false){};

  virtual ~LynxBinaryBaseTemplateReader() = default;

  bool Decode();

  void SetIsCard(bool is_card) { is_card_ = is_card; }

  std::shared_ptr<ElementTemplateInfo> DecodeElementTemplate(
      const std::string& key);

  const StyleMap& GetParsedStyles(const std::string& key);

 protected:
  // Perform some check or set method after decode header.
  virtual bool DidDecodeHeader() = 0;
  virtual bool DidDecodeAppType();
  virtual bool DidDecodeTemplate() = 0;

  // Decode Header Section.
  bool DecodeHeader();
  bool SupportedLepusVersion(const std::string& binary_version,
                             std::string& error);
  bool CheckLynxVersion(const std::string& binary_version);
  std::vector<int> VersionStrToNumber(const std::string& version_str);
  bool DecodeHeaderInfo(CompileOptions& compile_options);
  bool DecodeHeaderInfoField();

  template <typename T>
  void ReinterpretValue(T& tgt, std::vector<uint8_t> src);

  // Decode Template body
  bool DecodeTemplateBody();
  // For Section Route
  bool DecodeSectionRoute();
  // For Specific Section
  bool DecodeSpecificSection(const BinarySection& section);
  // For FlexibleTemplate
  bool DecodeFlexibleTemplateBody();
  // For NonFlexibleTemplate
  bool DeserializeSection();
  // JS section
  bool DeserializeJSSourceSection();
  // App Descriptor
  bool DecodeAppDescriptor();
  // Page Descriptor
  bool DecodePageDescriptor(bool is_hmr = false);
  bool DecodePageRoute(PageRoute& route);
  bool DecodePageMould(PageMould* mould);
  virtual bool DecodeContext() = 0;
  bool DeserializeVirtualNodeSection();
  // Component Descriptor
  bool DecodeComponentDescriptor(bool is_hmr = false);
  bool DecodeComponentRoute(ComponentRoute& route);
  bool DecodeComponentMould(ComponentMould* mould, int offset, int length);
  // CSS Descriptor
  virtual bool DecodeCSSDescriptor(bool is_hmr = false) = 0;
  // Dynamic Component
  bool DecodeDynamicComponentDescriptor(bool is_hmr = false);
  bool DecodeDynamicComponentRoute(DynamicComponentRoute& route);
  bool DecodeDynamicComponentMould(DynamicComponentMould* mould);
  bool DecodeDynamicComponentDeclarations();
  // Themed
  virtual Themed& Themed() = 0;
  bool DecodeThemedSection();

  // Element Template
  virtual bool DecodeElementTemplateSection();
  bool DecodeElementTemplateRoute();
  bool DecodeElementTemplateInfoInner(ElementTemplateInfo& info);
  bool DecodeElementInfo(ElementInfo& info);
  bool DecodeEvent(ElementInfo& info);

  // Parsed Style
  virtual bool DecodeParsedStylesSection();
  bool DecodeParsedStylesInner(StyleMap& style_map);
  virtual ParsedStyleMap& GetParsedStyleMap() = 0;

  // Air Parsed Styles
  virtual bool DecodeAirParsedStylesSection();
  bool DecodeAirParsedStylesInner(StyleMap& style_map);
  virtual AirParsedStylesMap& GetAirParsedStylesMap() = 0;

 protected:
  bool is_card_{true};
  // config decoder
  std::unique_ptr<LynxBinaryConfigDecoder> config_decoder_;

  // header fields.
  uint32_t total_size_;
  bool need_console_;
  bool support_component_js_;
  std::vector<int> lepus_version_;
  bool is_lepusng_binary_ = false;
  HeaderExtInfo header_ext_info_;
  std::unordered_map<uint32_t, std::vector<uint8_t>> header_info_map_;
  lepus::Value template_info_{};
  std::string app_type_{};

  // app fields.
  std::string app_name_{};

  // page fields.
  std::unordered_map<int32_t, std::shared_ptr<PageMould>> page_moulds_{};
  std::shared_ptr<lynx::tasm::PageConfig> page_configs_{};

  // component fields.
  std::unordered_map<std::string, int32_t> component_name_to_id_{};
  std::unordered_map<int32_t, std::shared_ptr<ComponentMould>>
      component_moulds_{};

  // JS fields.
  std::unordered_map<lepus::String, lepus::String> js_sources_{};

  // Dynamic Component fields.
  std::unordered_map<int32_t, std::shared_ptr<DynamicComponentMould>>
      dynamic_component_moulds_;
  // USING_DYNAMIC_COMPONENT_INFO fields.
  std::unordered_map<std::string, std::string>
      dynamic_component_declarations_{};

  // flexible template fields.
  std::unordered_map<BinarySection, TemplateBinary::SectionInfo>
      section_route_{};

  // Element Template fields.
  ElementTemplateRoute element_template_route_;

  // ParsedStyles fields
  ParsedStylesRoute parsed_styles_route_;

  // AirParsedStyles fields
  AirParsedStylesRoute air_parsed_styles_route_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_TEMPLATE_READER_H_
