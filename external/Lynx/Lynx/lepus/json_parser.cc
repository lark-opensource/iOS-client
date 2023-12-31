// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus/json_parser.h"

#include <algorithm>
#include <map>
#include <sstream>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/lepus_date.h"
#include "lepus/table.h"
#include "tasm/lynx_trace_event.h"
namespace lynx {
namespace lepus {

std::string readFile(const char* file) {
  FILE* pf = fopen(file, "r");
  if (pf == nullptr) {
    return "";
  }

  fseek(pf, 0, SEEK_END);
  long lSize = ftell(pf);
  DCHECK(lSize >= 0);

  std::unique_ptr<char[]> text = std::make_unique<char[]>(lSize + 1);
  // printf("file: %s size: %ld\n", file, lSize);
  if (text != nullptr) {
    rewind(pf);
    fread(text.get(), sizeof(char), lSize, pf);
    text.get()[lSize] = '\0';
    std::string content(text.get());
    // printf("str size:%s, if %d\n", content.c_str(), content.size());
    fclose(pf);
    return content;
  }

  fclose(pf);
  return "";
}

std::string writeFile(const uint8_t* content, const char* file, int len,
                      size_t& string_section_size) {
  FILE* pf = fopen(file, "wb");
  if (pf == nullptr) {
    return "create file failed!";
  }
  const uint8_t* current = content;
  size_t version = 2 * sizeof(uint32_t) + 1;
  (void)fwrite(current, version, 1, pf);

  (void)fwrite(current + string_section_size, len - string_section_size, 1, pf);

  (void)fwrite(current + version, string_section_size - version, 1, pf);
  fclose(pf);
  return "";
}

lepus_value jsonValueTolepusValue(const char* json) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "jsonValueTolepusValue");
  rapidjson::Document document;
  if (document.Parse(json).HasParseError()) {
    LOGE("error: source is not valid json file! msg:"
         << document.GetParseErrorMsg()
         << ", position: " << document.GetErrorOffset());
    return lepus_value();
  }

  return jsonValueTolepusValue(document);
}

lepus_value jsonValueTolepusValue(const rapid_value& rapValue) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "rapidJsonValueTolepusValue");
  rapidjson::Type type = rapValue.GetType();
  switch (type) {
    case rapidjson::Type::kNullType:
      /* code */  //???
      break;
    case rapidjson::Type::kFalseType:
      return lepus_value(false);
    case rapidjson::Type::kTrueType:
      return lepus_value(true);
    case rapidjson::Type::kNumberType: {
      if (rapValue.IsInt64()) {
        return lepus_value(rapValue.GetInt64());
      } else {
        return lepus_value(rapValue.GetDouble());
      }
    }
    case rapidjson::Type::kStringType: {
      lynx::base::scoped_refptr<StringImpl> pstr =
          lynx::lepus::StringImpl::Create(rapValue.GetString(),
                                          rapValue.GetStringLength());
      return lepus_value(pstr);
    }
    case rapidjson::Type::kArrayType: {
      base::scoped_refptr<CArray> ary = CArray::Create();
      for (rapidjson::SizeType i = 0; i < rapValue.Size(); i++) {
        lepus_value leValue = jsonValueTolepusValue(rapValue[i]);
        ary->push_back(leValue);
      }
      return lepus_value(ary);
    }
    case rapidjson::Type::kObjectType: {
      lynx::base::scoped_refptr<Dictionary> dict = Dictionary::Create();
      for (rapid_value::ConstMemberIterator itr = rapValue.MemberBegin();
           itr != rapValue.MemberEnd(); ++itr) {
        dict->SetValue(itr->name.GetString(),
                       jsonValueTolepusValue(itr->value));
      }
      return lepus_value(dict);
    }
    default:
      break;
  }
  return lepus_value();
}

void qjsArrayToJSONString(std::stringstream& ss, const lepus::Value& value,
                          bool ordered) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "qjsArrayToJSONString");
  if (value.IsJSArray()) {
    ss << "[";
    uint32_t js_array_size = value.GetLength();
    uint32_t current_idx = 0;
    LepusValueIterator js_array_to_json_string_callback =
        [&ss, &js_array_size, &current_idx, ordered](
            const lepus::Value& key, const lepus::Value& element) {
          lepusValueToJSONString(ss, element, ordered);
          if (current_idx++ != js_array_size - 1) {
            ss << ",";
          }
        };
    value.IteratorJSValue(js_array_to_json_string_callback);
    ss << "]";
  }
}

void qjsObjectToJSONString(std::stringstream& ss, const lepus::Value& value,
                           bool ordered) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "qjsObjectToJSONString");
  if (value.IsJSTable()) {
    uint32_t js_object_length = value.GetLength();
    uint32_t current_idx = 0;
    ss << "{";
    if (!ordered) {
      LepusValueIterator jsobject_to_json_string_callback =
          [&ss, &js_object_length, &current_idx](const lepus::Value& key,
                                                 const lepus::Value& val) {
            ss << "\"" << key.String()->c_str() << "\"";
            ss << ":";
            lepusValueToJSONString(ss, val, false);

            if (current_idx++ != js_object_length - 1) {
              ss << ",";
            }
          };
      value.IteratorJSValue(jsobject_to_json_string_callback);
    } else {
      std::map<std::string, lepus::Value> sorted_props;
      LepusValueIterator get_jsobject_all_prop_names =
          [&sorted_props](const lepus::Value& key, const lepus::Value& val) {
            sorted_props.insert(std::make_pair(key.String()->str(), val));
          };
      value.IteratorJSValue(get_jsobject_all_prop_names);

      for (auto it = sorted_props.begin(); it != sorted_props.end();) {
        ss << "\"" << it->first << "\"";
        ss << ":";
        lepusValueToJSONString(ss, it->second, true);
        if (++it != sorted_props.end()) {
          ss << ",";
        }
      }
    }
    ss << "}";
  }
}

void qjsValueToJSONString(std::stringstream& ss, const lepus::Value& value,
                          bool ordered) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "qjsValueToJSONString");
  if (value.IsJSValue()) {
    if (value.IsJSArray()) {
      qjsArrayToJSONString(ss, value, ordered);
    } else if (value.IsJSTable()) {
      qjsObjectToJSONString(ss, value, ordered);
    } else if (value.IsJSFunction()) {
      ss << "null";
    } else {
      lepusValueToJSONString(ss, value.ToLepusValue(), ordered);
    }
  }
}

void lepusValueToJSONString(std::stringstream& ss, const lepus_value& value,
                            bool ordered,
                            const std::shared_ptr<LepusValueSet>& all_set) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "lepusValueToJSONString");
  if (value.IsJSValue()) {
    qjsValueToJSONString(ss, value, ordered);
    return;
  }

  auto type = value.Type();
  switch (type) {
    case lepus::ValueType::Value_Int64:
      ss << value.Int64();
      break;
    case lepus::ValueType::Value_UInt64:
      ss << value.UInt64();
      break;
    case lepus::ValueType ::Value_Int32:
      ss << value.Int32();
      break;
    case lepus::ValueType ::Value_UInt32:
      ss << value.UInt32();
      break;
    case lepus::ValueType::Value_Double:
      ss << value.Number();
      break;
    case lepus::ValueType::Value_Bool:
      ss << (value.Bool() ? "true" : "false");
      break;
    case lepus::ValueType::Value_String: {
      // use rapidjson::Write to transcode escape characters
      rapidjson::StringBuffer buf;
      rapidjson::Writer<rapidjson::StringBuffer> writer(buf);
      writer.String(value.String()->c_str());
      ss << buf.GetString();
    } break;
    case lepus::ValueType::Value_Table: {
      if (all_set->find(&value) != all_set->end()) {
        ss << "null";
        LOGE("lepusValueToJSONString has circle tables!");
        break;
      }
      all_set->insert(&value);
      auto table = value.Table();
      if (!ordered) {
        ss << "{";
        for (auto it = table->begin(); it != table->end();) {
          ss << "\"" << it->first.c_str() << "\"";
          ss << ":";
          lepusValueToJSONString(ss, it->second, ordered, all_set);
          if (++it != table->end()) {
            ss << ",";
          }
        }
        ss << "}";
      } else {
        ss << "{";
        std::vector<lepus::String> temp_v;
        for (auto& it : *table) {
          temp_v.push_back(it.first);
        }
        std::sort(temp_v.begin(), temp_v.end(),
                  [](const lepus::String& left, const lepus::String& right) {
                    return left.impl()->str() < right.impl()->str();
                  });
        for (auto it = temp_v.begin(); it != temp_v.end();) {
          ss << "\"" << it->c_str() << "\"";
          ss << ":";
          lepusValueToJSONString(ss, table->GetValue(*it), ordered, all_set);
          if (++it != temp_v.end()) {
            ss << ",";
          }
        }
        ss << "}";
      }
    } break;
    case lepus::ValueType::Value_Array: {
      if (all_set->find(&value) != all_set->end()) {
        ss << "null";
        LOGE("lepusValueToJSONString has circle arrays!");
        break;
      }
      all_set->insert(&value);
      auto array = value.Array();
      ss << "[";
      for (size_t i = 0; i < array->size(); ++i) {
        lepusValueToJSONString(ss, array->get(i), ordered, all_set);
        if (array->size() - 1 != i) {
          ss << ",";
        }
      }
      ss << "]";
    } break;
#if !ENABLE_JUST_LEPUSNG
    case lepus::ValueType::Value_CDate: {
      value.Date()->print(ss);
    } break;
#endif
    case lepus::ValueType::Value_NaN: {
      ss << "NaN";
    } break;
    default:
      ss << "null";
      break;
  }
}

std::string lepusValueToJSONString(const lepus_value& value, bool in_order) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "lepusValueToJSONString");
  DCHECK(value.IsObject() || value.IsArrayOrJSArray());
  std::stringstream ss;
  lepusValueToJSONString(ss, value, in_order);
  return ss.str();
}

std::string lepusValueMapToJSONString(
    const std::unordered_map<lepus::String, lepus::Value>& map) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "lepusValueMapToJSONString");
  std::stringstream ss;
  ss << "{";
  for (auto it = map.begin(); it != map.end();) {
    ss << "\"" << it->first.c_str() << "\"";
    ss << ":";
    lepusValueToJSONString(ss, it->second, false);

    if (++it != map.end()) {
      ss << ",";
    }
  }
  ss << "}";
  return ss.str();
}

std::string lepusValueToString(const lepus_value& value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "lepusValueToString");
  std::stringstream ss;
  lepusValueToJSONString(ss, value, false);
  return ss.str();
}

}  // namespace lepus
}  // namespace lynx
