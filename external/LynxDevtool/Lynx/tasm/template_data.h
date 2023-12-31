// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TEMPLATE_DATA_H_
#define LYNX_TASM_TEMPLATE_DATA_H_

#include <string>

#include "lepus/value-inl.h"

namespace lynx {

namespace lepus {
class Value;
}

namespace tasm {

class TemplateData {
 public:
  TemplateData(const lepus::Value& value, bool read_only,
               std::string preprocessorName);
  TemplateData(const lepus::Value& value, bool read_only);
  const lepus::Value& GetValue() const;
  const std::string& PreprocessorName() const;
  bool IsReadOnly() const;
  void CloneValue();

 private:
  lepus::Value value_;
  std::string processor_name;
  bool read_only_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_DATA_H_
