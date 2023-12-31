// TODO

// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_TEMPLATE_BINARY_H_
#define LYNX_TASM_TEMPLATE_BINARY_H_

#define QUICK_BINARY_MAGIC 0x6d000000
#define LEPUS_BINARY_MAGIC 0x6d736100
#define TASM_SSR_SUFFIX_MAGIC 0x72737300
#define LEPUS_BINARY_VERSION 1

#include <string>
#include <unordered_map>
#include <vector>

namespace lynx {
namespace tasm {

#define LEPUS_VERSION_COUNT 4

enum BinaryOffsetType {
  TYPE_STRING,
  TYPE_CSS,
  TYPE_COMPONENT,
  TYPE_PAGE_ROUTE,
  TYPE_PAGE_DATA,
  TYPE_APP,
  TYPE_JS,
  TYPE_CONFIG,
  TYPE_DYNAMIC_COMPONENT_ROUTE,
  TYPE_DYNAMIC_COMPONENT_DATA,
  TYPE_THEMED,
  TYPE_USING_DYNAMIC_COMPONENT_INFO,
  TYPE_PAGE,
  TYPE_DYNAMIC_COMPONENT,
  TYPE_SECTION_ROUTE,
  TYPE_ROOT_LEPUS,
  TYPE_ELEMENT_TEMPLATE,
  TYPE_PARSED_STYLES
};

enum BinarySection {
  STRING,
  CSS,
  COMPONENT,
  PAGE,
  APP,
  JS,
  CONFIG,
  DYNAMIC_COMPONENT,
  THEMED,
  USING_DYNAMIC_COMPONENT_INFO,
  SECTION_ROUTE,
  ROOT_LEPUS,
  ELEMENT_TEMPLATE,
  PARSED_STYLES
};

enum PageSection {
  MOULD,
  CONTEXT,
  VIRTUAL_NODE_TREE,
  RADON_NODE_TREE,
};

enum ElementBuiltInTagEnum {
  ELEMENT_VIEW,
  ELEMENT_TEXT,
  ELEMENT_RAW_TEXT,
  ELEMENT_IMAGE,
  ELEMENT_SCROLL_VIEW,
  ELEMENT_LIST,
  ELEMENT_COMPONENT,
  ELEMENT_PAGE,
  ELEMENT_NONE,
  ELEMENT_WRAPPER,
  ELEMENT_OTHER
};

enum ElementTemplateEnum {
  ELEMENT_ID,
  ELEMENT_TEMP_ID,
  ELEMENT_ID_SELECTOR,
  ELEMENT_TAG_ENUM,
  ELEMENT_TAG_STR,
  ELEMENT_CHILDREN,
  ELEMENT_CLASS,
  ELEMENT_STYLES,
  ELEMENT_ATTRIBUTES,
  ELEMENT_EVENTS,
  ELEMENT_DATA_SET,
  ELEMENT_IS_COMPONENT,
  ELEMENT_PARSED_STYLES,
  ELEMENT_PARSED_STYLES_KEY,
  ELEMENT_CONFIG,
  ELEMENT_NOT_RECORDED,
};

enum DynamicComponentSection { DYNAMIC_MOULD, DYNAMIC_CONTEXT, DYNAMIC_CONFIG };

struct Range {
  uint32_t start;
  uint32_t end;

  Range() : start(0), end(0) {}
  Range(uint32_t s, uint32_t e) : start(s), end(e) {}

  uint32_t size() const { return end - start; }

  bool operator<(const Range& rhs) const {
    return this->start < rhs.start ||
           (!(rhs.start < this->start) && this->end < rhs.end);
  }

  bool operator==(const Range& rhs) const {
    return this->start == rhs.start && this->end == rhs.end;
  }
};

typedef Range PageRange;
struct PageRoute {
  std::unordered_map<int, PageRange> page_ranges;
};

typedef Range ComponentRange;
struct ComponentRoute {
  std::unordered_map<int, ComponentRange> component_ranges;
};

typedef Range DynamicComponentRange;
struct DynamicComponentRoute {
  std::unordered_map<int, DynamicComponentRange> dynamic_component_ranges;
};

typedef Range CSSRange;
struct CSSRoute {
  std::unordered_map<int, CSSRange> fragment_ranges;
};

typedef Range ElementTemplateRange;
struct ElementTemplateRoute {
  uint32_t descriptor_offset_;
  std::unordered_map<std::string, ElementTemplateRange> template_ranges_;
};

typedef Range ParsedStylesRange;
struct ParsedStylesRoute {
  uint32_t descriptor_offset_;
  std::unordered_map<std::string, ParsedStylesRange> parsed_styles_ranges_;
};

typedef Range AirParsedStylesRange;
struct AirParsedStylesRoute {
  uint32_t descriptor_offset_;
  std::unordered_map<std::string,
                     std::unordered_map<std::string, AirParsedStylesRange>>
      parsed_styles_ranges_;
};

class TemplateBinary {
 public:
  struct SectionInfo {
    BinarySection type_;
    uint32_t start_offset_;
    uint32_t end_offset_;
  };

  TemplateBinary(const char* lepus_version, const std::string& cli_version)
      : lepus_version_(lepus_version), cli_version_(cli_version) {}

  void AddSection(BinarySection sec, uint32_t start_offset,
                  uint32_t end_offset) {
    SectionInfo info = {sec, start_offset, end_offset};
    section_ary_.push_back(info);
  }

 public:
  typedef std::vector<SectionInfo> SectionList;

  uint32_t magic_word_;
  const char* lepus_version_;
  uint8_t section_count_;
  SectionList section_ary_;

  uint32_t total_size_;

  const std::string cli_version_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_BINARY_H_
