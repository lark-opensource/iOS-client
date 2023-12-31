//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "lynx_binary_base_template_reader.h"

#include <algorithm>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

bool LynxBinaryBaseTemplateReader::Decode() {
  // Decode header
  ERROR_UNLESS(DecodeHeader());

  // Perform some check or set method after decode header.
  ERROR_UNLESS(DidDecodeHeader());

  // Decode app type.
  ERROR_UNLESS(ReadStringDirectly(&app_type_));

  // Perform some check or set method after decode app type.
  ERROR_UNLESS(DidDecodeAppType());

  // Decode snapshot, useless now.
  DECODE_BOOL(snapshot);

  // Decode template's all sections.
  ERROR_UNLESS(DecodeTemplateBody());

  // Perform some check or set method after decode template.
  ERROR_UNLESS(DidDecodeTemplate());

  // If all above functions do not return false, then return true.
  return true;
}

// Decode Header Section
bool LynxBinaryBaseTemplateReader::DecodeHeader() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "DecodeHeader");
  DECODE_U32(total_size);
  if (total_size != stream_->size()) {
    error_message_ = "Decode Error, tasm file has broken";
    return false;
  }
  total_size_ = total_size;

  DECODE_U32(magic_word);
  if (magic_word == QUICK_BINARY_MAGIC) {
    is_lepusng_binary_ = true;
  } else if (magic_word == LEPUS_BINARY_MAGIC) {
    is_lepusng_binary_ = false;
  } else {
    return false;
  }

  // lepus_version is deprecated
  // now it is just used to be compatible with prev version
  std::string lepus_version;  // deprecated
  std::string error;
  ERROR_UNLESS(ReadStringDirectly(&lepus_version));
  ERROR_UNLESS_CODE(SupportedLepusVersion(lepus_version, error), error_message_,
                    error);

  std::string target_sdk_version;
  if (lepus_version > MAX_UNSUPPORTED_GECKO_MONITOR_VERSION) {
    // cli_version is deprecated
    // now ios_version == android_version == target_cli_version
    std::string cli_version;  // deprecated
    std::string ios_version;
    std::string android_version;

    ERROR_UNLESS(ReadStringDirectly(&cli_version));  // deprecated
    ERROR_UNLESS(ReadStringDirectly(&ios_version));
    ERROR_UNLESS(ReadStringDirectly(&android_version));
    if (ios_version != "unknown") {
      if (!CheckLynxVersion(ios_version)) {
        error_message_ =
            "Decode error, version check miss, should "
            "(current lynx version >= (ios == android) >= min supported), but: "
            "ios version:" +
            ios_version + ", android_version: " + android_version +
            ", min supported lynx version: " +
            Config::GetMinSupportLynxVersion() +
            ", current lynx version: " + Config::GetCurrentLynxVersion();
        return false;
      } else {
        LOGI("binary lynx version: "
             << ios_version << ", min supported lynx version: "
             << Config::GetMinSupportLynxVersion()
             << ", current lynx version:" << Config::GetCurrentLynxVersion());
      }
    } else {
      LOGI("target sdk version is unknown! jump LynxVersion check\n");
    }
    target_sdk_version = ios_version;
  }

  // Decode compiler options
  if (Config::IsHigherOrEqual(target_sdk_version,
                              FEATURE_HEADER_EXT_INFO_VERSION)) {
    ERROR_UNLESS(DecodeHeaderInfo(compile_options_));
  } else {
    compile_options_.target_sdk_version_ = target_sdk_version;
  }

  // Decode template info
  if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_TEMPLATE_INFO)) {
    ERROR_UNLESS(DecodeValue(&template_info_, true));
  }

  // Decode trial options
  if (compile_options_.enable_trial_options_) {
    ERROR_UNLESS(DecodeValue(&trial_options_, true));
  }

  enable_css_variable_ =
      Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_CSS_STYLE_VARIABLES) &&
      compile_options_.enable_css_variable_;
  enable_css_parser_ =
      Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_CSS_VALUE_VERSION) &&
      compile_options_.enable_css_parser_;

  return true;
}

bool LynxBinaryBaseTemplateReader::SupportedLepusVersion(
    const std::string &binary_version, std::string &error) {
  static std::string client_version = Config::GetVersion();
  static std::string min_supported_version = Config::GetMinSupportedVersion();
  static std::string max_need_console_version = Config::GetNeedConsoleVersion();

  std::vector<int> vec_binary = VersionStrToNumber(binary_version);
  static std::vector<int> vec_client = VersionStrToNumber(client_version);
  static std::vector<int> vec_min_supported_version =
      VersionStrToNumber(min_supported_version);

  LOGI("client version:" << client_version
                         << "  ;binary_version:" << binary_version);

  // Store lepus version
  lepus_version_ = vec_binary;

  bool has_error = false;

  if (vec_client.size() < LEPUS_VERSION_COUNT ||
      vec_binary.size() < LEPUS_VERSION_COUNT) {
    has_error = true;
  }

  if (!has_error) {
    // check is binary version > client version
    for (size_t i = 0; i < std::min(vec_client.size(), vec_binary.size());
         i++) {
      if (vec_client[i] > vec_binary[i]) {
        break;
      }

      if (vec_client[i] < vec_binary[i]) {
        has_error = true;
        break;
      }
    }
  }

  if (!has_error) {
    // check is binary version > min supported version
    for (size_t i = 0;
         i < std::min(vec_min_supported_version.size(), vec_binary.size());
         i++) {
      if (vec_binary[i] > vec_min_supported_version[i]) {
        break;
      }

      if (vec_binary[i] < vec_min_supported_version[i]) {
        has_error = true;
        break;
      }
    }
  }

  if (has_error) {
    error = "Decode Error,unsupported binary version:";
    error += binary_version;
    error += " ; client version:";
    error += client_version;
    error += " ; min supported version:";
    error += min_supported_version;
  }

  // check if this binary need 'console' in js runtime global
  std::vector<int> vec_max_need_console_version =
      VersionStrToNumber(max_need_console_version);
  for (size_t i = 0;
       i < std::min(vec_max_need_console_version.size(), vec_binary.size());
       i++) {
    if (vec_binary[i] > vec_max_need_console_version[i]) {
      need_console_ = false;
      support_component_js_ = true;
      break;
    }
  }
  return !has_error;
}

bool LynxBinaryBaseTemplateReader::CheckLynxVersion(
    const std::string &binary_version) {
  Version client_version(Config::GetCurrentLynxVersion());
  Version min_supported_lynx_version(Config::GetMinSupportLynxVersion());
  Version binary_lynx_version(binary_version);

  // binary_lynx_version should in this range:
  // min_supported_lynx_version  <= binary_lynx_version <= client_version
  if (binary_lynx_version < min_supported_lynx_version ||
      client_version < binary_lynx_version) {
    return false;
  }

  return true;
}

std::vector<int> LynxBinaryBaseTemplateReader::VersionStrToNumber(
    const std::string &version_str) {
  std::vector<int> version_vec;
  size_t pre_pos = 0;
  for (int i = 0; i < LEPUS_VERSION_COUNT - 1; i++) {
    size_t pos = version_str.find('.', pre_pos);
    if (pos == std::string::npos) {
      break;
    }
    std::string section = version_str.substr(pre_pos, pos);
    version_vec.push_back(atoi(section.c_str()));
    pre_pos = pos + 1;
  }
  size_t pos = version_str.find('-');
  if (pos != std::string::npos) {
    std::string section = version_str.substr(pre_pos, pos);
    version_vec.push_back(atoi(section.c_str()));
  } else {
    std::string section = version_str.substr(pre_pos);
    version_vec.push_back(atoi(section.c_str()));
  }
  return version_vec;
}

template <typename T>
void LynxBinaryBaseTemplateReader::ReinterpretValue(T &tgt,
                                                    std::vector<uint8_t> src) {
  if (src.size() == sizeof(T)) {
    tgt = *reinterpret_cast<T *>(src.data());
  }
}

template <>
void LynxBinaryBaseTemplateReader::ReinterpretValue(std::string &tgt,
                                                    std::vector<uint8_t> src) {
  tgt = std::string(reinterpret_cast<const char *>(src.data()), src.size());
}

bool LynxBinaryBaseTemplateReader::DecodeHeaderInfo(
    CompileOptions &compile_options) {
  auto curr_offset = stream_->offset();
  memset(&header_ext_info_, 0, sizeof(header_ext_info_));
  ERROR_UNLESS(stream_->ReadData(reinterpret_cast<uint8_t *>(&header_ext_info_),
                                 sizeof(header_ext_info_)));

  DCHECK(header_ext_info_.header_ext_info_magic_ == HEADER_EXT_INFO_MAGIC);
  for (uint32_t i = 0; i < header_ext_info_.header_ext_info_field_numbers_;
       i++) {
    ERROR_UNLESS(DecodeHeaderInfoField());
  }

#define CONVERT_FIXED_LENGTH_FIELD(type, field, id) \
  ReinterpretValue(compile_options_.field, header_info_map_[id])
  FOREACH_FIXED_LENGTH_FIELD(CONVERT_FIXED_LENGTH_FIELD)
#undef CONVERT_FIXED_LENGTH_FIELD

#define CONVERT_STRING_FIELD(field, id) \
  ReinterpretValue(compile_options_.field, header_info_map_[id])
  FOREACH_STRING_FIELD(CONVERT_STRING_FIELD)
#undef CONVERT_STRING_FIELD

  header_info_map_.clear();

  // space for forward compatible

  stream_->Seek(curr_offset + header_ext_info_.header_ext_info_size);

  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeHeaderInfoField() {
  HeaderExtInfo::HeaderExtInfoField header_info_field;
  auto size_to_read = sizeof(header_info_field) - sizeof(void *);
  ERROR_UNLESS(stream_->ReadData(
      reinterpret_cast<uint8_t *>(&header_info_field), (int)size_to_read));

  auto payload = std::vector<uint8_t>(header_info_field.payload_size_);
  ERROR_UNLESS(stream_->ReadData(reinterpret_cast<uint8_t *>(payload.data()),
                                 header_info_field.payload_size_));

  DCHECK(header_info_map_.find(header_info_field.key_id_) ==
         header_info_map_.end());
  header_info_map_[header_info_field.key_id_] = payload;

  return true;
}

bool LynxBinaryBaseTemplateReader::DidDecodeAppType() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DidDecodeAppType");
  if (app_type_ != APP_TYPE_DYNAMIC_COMPONENT && !is_card_) {
    error_message_ =
        "LynxBinaryBaseTemplateReader: input is a card when LoadComponent.";
    return false;
  }
  if (app_type_ == APP_TYPE_DYNAMIC_COMPONENT && is_card_) {
    error_message_ =
        "LynxBinaryBaseTemplateReader: input is a dynamic component when "
        "LoadTemplate.";
    return false;
  }
  return true;
}

// Decode Template body
bool LynxBinaryBaseTemplateReader::DecodeTemplateBody() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeTemplateBody");

  if (compile_options_.enable_flexible_template_) {
    ERROR_UNLESS(DecodeFlexibleTemplateBody());
    return true;
  }
  ERROR_UNLESS(DeserializeSection());
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeFlexibleTemplateBody() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeFlexibleTemplateBody");

  ERROR_UNLESS(DecodeSectionRoute());

  const static std::vector<BinarySection> kFiberSectionOrder{
      BinarySection::STRING,
      BinarySection::PARSED_STYLES,
      BinarySection::ELEMENT_TEMPLATE,
      BinarySection::CSS,
      BinarySection::JS,
      BinarySection::CONFIG,
      BinarySection::ROOT_LEPUS};

  const static std::vector<BinarySection> kSectionOrder{
      BinarySection::STRING,
      BinarySection::PARSED_STYLES,
      BinarySection::CSS,
      BinarySection::JS,
      BinarySection::COMPONENT,
      BinarySection::APP,
      BinarySection::PAGE,
      BinarySection::CONFIG,
      BinarySection::DYNAMIC_COMPONENT,
      BinarySection::USING_DYNAMIC_COMPONENT_INFO,
      BinarySection::THEMED};

  std::vector<BinarySection> order =
      compile_options_.enable_fiber_arch_ ? kFiberSectionOrder : kSectionOrder;

  for (const auto &s : order) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FindSpecificSection");

    auto iter = section_route_.find(s);
    if (iter == section_route_.end()) {
      continue;
    }

    const auto &route = iter->second;
    stream_->Seek(route.start_offset_);

    DECODE_U8(type);
    ERROR_UNLESS(DecodeSpecificSection(static_cast<BinarySection>(type)));
  }
  return true;
}

// For Section Route
bool LynxBinaryBaseTemplateReader::DecodeSectionRoute() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeSectionRoute");

  // section route type
  DECODE_U8(section_route_type);
  DECODE_U32LEB(section_count);

  for (uint32_t i = 0; i < section_count; ++i) {
    DECODE_U8(section);
    DECODE_U32LEB(start);
    DECODE_U32LEB(end);
    section_route_.insert({static_cast<BinarySection>(section),
                           {static_cast<BinarySection>(section), start, end}});
  }

  uint32_t start = static_cast<uint32_t>(stream_->offset());
  for (auto &pair : section_route_) {
    pair.second.start_offset_ += start;
    pair.second.end_offset_ += start;
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DeserializeSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeSection");

  DECODE_U8(section_count);
  for (size_t i = 0; i < section_count; i++) {
    DECODE_U8(type);
    ERROR_UNLESS(DecodeSpecificSection(static_cast<BinarySection>(type)));
  }  // end for

  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeSpecificSection(
    const BinarySection &section) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeSpecificSection");
  switch (section) {
    case BinarySection::CSS: {
      ERROR_UNLESS(DecodeCSSDescriptor());
      break;
    }
    case BinarySection::APP: {
      ERROR_UNLESS(DecodeAppDescriptor());
      break;
    }
    case BinarySection::PAGE: {
      ERROR_UNLESS(DecodePageDescriptor());
      break;
    }
    case BinarySection::STRING: {
      ERROR_UNLESS(DeserializeStringSection());
      break;
    }
    case BinarySection::COMPONENT: {
      ERROR_UNLESS(DecodeComponentDescriptor());
      break;
    }
    case BinarySection::JS: {
      ERROR_UNLESS(DeserializeJSSourceSection());
      break;
    }
    case BinarySection::CONFIG: {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodePageConfig");
      DECODE_STDSTR(config_str);
      page_configs_ = std::make_shared<PageConfig>();
      ERROR_UNLESS(
          config_decoder_->DecodePageConfig(config_str, page_configs_));
      break;
    }
    case BinarySection::DYNAMIC_COMPONENT: {
      ERROR_UNLESS(DecodeDynamicComponentDescriptor());
      break;
    }
    case BinarySection::THEMED: {
      ERROR_UNLESS(DecodeThemedSection());
      break;
    }
    case BinarySection::USING_DYNAMIC_COMPONENT_INFO: {
      ERROR_UNLESS(DecodeDynamicComponentDeclarations());
      break;
    }
    case BinarySection::ROOT_LEPUS: {
      ERROR_UNLESS(DecodeContext());
      break;
    }
    case BinarySection::ELEMENT_TEMPLATE: {
      ERROR_UNLESS(DecodeElementTemplateSection());
      break;
    }
    case BinarySection::PARSED_STYLES: {
      if (compile_options_.arch_option_ == ArchOption::FIBER_ARCH) {
        ERROR_UNLESS(DecodeParsedStylesSection());
      } else if (compile_options_.arch_option_ == ArchOption::AIR_ARCH) {
        ERROR_UNLESS(DecodeAirParsedStylesSection());
      }
      break;
    }
    default:
      DLOGE("unkown - section:");
      return false;
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeAppDescriptor() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeAppDescriptor");
  DECODE_U32LEB(main_page_id);
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_STR(path);
    DECODE_U32LEB(id);
    if (main_page_id == id) {
      app_name_ = path->str();
    }
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodePageDescriptor(bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodePageDescriptor");
  // TODO: lazy load
  PageRoute route;
  ERROR_UNLESS(DecodePageRoute(route));
  auto &page_ranges = route.page_ranges;
  size_t descriptor_start = stream_->offset();
  size_t descriptor_end = descriptor_start;
  for (auto &page_range : page_ranges) {
    stream_->Seek(descriptor_start + page_range.second.start);
    while (stream_->offset() < descriptor_start + page_range.second.end) {
      DECODE_U8(section);
      auto mould = std::make_shared<PageMould>();
      switch (section) {
        case PageSection::MOULD:
          ERROR_UNLESS(DecodePageMould(mould.get()));
#if ENABLE_HMR
          if (is_hmr && page_moulds_.find(mould->id()) != page_moulds_.end()) {
            page_moulds_.at(mould->id())
                ->set_data(std::move(mould->data()));  // update page data
          } else {
            page_moulds_[mould->id()] = std::move(mould);
          }
#else
          page_moulds_[mould->id()] = std::move(mould);
#endif
          break;
        case PageSection::CONTEXT:
          ERROR_UNLESS(DecodeContext());
          break;
        case PageSection::VIRTUAL_NODE_TREE:
          ERROR_UNLESS(DeserializeVirtualNodeSection());
          break;
      }
    }
    descriptor_end = descriptor_end > descriptor_start + page_range.second.end
                         ? descriptor_end
                         : page_range.second.end + descriptor_start;
  }
  stream_->Seek(descriptor_end);
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodePageMould(PageMould *mould) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodePageMould");
  DECODE_U32LEB(id);
  mould->set_id(id);
  DECODE_U32LEB(css_id);
  mould->set_css_id(css_id);
  DECODE_VALUE(data);
  mould->set_data(std::move(data));
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; i++) {
    DECODE_U32LEB(id);
    mould->AddDependentComponentId(id);
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodePageRoute(PageRoute &route) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_S32LEB(id);
    // CSSRange
    DECODE_U32LEB(start);
    DECODE_U32LEB(end);
    route.page_ranges.insert({id, PageRange(start, end)});
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DeserializeVirtualNodeSection() {
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeComponentDescriptor(bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeComponentDescriptor");
  ComponentRoute route;
  ERROR_UNLESS(DecodeComponentRoute(route));
  auto &component_ranges = route.component_ranges;
  size_t descriptor_start = stream_->offset();
  size_t descriptor_end = descriptor_start;
  for (auto it = component_ranges.begin(); it != component_ranges.end(); ++it) {
    auto mould = std::make_shared<ComponentMould>();
    stream_->Seek(descriptor_start + it->second.start);
    ERROR_UNLESS(DecodeComponentMould(
        mould.get(), static_cast<int>(stream_->offset()), it->second.end));
    component_name_to_id_[mould->name()] = mould->id();
#if ENABLE_HMR
    if (is_hmr &&
        component_moulds_.find(mould->id()) != component_moulds_.end()) {
      // when enable HMR, then move new data to the existed mould, in order to
      // update data
      component_moulds_.at(mould->id())
          .get()
          ->set_data(std::move(mould->data()));
    } else {
      component_moulds_[mould->id()] = std::move(mould);
    }
#else
    component_moulds_[mould->id()] = std::move(mould);
#endif
    descriptor_end = descriptor_end > descriptor_start + it->second.end
                         ? descriptor_end
                         : it->second.end + descriptor_start;
  }
  stream_->Seek(descriptor_end);
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeComponentRoute(ComponentRoute &route) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_S32LEB(id);
    // CSSRange
    DECODE_U32LEB(start);
    DECODE_U32LEB(end);
    route.component_ranges.insert({id, ComponentRange(start, end)});
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeComponentMould(ComponentMould *mould,
                                                        int offset,
                                                        int length) {
  DECODE_U32LEB(id);
  mould->set_id(id);
  DECODE_U32LEB(css_id);
  mould->set_css_id(css_id);
  DECODE_VALUE(data);
  mould->set_data(std::move(data));
  DECODE_VALUE(props);
  mould->set_properties(std::move(props));
  if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_CSS_EXTERNAL_CLASS_VERSION) &&
      compile_options_.enable_css_external_class_) {
    DECODE_VALUE(external_classes);
    mould->set_external_classes(std::move(external_classes));
  }
  if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_COMPONENT_CONFIG) &&
      compile_options_.enable_component_config_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeComponentConfig");
    DECODE_STDSTR(config_str);
    auto component_config = std::make_shared<ComponentConfig>();
    ERROR_UNLESS(
        config_decoder_->DecodeComponentConfig(config_str, component_config));
    mould->SetComponentConfig(component_config);
  }
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_U32LEB(id);
    mould->AddDependentComponentId(id);
  }
  size_t len = stream_->offset() - offset;
  if (len >= static_cast<size_t>(length)) {
    return true;
  }
  std::string name, path;
  ReadStringDirectly(&name);
  mould->set_name(std::move(name));
  ReadStringDirectly(&path);
  mould->set_path(std::move(path));
  len = stream_->offset() - offset;
  return true;
}

bool LynxBinaryBaseTemplateReader::DeserializeJSSourceSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeJSSourceSection");
  DECODE_U32(count);
  for (size_t i = 0; i < count; i++) {
    DECODE_STR(path);
    DECODE_STR(content);
    js_sources_[path] = content;
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeDynamicComponentDescriptor(
    bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeDynamicComponentDescriptor");
  DynamicComponentRoute route;
  ERROR_UNLESS(DecodeDynamicComponentRoute(route));
  auto &dynamic_component_ranges = route.dynamic_component_ranges;
  size_t descriptor_start = stream_->offset();
  size_t descriptor_end = descriptor_start;
  for (auto &dynamic_component_range : dynamic_component_ranges) {
    auto mould = std::make_shared<DynamicComponentMould>();
    stream_->Seek(descriptor_start + dynamic_component_range.second.start);
    while (stream_->offset() <
           descriptor_start + dynamic_component_range.second.end) {
      DECODE_U8(section);
      switch (section) {
        case DynamicComponentSection::DYNAMIC_MOULD:
          ERROR_UNLESS(DecodeDynamicComponentMould(mould.get()));
          break;
        case DynamicComponentSection::DYNAMIC_CONTEXT:
          ERROR_UNLESS(DecodeContext());
          break;
        case DynamicComponentSection::DYNAMIC_CONFIG:
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeComponentConfig");
          DECODE_STDSTR(config_str);
          auto component_config = std::make_shared<ComponentConfig>();
          ERROR_UNLESS(config_decoder_->DecodeComponentConfig(
              config_str, component_config));
          mould->SetComponentConfig(component_config);
          break;
      }
    }
#if ENABLE_HMR
    if (is_hmr && dynamic_component_moulds_.find(mould->id()) !=
                      dynamic_component_moulds_.end()) {
      // when enable HMR, then move new data to the existed mould, in order to
      // update data
      dynamic_component_moulds_.at(mould->id())
          .get()
          ->set_data(std::move(mould->data()));
    } else {
      dynamic_component_moulds_[mould->id()] = std::move(mould);
    }
#else
    dynamic_component_moulds_[mould->id()] = std::move(mould);
#endif
    descriptor_end =
        descriptor_end > descriptor_start + dynamic_component_range.second.end
            ? descriptor_end
            : dynamic_component_range.second.end + descriptor_start;
  }
  stream_->Seek(descriptor_end);
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeDynamicComponentDeclarations() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeDynamicComponentDeclarations");
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_STR(name);
    DECODE_STR(path);
    dynamic_component_declarations_.insert(
        std::make_pair(name->str(), path->str()));
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeDynamicComponentRoute(
    DynamicComponentRoute &route) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_S32LEB(id);
    // CSSRange
    DECODE_U32LEB(start);
    DECODE_U32LEB(end);
    route.dynamic_component_ranges.insert(
        {id, DynamicComponentRange(start, end)});
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeDynamicComponentMould(
    DynamicComponentMould *mould) {
  std::string path;
  ERROR_UNLESS(ReadStringDirectly(&path));
  mould->set_path(path);
  DECODE_U32LEB(id);
  mould->set_id(id);
  DECODE_U32LEB(css_id);
  mould->set_css_id(css_id);
  DECODE_VALUE(data);
  mould->set_data(data);
  if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              BUGFIX_DYNAMIC_COMPONENT_DEFAULT_PROPS_VERSION)) {
    DECODE_VALUE(props);
    mould->set_properties(std::move(props));
  }
  if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              FEATURE_CSS_EXTERNAL_CLASS_VERSION) &&
      compile_options_.enable_css_external_class_) {
    DECODE_VALUE(external_classes);
    mould->set_external_classes(std::move(external_classes));
  }
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; i++) {
    DECODE_U32LEB(id);
    mould->AddDependentComponentId(id);
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeThemedSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeThemedSection");
  std::shared_ptr<ThemeResMap> transFileMap = std::make_shared<ThemeResMap>();
  DECODE_U32LEB(fileCount);
  for (size_t i = 0; i < fileCount; ++i) {
    std::shared_ptr<ThemedRes> resMap = std::make_shared<ThemedRes>();
    DECODE_STDSTR(path);
    DECODE_U32LEB(itemCount);
    if (itemCount == 0) {
      continue;
    }
    for (size_t i = 0; i < itemCount; ++i) {
      DECODE_STDSTR(key);
      DECODE_STDSTR(value);
      if (!key.empty()) {
        resMap->insert({std::move(key), std::move(value)});
      }
    }
    if (!path.empty()) {
      transFileMap->insert({std::move(path), std::move(resMap)});
    }
  }

  auto &assemblerThemed = Themed();
  assemblerThemed.reset();

  DECODE_U32LEB(pageCount);
  for (size_t page = 0; page < pageCount; ++page) {
    DECODE_U32LEB(pageId);
    DECODE_U32LEB(defCount);
    if (defCount < 4) {
      continue;
    }

    // 1. __default
    ThemedRes defaultMap;
    DECODE_U32LEB(defaultCount);
    for (size_t index = 0; index < defaultCount; ++index) {
      DECODE_STDSTR(name);
      DECODE_STDSTR(value);
      defaultMap[name] = value;
    }

    // 2. __finalFallback
    ThemedRes fallback_map;
    DECODE_U32LEB(fallbackCount);
    for (size_t index = 0; index < fallbackCount; ++index) {
      DECODE_STDSTR(name);
      DECODE_STDSTR(value);
      fallback_map[name] = value;
    }

    // 3. __priority
    DECODE_U32LEB(priorityCount);
    std::shared_ptr<std::vector<Themed::TransMap>> mapVec =
        std::make_shared<std::vector<Themed::TransMap>>();
    mapVec->resize(priorityCount);
    for (size_t index = 0; index < priorityCount; ++index) {
      DECODE_STDSTR(name);
      auto &transMap = mapVec->at(index);
      transMap.name_ = name;
      transMap.default_ = defaultMap[name];
      transMap.fallback_ = fallback_map[name];
    }

    // 4. path map
    DECODE_U32LEB(pathMapCount);
    for (size_t index = 0; index < pathMapCount; ++index) {
      DECODE_STDSTR(name);
      DECODE_U32LEB(pathCount);
      if (pathCount <= 0) {
        continue;
      }

      // find from mapVec
      Themed::TransMap *pTransMap_ = nullptr;
      for (auto &item : *mapVec) {
        if (item.name_ == name) {
          pTransMap_ = &item;
          break;
        }
      }

      // paths
      for (size_t j = 0; j < pathCount; ++j) {
        DECODE_STDSTR(key);
        DECODE_STDSTR(path);
        if (pTransMap_ == nullptr) {
          continue;
        }
        auto itRes = transFileMap->find(path);
        if (itRes == transFileMap->end()) {
          continue;
        }

        pTransMap_->resMap_.insert({key, itRes->second});
      }
    }
    // add to page
    assemblerThemed.pageTransMaps.insert(
        {std::move(pageId), std::move(mapVec)});
    assemblerThemed.hasTransConfig = true;
  }

  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeElementTemplateSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_ELEMENT_TEMPLATE_SECTION);
  // LazyDecode ElementTemplateSection, just exec DecodeElementTemplateRoute
  // when decode template.
  ERROR_UNLESS(DecodeElementTemplateRoute());
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeElementTemplateRoute() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeElementTemplateRoute");
  DECODE_U32(size);
  element_template_route_.template_ranges_.reserve(size);
  for (size_t i = 0; i < size; ++i) {
    std::string key;
    ERROR_UNLESS(ReadStringDirectly(&key));
    // Template Radnge
    DECODE_U32(start);
    DECODE_U32(end);
    element_template_route_.template_ranges_.insert(
        {key, ElementTemplateRange(start, end)});
  }
  element_template_route_.descriptor_offset_ =
      static_cast<uint32_t>(stream_->offset());
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeElementTemplateInfoInner(
    ElementTemplateInfo &info) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeElementTemplateInfoInner");
  DECODE_U8(size);
  for (int8_t index = 0; index < size; ++index) {
    auto element_info = std::make_shared<ElementInfo>();
    ERROR_UNLESS(DecodeElementInfo(*element_info));
    info.elements_.push_back(element_info);
  }
  info.exist_ = true;
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeElementInfo(ElementInfo &info) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeElementInfo");
  DECODE_U8(section_count);
  for (int8_t index = 0; index < section_count; ++index) {
    DECODE_U32(int_key);
    ElementTemplateEnum enum_key = static_cast<ElementTemplateEnum>(int_key);
    switch (enum_key) {
      case ELEMENT_ID:
      case ELEMENT_TEMP_ID:
      case ELEMENT_ID_SELECTOR:
        ERROR_UNLESS(ReadStringDirectly(&info.id_selector_));
        break;
      case ELEMENT_TAG_STR:
        ERROR_UNLESS(ReadStringDirectly(&info.tag_));
        break;
      case ELEMENT_TAG_ENUM: {
        DECODE_U32(tag);
        info.tag_enum_ = static_cast<ElementBuiltInTagEnum>(tag);
        break;
      }
      case ELEMENT_CHILDREN: {
        DECODE_U32(ary_size);
        for (uint32_t index = 0; index < ary_size; ++index) {
          auto child_info = std::make_shared<ElementInfo>();
          ERROR_UNLESS(DecodeElementInfo(*child_info));
          info.children_.push_back(child_info);
        }
        break;
      }
      case ELEMENT_CLASS: {
        DECODE_U32(ary_size);
        for (uint32_t index = 0; index < ary_size; ++index) {
          std::string class_name;
          ERROR_UNLESS(ReadStringDirectly(&class_name));
          info.class_selector_.push_back(class_name);
        }
        break;
      }
      case ELEMENT_STYLES: {
        DECODE_U32(map_size);
        for (uint32_t index = 0; index < map_size; ++index) {
          DECODE_U32(int_property);
          const auto &key = static_cast<CSSPropertyID>(int_property);
          std::string value;
          ERROR_UNLESS(ReadStringDirectly(&value));
          info.inline_styles_.insert({key, value});
        }
        break;
      }
      case ELEMENT_ATTRIBUTES: {
        DECODE_U32(map_size);
        for (uint32_t index = 0; index < map_size; ++index) {
          std::string name;
          ERROR_UNLESS(ReadStringDirectly(&name));
          DECODE_VALUE_HEADER(value);
          info.attrs_.insert({name, value});
        }
        break;
      }
      case ELEMENT_EVENTS: {
        ERROR_UNLESS(DecodeEvent(info));
        break;
      }
      case ELEMENT_DATA_SET: {
        ERROR_UNLESS(DecodeValue(&info.data_set_, true));
        break;
      }
      case ELEMENT_PARSED_STYLES_KEY: {
        // When read ELEMENT_PARSED_STYLES_KEY, execute GetParsedStyles to get
        // parsed style
        ERROR_UNLESS(ReadStringDirectly(&info.parser_style_key_));
        if (!info.parser_style_key_.empty()) {
          // Mark the offset
          const auto &now_offset = stream_->offset();
          info.has_parser_style_ = true;
          info.parser_style_map_ = GetParsedStyles(info.parser_style_key_);
          // Seek to the offset
          stream_->Seek(now_offset);
        }
        break;
      }
      case ELEMENT_CONFIG: {
        ERROR_UNLESS(DecodeValue(&info.config_, true));
        break;
      }
      default:
        break;
    }
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeEvent(ElementInfo &info) {
  DECODE_U8(size);
  info.events_.assign(size, ElementEventInfo());
  for (uint8_t i = 0; i < size; ++i) {
    ERROR_UNLESS(ReadStringDirectly(&info.events_[i].type_));
    ERROR_UNLESS(ReadStringDirectly(&info.events_[i].name_));
    ERROR_UNLESS(ReadStringDirectly(&info.events_[i].value_));
  }
  return true;
}

std::shared_ptr<ElementTemplateInfo>
LynxBinaryBaseTemplateReader::DecodeElementTemplate(const std::string &key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeElementTemplate");

  // Reset error message
  error_message_.clear();

  // Decode ElementTemplateInfo
  auto info = std::make_shared<ElementTemplateInfo>();
  const auto &iter = element_template_route_.template_ranges_.find(key);
  if (iter == element_template_route_.template_ranges_.end()) {
    return info;
  }
  const auto &start =
      element_template_route_.descriptor_offset_ + iter->second.start;
  stream_->Seek(start);
  DecodeElementTemplateInfoInner(*info);
  info->key_ = key;

  // Log Decode Error
  if (!info->exist_) {
    LOGE("DecodeElementTemplate Error: " << error_message_);
  }

  return info;
}

const StyleMap &LynxBinaryBaseTemplateReader::GetParsedStyles(
    const std::string &key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeParsedStyles");

  auto &parsed_styles_map = GetParsedStyleMap();

  auto iter = parsed_styles_map.find(key);
  if (iter != parsed_styles_map.end()) {
    return *(iter->second);
  }

  // Reset error message
  error_message_.clear();

  auto style_map = std::make_unique<StyleMap>();
  const auto &route_iter = parsed_styles_route_.parsed_styles_ranges_.find(key);
  if (route_iter == parsed_styles_route_.parsed_styles_ranges_.end()) {
    LOGI(
        "DecodeParsedStyles Error, can not find the parsed style, and the key "
        "is: "
        << key);
    auto res = parsed_styles_map.insert({key, std::move(style_map)});
    return *(res.first->second);
  }
  const auto &start =
      parsed_styles_route_.descriptor_offset_ + route_iter->second.start;
  stream_->Seek(start);
  if (!DecodeParsedStylesInner(*style_map)) {
    LOGE("DecodeParsedStyles Error: " << error_message_);
  }
  auto res = parsed_styles_map.insert({key, std::move(style_map)});
  return *(res.first->second);
}

bool LynxBinaryBaseTemplateReader::DecodeParsedStylesSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_PARSED_STYLES_SECTION);
  // LazyDecode, only decode route.
  DECODE_U32(size);
  parsed_styles_route_.parsed_styles_ranges_.reserve(size);
  for (size_t i = 0; i < size; ++i) {
    std::string key;
    ERROR_UNLESS(ReadStringDirectly(&key));
    DECODE_U32(start);
    DECODE_U32(end);
    parsed_styles_route_.parsed_styles_ranges_.insert(
        {key, ParsedStylesRange(start, end)});
  }
  parsed_styles_route_.descriptor_offset_ =
      static_cast<uint32_t>(stream_->offset());
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeParsedStylesInner(
    StyleMap &style_map) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeParsedStylesInner");
  DECODE_U32(size);
  for (uint32_t i = 0; i < size; ++i) {
    DECODE_U32(style_key);
    tasm::CSSValue value;
    DecodeCSSValue(&value, true, true);
    style_map.insert({static_cast<CSSPropertyID>(style_key), value});
  }
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeAirParsedStylesSection() {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeAirStylesSection");
  // Currently LazyDecode is not applied in Air, because this may increase the
  // time of `renderPage` and `updatePage`. LazyDecode could decrease the decode
  // time for sure, but in Air we could solve this by using pre-decode.
  // For other cases, LazyDecode may also be applied in Air later.
  DECODE_U32(size);
  air_parsed_styles_route_.parsed_styles_ranges_.reserve(size);
  for (size_t i = 0; i < size; ++i) {
    std::string component_key;
    ERROR_UNLESS(ReadStringDirectly(&component_key));
    DECODE_U32(css_size);
    std::unordered_map<std::string, AirParsedStylesRange> single_ranges;
    single_ranges.reserve(css_size);
    for (size_t j = 0; j < css_size; ++j) {
      std::string key;
      ERROR_UNLESS(ReadStringDirectly(&key));
      DECODE_U32(start);
      DECODE_U32(end);
      single_ranges.emplace(key, AirParsedStylesRange(start, end));
    }
    air_parsed_styles_route_.parsed_styles_ranges_.emplace(component_key,
                                                           single_ranges);
  }
  air_parsed_styles_route_.descriptor_offset_ =
      static_cast<uint32_t>(stream_->offset());

  auto &air_parsed_styles_map = GetAirParsedStylesMap();
  for (const auto &range : air_parsed_styles_route_.parsed_styles_ranges_) {
    for (const auto &inner_range : range.second) {
      const auto &start = inner_range.second.start +
                          air_parsed_styles_route_.descriptor_offset_;
      stream_->Seek(start);
      auto style_map = std::make_shared<StyleMap>();
      if (!DecodeAirParsedStylesInner(*style_map)) {
        LOGE("DecodeAirParsedStyles Error: " << error_message_);
      }
      air_parsed_styles_map[range.first].emplace(inner_range.first,
                                                 std::move(style_map));
    }
  }
#endif
  return true;
}

bool LynxBinaryBaseTemplateReader::DecodeAirParsedStylesInner(
    StyleMap &style_map) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeAirStylesInner");
  DECODE_U32(raw_size);
  for (uint32_t i = 0; i < raw_size; ++i) {
    DECODE_U32(style_key);
    DECODE_VALUE(style_value);
    if (static_cast<CSSPropertyID>(style_key) == kPropertyIDAnimationName) {
      style_map.insert({static_cast<CSSPropertyID>(style_key),
                        CSSValue(style_value, CSSValuePattern::MAP)});
    } else {
      StyleMap output;
      UnitHandler::Process(
          static_cast<CSSPropertyID>(style_key), style_value, output,
          CSSParserConfigs::GetCSSParserConfigsByComplierOptions(
              compile_options_));
      for (const auto &p : output) {
        style_map.insert({p.first, p.second});
      }
    }
  }
  DECODE_U32(size);
  for (uint32_t i = 0; i < size; ++i) {
    DECODE_U32(style_key);
    tasm::CSSValue value;
    DecodeCSSValue(&value, true, true);
    style_map.insert({static_cast<CSSPropertyID>(style_key), value});
  }
#endif
  return true;
}

}  // namespace tasm
}  // namespace lynx
