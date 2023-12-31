// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/content_data.h"

#include "tasm/attribute_holder.h"

namespace lynx {
namespace tasm {

ContentData* ContentData::createTextContent(const lepus::String& text) {
  return new TextContentData(text);
}

ContentData* ContentData::createImageContent(const std::string& url) {
  return new ImageContentData(url);
}

ContentData* ContentData::createAttrContent(const AttributeHolder* node,
                                            const lepus::String& attr) {
  return new AttrContentData(node, attr);
}

AttrContentData::AttrContentData(const AttributeHolder* owner,
                                 const lepus::String& attr)
    : attr_owner_(owner), attr_key_(attr) {}

const lepus::Value& AttrContentData::attr_content() {
  static lepus::Value kTempLepusValue = lepus::Value();
  if (attr_owner_ == nullptr) return kTempLepusValue;

  auto& styles = attr_owner_->attributes();
  auto iter = styles.find(attr_key_);
  if (iter != styles.end()) return iter->second.first;

  return kTempLepusValue;
}

// TODO: another type

}  // namespace tasm
}  // namespace lynx
