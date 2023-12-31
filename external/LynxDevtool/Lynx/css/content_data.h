// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_CSS_CONTENT_DATA_H_
#define LYNX_CSS_CONTENT_DATA_H_

#include <string>

#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace tasm {

class AttributeHolder;

class ContentData {
 public:
  static ContentData* createTextContent(const lepus::String&);
  static ContentData* createImageContent(const std::string&);
  static ContentData* createAttrContent(const AttributeHolder*,
                                        const lepus::String&);

  virtual ~ContentData() {
    if (next_) delete next_;
  }
  virtual bool isText() const { return false; }
  virtual bool isImage() const { return false; }
  virtual bool isAttr() const { return false; }

  ContentData* next() { return next_; }
  void set_next(ContentData* next) { next_ = next; }

 private:
  ContentData* next_ = nullptr;
};

class TextContentData : public ContentData {
  friend class ContentData;

 public:
  TextContentData(const lepus::String& text) : text_(text) {}

  const lepus::String& text() const { return text_; }
  void set_text(const lepus::String& text) { text_ = text; }

  bool isText() const override { return true; }

 private:
  lepus::String text_;
};

class ImageContentData : public ContentData {
 public:
  ImageContentData(const std::string& url) : url_(url) {}

  const std::string& url() const { return url_; }
  void set_url(const std::string& url) { url_ = url; }

  bool isImage() const override { return true; }

 private:
  std::string url_;
};

class AttrContentData : public ContentData {
 public:
  AttrContentData(const AttributeHolder* owner, const lepus::String& text);

  const lepus::Value& attr_content();
  bool isAttr() const override { return true; }

 private:
  const AttributeHolder* attr_owner_;
  const lepus::String attr_key_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CONTENT_DATA_H_
