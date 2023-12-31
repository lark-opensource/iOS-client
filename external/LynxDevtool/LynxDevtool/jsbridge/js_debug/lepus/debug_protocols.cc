// Copyright 2019 The Lynx Authors. All rights reserved.
#include "debug_protocols.h"

#include <utility>

#include "lepus_debugger_tools.h"

namespace debugProtocols {

/// Base Protocol
BaseProtocol::BaseProtocol(std::string script_id, ProtocolType type)
    : dom_(std::make_shared<rapidjson::Document>()),
      script_id_(std::move(script_id)),
      type_(type) {
  dom_->SetObject();
}

BaseProtocol::BaseProtocol(const ProtocolType &type)
    : dom_(std::make_shared<rapidjson::Document>()),
      script_id_("0"),
      type_(type) {
  dom_->SetObject();
}

std::shared_ptr<rapidjson::Document> &BaseProtocol::GetDom() { return dom_; }

void BaseProtocol::GetRetDom(std::shared_ptr<rapidjson::Document> &res) {
  res = std::make_shared<rapidjson::Document>();
  res->SetObject();
}

std::string BaseProtocol::GetReturnMsg() { return GetMessage(); }

std::string BaseProtocol::GetMessage() { return "BaseProtocol"; }

/// PropertyPreview
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyPreview
PropertyPreview::PropertyPreview(const std::string &name,
                                 const std::string &type,
                                 const std::string &value) {
  name_ = name;
  type_ = type;
  value_ = value;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_STRING_VALUE("value", value_, dom_);
}

PropertyPreview::PropertyPreview(const PropertyPreview &preview) {
  name_ = preview.name_;
  type_ = preview.type_;
  value_ = preview.value_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_STRING_VALUE("value", value_, dom_);
}

PropertyPreview &PropertyPreview::operator=(const PropertyPreview &other) {
  name_ = other.name_;
  type_ = other.type_;
  value_ = other.value_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_STRING_VALUE("value", value_, dom_);
  return *this;
}

/// ObjectPreview
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-ObjectPreview
ObjectPreview::ObjectPreview() : overflow_(false){};
ObjectPreview::ObjectPreview(
    const std::string &type, bool overflow, const std::string &description,
    const template_vector<PropertyPreview> &property_previews,
    const std::string &subtype) {
  type_ = type;
  description_ = description;
  overflow_ = overflow;
  subtype_ = subtype;
  property_previews_ = property_previews;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_COMMON_VALUE("overflow", overflow_, dom_);
  ADD_JSON_STRING_VALUE("description", description_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, property_previews_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("properties", vs, dom_);
  if (!subtype_.empty()) {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
}

ObjectPreview::ObjectPreview(const ObjectPreview &preview) {
  type_ = preview.type_;
  description_ = preview.description_;
  overflow_ = preview.overflow_;
  subtype_ = preview.subtype_;
  property_previews_ = preview.property_previews_;
  dom_->SetObject();
  if (subtype_ != "") {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_COMMON_VALUE("overflow", overflow_, dom_);
  ADD_JSON_STRING_VALUE("description", description_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, property_previews_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("properties", vs, dom_);
}

ObjectPreview &ObjectPreview::operator=(const ObjectPreview &other) {
  type_ = other.type_;
  description_ = other.description_;
  overflow_ = other.overflow_;
  subtype_ = other.subtype_;
  property_previews_ = other.property_previews_;
  dom_->SetObject();
  if (subtype_ != "") {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_COMMON_VALUE("overflow", overflow_, dom_);
  ADD_JSON_STRING_VALUE("description", description_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, property_previews_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("properties", vs, dom_);
  return *this;
}

std::string ObjectPreview::GetDescription() { return description_; }

/// RemoteObject
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-RemoteObject

// scope object initialization with object type and object id
RemoteObject::RemoteObject(std::string type, const std::string &object_id) {
  type_ = std::move(type);
  object_id_ = object_id;
  value_ = lynx::lepus::Value();
  description_ = "";
  class_name_ = "";
  subtype_ = "";
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  // only object has real objectId
  if (object_id_ != "-1") {
    ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  }
}

// input: lepus value, output: corresponding value type
std::string RemoteObject::GetType(const lynx::lepus::Value &value) {
  std::string type = "other";
  switch (value.Type()) {
    case lynx::lepus::Value_String: {
      type = "string";
      break;
    }
    case lynx::lepus::Value_Bool: {
      type = "boolean";
      break;
    }
    case lynx::lepus::Value_Int32:
    case lynx::lepus::Value_UInt32:
    case lynx::lepus::Value_UInt64: {
      type = "number";
      break;
    }
    case lynx::lepus::Value_Int64: {
      type = "number";
      break;
    }
    case lynx::lepus::Value_Closure: {
      type = "function";
      break;
    }
    case lynx::lepus::Value_CFunction: {
      type = "function";
      break;
    }
    case lynx::lepus::Value_CPointer: {
      type = "function";
      break;
    }
    case lynx::lepus::Value_RefCounted: {
      type = "function";
      break;
    }
    case lynx::lepus::Value_Table: {
      type = "object";
      break;
    }
    case lynx::lepus::Value_Array: {
      type = "object";
      break;
    }
    case lynx::lepus::Value_RegExp: {
      type = "object";
      break;
    }
    case lynx::lepus::Value_CDate: {
      type = "object";
      break;
    }
    case lynx::lepus::Value_Undefined:
    case lynx::lepus::Value_Nil: {
      type = "undefined";
      break;
    }
    default: {
      LOGI("other type" << value.Type());
      break;
    }
  }
  return type;
}

// input: lepus value, output: corresponding value in string type
std::string RemoteObject::GetValueStr(const lynx::lepus::Value &value) {
  std::string value_str = "";
  switch (value.Type()) {
    case lynx::lepus::Value_String: {
      value_str = value.String()->str();
      break;
    }
    case lynx::lepus::Value_Bool: {
      if (value.Bool()) {
        value_str = "true";
      } else {
        value_str = "false";
      }
      break;
    }
    case lynx::lepus::Value_Int32:
    case lynx::lepus::Value_UInt32:
    case lynx::lepus::Value_UInt64: {
      value_str = std::to_string(value.Number());
      break;
    }
    case lynx::lepus::Value_Int64: {
      value_str = std::to_string(value.Int64());
      break;
    }
    case lynx::lepus::Value_Closure: {
      value_str = lynx::lepus::DebugTool::GetFunctionSourceCode(
          value.GetClosure()->function(), false);
      break;
    }
    case lynx::lepus::Value_CFunction: {
      value_str = "function source";
      break;
    }
    case lynx::lepus::Value_Table: {
      value_str = "object";
      break;
    }
    case lynx::lepus::Value_Array: {
      value_str = "object";
      break;
    }
    case lynx::lepus::Value_RegExp: {
      value_str = "object";
      break;
    }
    case lynx::lepus::Value_CDate: {
      value_str = "object";
      break;
    }
    case lynx::lepus::Value_Undefined:
    case lynx::lepus::Value_Nil: {
      value_str = "undefined";
      break;
    }
    default: {
      break;
    }
  }
  return value_str;
}

// if this value is a function, use this SetFunctionInfo to get function
// information
void RemoteObject::SetFunctionInfo() {
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  // description: function source
  description_ = lynx::lepus::DebugTool::GetFunctionSourceCode(
      value_.GetClosure()->function(), false);
  rapidjson::Value str_desc;
  ADD_JSON_STRING_VALUE2("description", description_, dom_);
  // className: function name
  class_name_ = value_.GetClosure()->function()->GetFunctionName();
  ADD_JSON_STRING_VALUE2("className", class_name_, dom_);
}

// if this value is an object, call SetObjectInfo to get object information
void RemoteObject::SetObjectInfo() {
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  // description: "Object"
  description_ = "Object";
  ADD_JSON_STRING_VALUE2("description", description_, dom_);

  // className: "Object"
  class_name_ = "Object";
  ADD_JSON_STRING_VALUE2("className", class_name_, dom_);

  // get property previews(name, type, value_str)
  template_vector<PropertyPreview> property_previews;
  for (auto &iter : *value_.Table()) {
    debugProtocols::PropertyPreview preview(
        iter.first.str(), GetType(iter.second), GetValueStr(iter.second));
    property_previews.push_back(preview);
  }

  // get object preivew:
  // (type, overflow, description, property previews)
  if (!property_previews.empty()) {
    preview_ = ObjectPreview("object", false, "Object", property_previews);
  }
}

// if this value is an array, call SetObjectInfo to get array information
void RemoteObject::SetArrayInfo() {
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);

  // description: "Array(size)"
  description_ = "Array(" + std::to_string(value_.Array()->size()) + ")";
  ADD_JSON_STRING_VALUE2("description", description_, dom_);

  // className: "Array"
  class_name_ = "Array";
  ADD_JSON_STRING_VALUE2("className", class_name_, dom_);
  // subtype: "array"
  subtype_ = "array";
  // get array property preview:
  // (name, type, value)
  template_vector<PropertyPreview> property_previews;
  for (size_t i = 0; i < value_.Array()->size(); i++) {
    PropertyPreview preview(std::to_string(i), GetType(value_.Array()->get(i)),
                            GetValueStr(value_.Array()->get(i)));
    property_previews.push_back(preview);
  }
  // get object preview
  // (type, overflow, description, property_previews, subtype)
  preview_ = ObjectPreview(
      "object", false, "Array(" + std::to_string(value_.Array()->size()) + ")",
      property_previews, subtype_);
}

// if this value is a Date, call SetObjectInfo to get Date information
void RemoteObject::SetDateInfo() {
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  std::stringstream ss;
  value_.Date()->print(ss);
  // description: ""%Y-%m-%dT%H:%M:%S."
  description_ = ss.str();
  ADD_JSON_STRING_VALUE2("description", description_, dom_);

  // className: "Date"
  class_name_ = "Date";
  ADD_JSON_STRING_VALUE2("className", class_name_, dom_);

  // subtype: "date"
  subtype_ = "date";
  // property_preview: {}
  template_vector<PropertyPreview> property_previews;
  PropertyPreview preview;
  property_previews.push_back(preview);
  preview_ =
      ObjectPreview("object", false, description_, property_previews, subtype_);
}

// if this value is an regexp, call SetObjectInfo to get regexp information
void RemoteObject::SetRegExpInfo() {
#if !ENABLE_JUST_LEPUSNG
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  // description: pattern/flag
  if (value_.RegExp()->get_flags().str() != "") {
    description_ = value_.RegExp()->get_pattern().str() + "/" +
                   value_.RegExp()->get_flags().str();
  } else {
    description_ = value_.RegExp()->get_pattern().str();
  }

  ADD_JSON_STRING_VALUE2("description", description_, dom_);
  // className: "RegExp"
  class_name_ = "RegExp";
  ADD_JSON_STRING_VALUE2("className", class_name_, dom_);
  // subtype: "regexp"
  subtype_ = "regexp";
  template_vector<PropertyPreview> property_previews;
  // propertyPreview: (name, type, value)
  PropertyPreview preview("lastIndex", "number", "0");
  // objectpreview():
  preview_ =
      ObjectPreview("object", false, description_, property_previews, subtype_);
#endif
}

// getproperties initialization
// objectId only available when it is an object
RemoteObject::RemoteObject(const lynx::lepus::Value &value,
                           std::string object_id) {
  value_ = value;
  description_ = "";
  class_name_ = "";
  object_id_ = object_id;
  dom_->SetObject();
  preview_ = ObjectPreview();
  switch (value_.Type()) {
    case lynx::lepus::Value_String: {
      ADD_JSON_STRING_VALUE("value", value_.String()->str(), dom_);
      break;
    }
    case lynx::lepus::Value_Bool: {
      ADD_JSON_COMMON_VALUE("value", value_.Bool(), dom_);
      break;
    }
    case lynx::lepus::Value_Int32:
    case lynx::lepus::Value_UInt32:
    case lynx::lepus::Value_UInt64: {
      description_ = std::to_string(value_.Number());
      ADD_JSON_COMMON_VALUE("value", value_.Number(), dom_);
      ADD_JSON_STRING_VALUE("description", description_, dom_);
      break;
    }
    case lynx::lepus::Value_Int64: {
      description_ = std::to_string(value_.Int64());
      ADD_JSON_COMMON_VALUE("value", value_.Int64(), dom_);
      ADD_JSON_STRING_VALUE("description", description_, dom_);
      break;
    }
    case lynx::lepus::Value_Closure: {
      SetFunctionInfo();
      break;
    }
    case lynx::lepus::Value_Table: {
      SetObjectInfo();
      break;
    }
    case lynx::lepus::Value_Array: {
      SetArrayInfo();
      break;
    }
    case lynx::lepus::Value_CDate: {
      SetDateInfo();
      break;
    }
    case lynx::lepus::Value_RegExp: {
      SetRegExpInfo();
      break;
    }
    case lynx::lepus::Value_Undefined:
    case lynx::lepus::Value_Nil: {
      rapidjson::Value str_und;
      str_und.SetString("undefined", strlen("undefined"), dom_->GetAllocator());
      dom_->AddMember("value", str_und, dom_->GetAllocator());
      break;
    }
    default: {
      break;
    }
  }

  type_ = GetType(value_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);

  if (preview_.GetDescription() != "") {
    ADD_JSON_OBJECT_VALUE("preview", preview_, dom_);
  }
  if (subtype_ != "") {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
}

RemoteObject::RemoteObject(const RemoteObject &object) {
  type_ = object.type_;
  value_ = object.value_;
  object_id_ = object.object_id_;
  description_ = object.description_;
  class_name_ = object.class_name_;
  preview_ = object.preview_;
  subtype_ = object.subtype_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  if (object_id_ != "-1") {
    ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  }
  if (description_ != "") {
    ADD_JSON_STRING_VALUE("description", description_, dom_);
  }
  if (class_name_ != "") {
    ADD_JSON_STRING_VALUE("className", class_name_, dom_);
  }
  if (preview_.GetDescription() != "") {
    ADD_JSON_OBJECT_VALUE("preview", preview_, dom_);
  }
  if (subtype_ != "") {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
  switch (value_.Type()) {
    case lynx::lepus::Value_String: {
      ADD_JSON_STRING_VALUE("value", value_.String()->str(), dom_);
      break;
    }
    case lynx::lepus::Value_Bool: {
      ADD_JSON_COMMON_VALUE("value", value_.Bool(), dom_);
      break;
    }
    case lynx::lepus::Value_Int32:
    case lynx::lepus::Value_UInt32:
    case lynx::lepus::Value_UInt64: {
      ADD_JSON_COMMON_VALUE("value", value_.Number(), dom_);
      break;
    }
    case lynx::lepus::Value_Int64: {
      ADD_JSON_COMMON_VALUE("value", value_.Int64(), dom_);
      break;
    }
    default:
      break;
  }
}

RemoteObject &RemoteObject::operator=(const RemoteObject &other) {
  value_ = other.value_;
  object_id_ = other.object_id_;
  type_ = other.type_;
  description_ = other.description_;
  class_name_ = other.class_name_;
  preview_ = other.preview_;
  subtype_ = other.subtype_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  if (object_id_ != "-1") {
    ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
  }
  if (description_ != "") {
    ADD_JSON_STRING_VALUE("description", description_, dom_);
  }
  if (class_name_ != "") {
    ADD_JSON_STRING_VALUE("className", class_name_, dom_);
  }
  if (preview_.GetDescription() != "") {
    ADD_JSON_OBJECT_VALUE("preview", preview_, dom_);
  }
  if (subtype_ != "") {
    ADD_JSON_STRING_VALUE("subtype", subtype_, dom_);
  }
  switch (value_.Type()) {
    case lynx::lepus::Value_String: {
      ADD_JSON_STRING_VALUE("value", value_.String()->str(), dom_);
      break;
    }
    case lynx::lepus::Value_Bool: {
      ADD_JSON_COMMON_VALUE("value", value_.Bool(), dom_);
      break;
    }
    case lynx::lepus::Value_Int32:
    case lynx::lepus::Value_UInt32:
    case lynx::lepus::Value_UInt64: {
      ADD_JSON_COMMON_VALUE("value", value_.Number(), dom_);
      break;
    }
    case lynx::lepus::Value_Int64: {
      ADD_JSON_COMMON_VALUE("value", value_.Int64(), dom_);
      break;
    }
    default: {
      break;
    }
  }
  return *this;
}

/// propertyDescriptor
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyDescriptor
PropertyDescriptor::PropertyDescriptor(std::string name,
                                       const RemoteObject &value,
                                       bool configurable, bool enumerable) {
  name_ = std::move(name);
  value_ = value;
  configurable_ = configurable;
  enumerable_ = enumerable;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_OBJECT_VALUE("value", value_, dom_);
  ADD_JSON_COMMON_VALUE("configurable", configurable_, dom_);
  ADD_JSON_COMMON_VALUE("enumerable", enumerable_, dom_);
}

PropertyDescriptor::PropertyDescriptor(const PropertyDescriptor &other) {
  name_ = other.name_;
  value_ = other.value_;
  configurable_ = other.configurable_;
  enumerable_ = other.enumerable_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_OBJECT_VALUE("value", value_, dom_);
  ADD_JSON_COMMON_VALUE("configurable", configurable_, dom_);
  ADD_JSON_COMMON_VALUE("enumerable", enumerable_, dom_);
}

PropertyDescriptor &PropertyDescriptor::operator=(
    const PropertyDescriptor &other) {
  value_ = other.value_;
  name_ = other.name_;
  configurable_ = other.configurable_;
  enumerable_ = other.enumerable_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("name", name_, dom_);
  ADD_JSON_OBJECT_VALUE("value", value_, dom_);
  ADD_JSON_COMMON_VALUE("configurable", configurable_, dom_);
  ADD_JSON_COMMON_VALUE("enumerable", enumerable_, dom_);
  return *this;
}

/// getProperties
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-getProperties
GetProperties::GetProperties() : BaseProtocol(ProtocolType::Runtime) {}

GetProperties::GetProperties(const std::string &object_id)
    : BaseProtocol(ProtocolType::Runtime), object_id_(object_id) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("objectId", object_id_, dom_);
}

void GetProperties::InitReturn(const std::string &name,
                               const RemoteObject &object) {
  ret_.AddResult(name, object);
}

GetProperties::Return::Return() {
  dom_->SetObject();
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, result_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("result", vs, dom_);
}

void GetProperties::Return::AddResult(const std::string &name,
                                      const RemoteObject &object) {
  result_.emplace_back(name, object, true, true);
}

std::shared_ptr<rapidjson::Document> &GetProperties::Return::GetDom() {
  dom_->SetObject();
  rapidjson::Value rs(rapidjson::Type::kArrayType);
  if (dom_->HasMember("result")) dom_->RemoveMember("result");
  ADD_JSON_OBJECT_ARRAY(rs, result_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("result", rs, dom_);
  return dom_;
}

/// enable
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-enable
Enable::Enable() : BaseProtocol(ProtocolType::Debug) {}

Enable::Enable(int32_t max_size) : BaseProtocol(ProtocolType::Debug) {}

std::string Enable::GetReturnMsg() { return ret_.GetMessage(); }

Enable::Return::Return(int32_t debugger_id)
    : debugger_id_(std::to_string(debugger_id)) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("debuggerId", debugger_id_, dom_);
}

void Enable::InitReturn(int32_t debugger_id) {
  ret_.SetDebuggerId(debugger_id);
}

void Enable::Return::SetDebuggerId(int32_t debugger_id) {
  debugger_id_ = std::to_string(debugger_id);
  if (dom_->HasMember("debuggerId")) dom_->RemoveMember("debuggerId");
  ADD_JSON_STRING_VALUE("debuggerId", debugger_id_, dom_);
}

/// ScriptPosition
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-ScriptPosition
ScriptPosition::ScriptPosition() : line_number_(-1), column_number_(-1) {}

ScriptPosition::ScriptPosition(const ScriptPosition &position) {
  line_number_ = position.line_number_;
  column_number_ = position.column_number_;
  dom_->SetObject();
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
}

ScriptPosition &ScriptPosition::operator=(const ScriptPosition &other) {
  line_number_ = other.line_number_;
  column_number_ = other.column_number_;
  dom_->SetObject();
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  return *this;
}

/// LocationRange
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-LocationRange
LocationRange::LocationRange()
    : script_id_("0"), start_(ScriptPosition()), end_(ScriptPosition()) {}

LocationRange::LocationRange(const LocationRange &location) {
  script_id_ = location.script_id_;
  start_ = location.start_;
  end_ = location.end_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_OBJECT_VALUE("start", start_, dom_);
  ADD_JSON_OBJECT_VALUE("end", end_, dom_);
}

LocationRange &LocationRange::operator=(const LocationRange &other) {
  script_id_ = other.script_id_;
  start_ = other.start_;
  end_ = other.end_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_OBJECT_VALUE("start", start_, dom_);
  ADD_JSON_OBJECT_VALUE("end", end_, dom_);
  return *this;
}

/// StepInto
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepInto
StepInto::StepInto() : BaseProtocol(ProtocolType::Debug) { dom_->SetObject(); }

/// stepOver
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepOver
StepOver::StepOver() : BaseProtocol(ProtocolType::Debug) { dom_->SetObject(); }

/// resume
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-resume
Resume::Resume() : BaseProtocol(ProtocolType::Debug) {}

/// getScriptSource
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getScriptSource
void GetScriptSource::InitReturn(const std::string &script_source) {
  ret_.SetSource(script_source);
}

GetScriptSource::GetScriptSource() : script_id_("0") {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
}

GetScriptSource::GetScriptSource(std::string script_id)
    : script_id_(std::move(script_id)) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
}

std::string GetScriptSource::GetReturnMsg() { return ret_.GetMessage(); }

GetScriptSource::Return::Return(std::string script_source)
    : script_source_(script_source) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptSource", script_source_, dom_);
}

void GetScriptSource::Return::SetSource(const std::string &script_source) {
  script_source_ = std::move(script_source);
  if (dom_->HasMember("scriptSource")) dom_->RemoveMember("scriptSource");
  ADD_JSON_STRING_VALUE("scriptSource", script_source_, dom_);
}

/// Location
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
Location::Location() : script_id_("0"), line_number_(-1), column_number_(-1) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
}

Location::Location(std::string script_id, int32_t line_number,
                   int32_t column_number) {
  script_id_ = std::move(script_id);
  line_number_ = line_number;
  column_number_ = column_number;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
}

Location::Location(const Location &location) {
  script_id_ = location.script_id_;
  line_number_ = location.line_number_;
  column_number_ = location.column_number_;

  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
}

Location &Location::operator=(const Location &other) {
  script_id_ = other.script_id_;
  line_number_ = other.line_number_;
  column_number_ = other.column_number_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  return *this;
}

/// Scope
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
Scope::Scope(const std::string &type, const RemoteObject &object) {
  type_ = type;
  object_ = object;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_OBJECT_VALUE("object", object_, dom_);
}

Scope::Scope(const Scope &scope) {
  type_ = scope.type_;
  object_ = scope.object_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_OBJECT_VALUE("object", object_, dom_);
}

Scope &Scope::operator=(const Scope &other) {
  object_ = other.object_;
  type_ = other.type_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  ADD_JSON_OBJECT_VALUE("object", object_, dom_);
  return *this;
}

/// CallFrame
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-CallFrame
// construct debugger callframe
CallFrame::CallFrame(std::string callframe_id, std::string function_name,
                     const Location &location, std::string url,
                     template_vector<Scope> scope_chain,
                     const RemoteObject &this_object)
    : call_frame_id_(std::move(callframe_id)),
      function_name_(std::move(function_name)),
      location_(location),
      url_(std::move(url)),
      scope_chain_(std::move(scope_chain)),
      this_object_(this_object) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("callFrameId", call_frame_id_, dom_);
  ADD_JSON_STRING_VALUE("functionName", function_name_, dom_);
  ADD_JSON_OBJECT_VALUE("location", location_, dom_);
  ADD_JSON_STRING_VALUE("url", url_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, scope_chain_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("scopeChain", vs, dom_);
  ADD_JSON_OBJECT_VALUE("this", this_object_, dom_);
}

CallFrame::CallFrame(const CallFrame &callframe) {
  call_frame_id_ = callframe.call_frame_id_;
  function_name_ = callframe.function_name_;
  location_ = callframe.location_;
  url_ = callframe.url_;
  this_object_ = callframe.this_object_;
  scope_chain_ = callframe.scope_chain_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("callFrameId", call_frame_id_, dom_);
  ADD_JSON_STRING_VALUE("functionName", function_name_, dom_);
  ADD_JSON_OBJECT_VALUE("location", location_, dom_);
  ADD_JSON_STRING_VALUE("url", url_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, scope_chain_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("scopeChain", vs, dom_);
  ADD_JSON_OBJECT_VALUE("this", this_object_, dom_);
}

CallFrame &CallFrame::operator=(const CallFrame &other) {
  call_frame_id_ = other.call_frame_id_;
  function_name_ = other.function_name_;
  location_ = other.location_;
  url_ = other.url_;
  scope_chain_ = other.scope_chain_;
  this_object_ = other.this_object_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("callFrameId", call_frame_id_, dom_);
  ADD_JSON_STRING_VALUE("functionName", function_name_, dom_);
  ADD_JSON_OBJECT_VALUE("location", location_, dom_);
  ADD_JSON_STRING_VALUE("url", url_, dom_);
  rapidjson::Value vs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(vs, scope_chain_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("scopeChain", vs, dom_);
  ADD_JSON_OBJECT_VALUE("this", this_object_, dom_);
  return *this;
}

/// paused: use callframes and reason to construct paused event
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
Paused::Paused(const lynx::lepus::Value &callframes,
               const std::string &reason) {
  size_t callframe_size = callframes.Array()->size();
  template_vector<CallFrame> callframes_result;
  for (size_t i = 0; i < callframe_size; i++) {
    lynx::lepus::Value callframe = callframes.Array()->get(i);
    std::string callframe_id =
        std::to_string(callframe.Table()->GetValue("callFrameId").Int32());
    std::string function_name =
        callframe.Table()->GetValue("functionName").String()->str();

    // get callframe location
    Location callframe_location = GetCallframeLocation(callframe);

    // get callframe scope chain
    template_vector<Scope> scopes;
    scopes = GetCallFrameScopeChain(callframe);

    lynx::lepus::Value this_ = callframe.Table()->GetValue("this");
    std::string this_object_id =
        std::to_string(this_.Table()->GetValue("objectId").Int32());
    lynx::lepus::Value obj(lynx::lepus::Dictionary::Create());
    RemoteObject this_object(obj, this_object_id);

    std::string url = callframe.Table()->GetValue("url").String()->str();
    CallFrame callframe_result(callframe_id, function_name, callframe_location,
                               url, scopes, this_object);
    callframes_result.push_back(callframe_result);
  }
  callframes_ = callframes_result;
  reason_ = reason;
  dom_->SetObject();
  rapidjson::Value cs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(cs, callframes_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("callFrames", cs, dom_);
  ADD_JSON_STRING_VALUE("reason", reason_, dom_);
}

Paused::Paused(template_vector<CallFrame> callframes, std::string reason)
    : callframes_(std::move(callframes)), reason_(std::move(reason)) {
  dom_->SetObject();
  rapidjson::Value cs(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(cs, callframes_, dom_, GetObject());
  ADD_JSON_STRING_VALUE("reason", reason_, dom_);
}

// Location ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
// get the location info from callframes
Location Paused::GetCallframeLocation(const lynx::lepus::Value &callframe) {
  lynx::lepus::Value location = callframe.Table()->GetValue("location");
  lynx::lepus::Value ln = location.Table()->GetValue("lineNumber");
  lynx::lepus::Value cn = location.Table()->GetValue("columnNumber");
  int64_t line_number = 0, col_number = 0;
  if (ln.IsNumber() && cn.IsNumber()) {
    line_number = static_cast<int64_t>(ln.Number());
    col_number = static_cast<int64_t>(cn.Number());
  }
  std::string scriptId = location.Table()->GetValue("scriptId").String()->str();
  Location callframe_location(scriptId, static_cast<int32_t>(line_number),
                              static_cast<int32_t>(col_number));
  return callframe_location;
}

// scope ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
// get scope chain(vector of scope) from callframes
template_vector<Scope> Paused::GetCallFrameScopeChain(
    const lynx::lepus::Value &callframe) {
  template_vector<Scope> result;
  lynx::lepus::Value scope_chain = callframe.Table()->GetValue("scopeChain");
  size_t scope_size = scope_chain.Array()->size();
  for (size_t j = 0; j < scope_size; j++) {
    lynx::lepus::Value scope_info = scope_chain.Array()->get(j);
    std::string scope_type =
        scope_info.Table()->GetValue("type").String()->str();
    lynx::lepus::Value scope_object = scope_info.Table()->GetValue("object");
    std::string object_type =
        scope_object.Table()->GetValue("type").String()->str();
    std::string object_id =
        std::to_string(scope_object.Table()->GetValue("objectId").Int32());
    RemoteObject object(object_type, object_id);
    Scope scope(scope_type, object);
    result.push_back(scope);
  }
  return result;
}

/// scriptParsed
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-scriptParsed
ScriptParsed::ScriptParsed(std::string script_id, std::string url,
                           int32_t start_line, int32_t start_column,
                           int32_t end_line, int32_t end_column, int32_t eid,
                           std::string hash)
    : script_id_(std::move(script_id)),
      url_(std::move(url)),
      start_line_(start_line),
      start_column_(start_column),
      end_line_(end_line),
      end_column_(end_column),
      execution_context_id_(eid),
      hash_(std::move(hash)) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_STRING_VALUE("url", url_, dom_);
  ADD_JSON_COMMON_VALUE("startLine", start_line_, dom_);
  ADD_JSON_COMMON_VALUE("startColumn", start_column_, dom_);
  ADD_JSON_COMMON_VALUE("endLine", end_line_, dom_);
  ADD_JSON_COMMON_VALUE("endColumn", end_column_, dom_);
  ADD_JSON_COMMON_VALUE("executionContextId", execution_context_id_, dom_);
  ADD_JSON_STRING_VALUE("hash", hash_, dom_);
}

/// setBreakpointsActive
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
SetBreakpointsActive::SetBreakpointsActive(bool active) : active_(active) {
  dom_->SetObject();
  ADD_JSON_COMMON_VALUE("active", active_, dom_);
}

/// setBreakpointByUrl
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
SetBreakpointByUrl::SetBreakpointByUrl() : line_number_(0), column_number_(0) {}

SetBreakpointByUrl::SetBreakpointByUrl(int32_t line_number, std::string url,
                                       std::string url_regex, std::string hash,
                                       int32_t column_number,
                                       std::string condition)
    : line_number_(line_number),
      url_(std::move(url)),
      url_regex_(std::move(url_regex)),
      script_hash_(std::move(hash)),
      column_number_(column_number),
      condition_(std::move(condition)) {
  dom_->SetObject();
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_STRING_VALUE("url", url_, dom_);
  ADD_JSON_STRING_VALUE("urlRegex", url_regex_, dom_);
  ADD_JSON_STRING_VALUE("scriptHash", script_hash_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  ADD_JSON_STRING_VALUE("condition", condition_, dom_);
}

SetBreakpointByUrl::Return::Return() {
  breakpoint_id_ = "";
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("breakpointId", breakpoint_id_, dom_);
  rapidjson::Value locations(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(locations, locations_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("locations", locations, dom_);
};

SetBreakpointByUrl::Return::Return(std::string breakpoint_id,
                                   template_vector<Location> locations)
    : breakpoint_id_(std::move(breakpoint_id)),
      locations_(std::move(locations)) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("breakpointId", breakpoint_id_, dom_);
  rapidjson::Value ls(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(ls, locations_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("locations", ls, dom_);
}

std::shared_ptr<rapidjson::Document> &SetBreakpointByUrl::Return::GetDom() {
  dom_->SetObject();
  if (dom_->HasMember("breakpointId")) dom_->RemoveMember("breakpointId");
  if (dom_->HasMember("locations")) dom_->RemoveMember("locations");
  ADD_JSON_STRING_VALUE("breakpointId", breakpoint_id_, dom_);
  rapidjson::Value ls(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(ls, locations_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("locations", ls, dom_);
  return dom_;
}

/// Breakpoint location
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-BreakLocation
BreakLocation::BreakLocation(int32_t line_number, int32_t column_number,
                             std::string type)
    : line_number_(line_number),
      column_number_(column_number),
      type_(std::move(type)) {
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
}

BreakLocation::BreakLocation(const BreakLocation &break_location) {
  script_id_ = break_location.script_id_;
  line_number_ = break_location.line_number_;
  column_number_ = break_location.column_number_;
  type_ = break_location.type_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
}

BreakLocation &BreakLocation::operator=(const BreakLocation &break_location) {
  script_id_ = break_location.script_id_;
  line_number_ = break_location.line_number_;
  column_number_ = break_location.column_number_;
  type_ = break_location.type_;
  dom_->SetObject();
  ADD_JSON_STRING_VALUE("scriptId", script_id_, dom_);
  ADD_JSON_COMMON_VALUE("lineNumber", line_number_, dom_);
  ADD_JSON_COMMON_VALUE("columnNumber", column_number_, dom_);
  ADD_JSON_STRING_VALUE("type", type_, dom_);
  return *this;
}

/// getPossibleBreakpoints
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getPossibleBreakpoints
GetPossibleBreakpoints::GetPossibleBreakpoints(const Location &start,
                                               const Location &end,
                                               bool restrict_to_function)
    : start_(start), end_(end), restrict_to_function_(restrict_to_function) {
  dom_->SetObject();
  ADD_JSON_OBJECT_VALUE("start", start_, dom_);
  ADD_JSON_OBJECT_VALUE("end", end_, dom_);
  ADD_JSON_COMMON_VALUE("restrictToFunction", restrict_to_function_, dom_);
}

void GetPossibleBreakpoints::AddRetLocations(
    const BreakLocation &break_location) {
  ret_.AddLocations(break_location);
}

void GetPossibleBreakpoints::GetRetDom(
    std::shared_ptr<rapidjson::Document> &ret) {
  ret = ret_.GetDom();
}

GetPossibleBreakpoints::Return::Return() {
  dom_->SetObject();
  rapidjson::Value locations(rapidjson::Type::kArrayType);
  ADD_JSON_OBJECT_ARRAY(locations, locations_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("locations", locations, dom_);
}

void GetPossibleBreakpoints::Return::AddLocations(
    const BreakLocation &break_location) {
  locations_.emplace_back(break_location);
}

std::shared_ptr<rapidjson::Document> &GetPossibleBreakpoints::Return::GetDom() {
  dom_->SetObject();
  rapidjson::Value locations(rapidjson::Type::kArrayType);
  if (dom_->HasMember("locations")) dom_->RemoveMember("locations");
  ADD_JSON_OBJECT_ARRAY(locations, locations_, dom_, GetObject());
  ADD_JSON_COMMON_VALUE("locations", locations, dom_);
  return dom_;
}

/// removeBreakpoint
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-removeBreakpoint
RemoveBreakpoint::RemoveBreakpoint(std::string breakpoint_id)
    : breakpoint_id_(std::move(breakpoint_id)) {}
}  // namespace debugProtocols
