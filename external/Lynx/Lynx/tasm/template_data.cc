// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tasm/template_data.h"

#include <utility>

namespace lynx {
namespace tasm {

TemplateData::TemplateData(const lepus::Value& value, bool read_only,
                           std::string name)
    : value_(value), processor_name(std::move(name)), read_only_(read_only) {}

TemplateData::TemplateData(const lepus::Value& value, bool read_only)
    : value_(value), read_only_(read_only) {}

const lepus::Value& TemplateData::GetValue() const { return value_; }

const std::string& TemplateData::PreprocessorName() const {
  return processor_name;
}

bool TemplateData::IsReadOnly() const { return read_only_; }

void TemplateData::CloneValue() { value_ = lynx::lepus::Value::Clone(value_); }

}  // namespace tasm
}  // namespace lynx
