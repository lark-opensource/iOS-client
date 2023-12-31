//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "base_binary_reader.h"

#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "lepus/array.h"
#include "lepus/lepus_date.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"
#include "tasm/config.h"

namespace lynx {
namespace lepus {

#if !ENABLE_JUST_LEPUSNG
bool BaseBinaryReader::DeserializeFunction(
    base::scoped_refptr<Function>& parent,
    base::scoped_refptr<Function>& function) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeFunction");
  // const value
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_VALUE(value);
    function->const_values_.push_back(std::move(value));
  }

  // instruction
  ERROR_UNLESS(ReadU32Leb128(&size));
  for (size_t i = 0; i < size; ++i) {
    Instruction instruction;
    DECODE_U64LEB(op_code);
    instruction.op_code_ = static_cast<long>(op_code);
    function->AddInstruction(instruction);
  }

  // up value info
  DECODE_U32LEB(update_value_size);
  for (size_t i = 0; i < update_value_size; ++i) {
    DECODE_STR(name);
    DECODE_U64LEB(reg);
    DECODE_BOOL(in_parent_var);
    function->AddUpvalue(name, static_cast<long>(reg), in_parent_var);
  }

  // switch info
  const char* version = compile_options_.target_sdk_version_.c_str();
  if (version &&
      lynx::tasm::Config::IsHigherOrEqual(version, FEATURE_CONTROL_VERSION_2)) {
    DECODE_U32LEB(switch_info_size);
    for (size_t i = 0; i < switch_info_size; ++i) {
      DECODE_U64LEB(key_type);
      DECODE_U64LEB(min);
      DECODE_U64LEB(max);
      DECODE_U64LEB(default_offset);
      DECODE_U64LEB(switch_table_size);
      DECODE_U64LEB(type);
      std::vector<std::pair<long, long>> vec;
      for (size_t j = 0; j < switch_table_size; j++) {
        DECODE_U64LEB(v1);
        DECODE_U64LEB(v2);
        vec.emplace_back(std::pair<long, long>{v1, v2});
      }
      function->AddSwitch(static_cast<long>(key_type), static_cast<long>(min),
                          static_cast<long>(max),
                          static_cast<long>(default_offset),
                          static_cast<SwitchType>(type), vec);
    }
  }

  func_vec.push_back(function);

  // children
  ERROR_UNLESS(ReadU32Leb128(&size));
  for (size_t i = 0; i < size; ++i) {
    DECODE_FUNCTION(function, child_function);
  }

  if (parent.Get() != nullptr) {
    parent->AddChildFunction(function);
  }
  return true;
}

bool BaseBinaryReader::DeserializeGlobal(
    std::unordered_map<lepus::String, lepus::Value>& global) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeGlobal");
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_STR(name);
    DECODE_VALUE(value);
    global[name] = value;
  }
  return true;
}

bool BaseBinaryReader::DeserializeTopVariables(
    std::unordered_map<lepus::String, long>& top_level_variables) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeTopVariables");
  DECODE_U32LEB(top_size);
  for (size_t i = 0; i < top_size; i++) {
    DECODE_STR(str);
    DECODE_S32LEB(pos);
    top_level_variables.insert(std::make_pair(str, pos));
  }
  return true;
}

bool BaseBinaryReader::DecodeClosure(base::scoped_refptr<Closure>& out_value) {
  uint32_t value_count = 0;
  ERROR_UNLESS(ReadU32Leb128(&value_count));
  uint32_t index = 0;
  ERROR_UNLESS(ReadU32Leb128(&index));
  ERROR_UNLESS(index < func_vec.size());
  out_value->function_ = func_vec[index];
  return true;
}

bool BaseBinaryReader::DecodeRegExp(base::scoped_refptr<RegExp>& reg) {
  DECODE_VALUE(pattern);
  DECODE_VALUE(flags);
  reg->set_pattern(pattern.String());
  reg->set_flags(flags.String());
  return true;
}

bool BaseBinaryReader::DecodeDate(base::scoped_refptr<CDate>& date) {
  tm_extend date_;
  DECODE_S32LEB(language);
  DECODE_S32LEB(ms_);
  DECODE_S32LEB(tm_year);
  DECODE_S32LEB(tm_mon);
  DECODE_S32LEB(tm_mday);
  DECODE_S32LEB(tm_hour);
  DECODE_S32LEB(tm_min);
  DECODE_S32LEB(tm_sec);
  DECODE_S32LEB(tm_wday);
  DECODE_S32LEB(tm_yday);
  DECODE_S32LEB(tm_isdst);
  DECODE_DOUBLE(tm_gmtoff);

  date_.tm_year = tm_year;
  date_.tm_mon = tm_mon;
  date_.tm_mday = tm_mday;
  date_.tm_hour = tm_hour;
  date_.tm_min = tm_min;
  date_.tm_sec = tm_sec;
  date_.tm_wday = tm_wday;
  date_.tm_yday = tm_yday;
  date_.tm_isdst = tm_isdst;
  date_.tm_gmtoff = tm_gmtoff;

  date->SetDate(date_, ms_, language);
  return true;
}
#endif

bool BaseBinaryReader::DeserializeStringSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DeserializeStringSection");
  DECODE_U32LEB(count);
  string_list_count_ = count;
  string_list_.resize(count);
  for (size_t dd = 0; dd < count; dd++) {
    DECODE_U32LEB(length);
    if (length != 0) {
      lynx::base::scoped_refptr<lepus::StringImpl> result =
          lynx::lepus::StringImpl::Create(
              reinterpret_cast<const char*>(stream_->cursor()), length);
      stream_->Seek(stream_->offset() + length);
      string_list_[dd] = std::move(result);
    } else {
      static lepus::String kEmpty = "";
      string_list_[dd] = kEmpty;
    }
  }
  return true;
}

bool BaseBinaryReader::DecodeUtf8Str(
    lynx::base::scoped_refptr<lepus::StringImpl>& result) {
  DECODE_U32LEB(index);
  ERROR_UNLESS(index < string_list_.size());
  result = string_list_[index].impl();
  return true;
}

bool BaseBinaryReader::DecodeUtf8Str(std::string* result) {
  DECODE_U32LEB(index);
  ERROR_UNLESS(index < string_list_.size());
  *result = string_list_[index].str();
  return true;
}

bool BaseBinaryReader::DecodeTable(
    lynx::base::scoped_refptr<Dictionary>& out_value, bool is_header) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    // If encode happens in parsing header stage, nothing in string_list, so
    // read string directly
    if (is_header) {
      std::string temp;
      ERROR_UNLESS(ReadStringDirectly(&temp));
      base::scoped_refptr<lepus::StringImpl> key =
          lepus::StringImpl::Create(std::move(temp));
      DECODE_VALUE_HEADER(value);
      out_value->SetValue(key, std::move(value));
    } else {
      DECODE_STR(key);
      DECODE_VALUE(value);
      out_value->SetValue(key, std::move(value));
    }
  }
  return true;
}

bool BaseBinaryReader::DecodeArray(base::scoped_refptr<CArray>& ary) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; i++) {
    DECODE_VALUE(value);
    ary->push_back(value);
  }
  return true;
}

bool BaseBinaryReader::DecodeValue(Value* result, bool is_header) {
  DECODE_U8(type);
  switch (type) {
    case ValueType::Value_Int32: {
      DECODE_S32LEB(number);
      result->SetNumber(static_cast<int32_t>(number));
    } break;
    case ValueType::Value_UInt32: {
      DECODE_U32LEB(number);
      result->SetNumber(static_cast<uint32_t>(number));
    } break;
    case ValueType::Value_Int64: {
      DECODE_U64LEB(number);
      result->SetNumber(static_cast<int64_t>(number));
    } break;
    case ValueType::Value_Double: {
      DECODE_DOUBLE(number);
      result->SetNumber(number);
    } break;
    case ValueType::Value_Bool: {
      DECODE_BOOL(boolean);
      result->SetBool(boolean);
    } break;
    case ValueType::Value_String: {
      // If encode happens in parsing header stage, nothing in string_list, so
      // read string directly
      if (is_header) {
        std::string temp;
        ERROR_UNLESS(ReadStringDirectly(&temp));
        base::scoped_refptr<lepus::StringImpl> str =
            lepus::StringImpl::Create(std::move(temp));
        result->SetString(str);
      } else {
        DECODE_STR(str);
        result->SetString(str);
      }
    } break;
    case ValueType::Value_Table: {
      DECODE_DICTIONARY(table, is_header);
      result->SetTable(table);
    } break;
    case ValueType::Value_Array: {
      DECODE_ARRAY(ary);
      result->SetArray(ary);
    } break;
#if !ENABLE_JUST_LEPUSNG
    case ValueType::Value_Closure: {
      DECODE_CLOSURE(closure);
      result->SetClosure(closure);
    } break;
    case ValueType::Value_CFunction:
    case ValueType::Value_CPointer:
    case ValueType::Value_RefCounted:
      break;
    case ValueType::Value_Nil:
      break;
    case ValueType::Value_Undefined:
      result->SetUndefined();
      break;
    case ValueType::Value_CDate: {
      DECODE_DATE(date);
      result->SetDate(date);
      break;
    }
    case ValueType::Value_RegExp: {
      DECODE_REGEXP(reg);
      result->SetRegExp(reg);
      break;
    }
    case ValueType::Value_NaN: {
      DECODE_BOOL(NaaN);
      result->SetNan(NaaN);
      break;
    }
#endif
    default:
      break;
  }
  return true;
}

base::scoped_refptr<lepus::StringImpl> BaseBinaryReader::CreateLepusString() {
  return lynx::lepus::StringImpl::Create("");
}

}  // namespace lepus
}  // namespace lynx
