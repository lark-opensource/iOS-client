// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/replay/replay_controller.h"

#include <vector>

#include "config/config.h"

#if ENABLE_ARK_REPLAY
#include "lepus/array.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "tasm/replay/ark_test_replay.h"
#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/writer.h"
#endif  // ENABLE_ARK_REPLAY

namespace lynx {
namespace tasm {
namespace replay {

bool ReplayController::Enable() {
#if ENABLE_ARK_REPLAY
  return true;
#else
  return false;
#endif
}

void ReplayController::StartTest() {
#if ENABLE_ARK_REPLAY
  lynx::tasm::replay::ArkTestReplay::GetInstance().StartTest();
#endif
}

void ReplayController::EndTest(const std::string& file_path) {
#if ENABLE_ARK_REPLAY
  lynx::tasm::replay::ArkTestReplay::GetInstance().EndTest(file_path);
#endif
}

void ReplayController::SendFileByAgent(const std::string& type,
                                       const std::string& file) {
#if ENABLE_ARK_REPLAY
  LOGI("SendFileByAgent: type: " + type + ", file: " + file);
  if (!file.empty()) {
    lynx::tasm::replay::ArkTestReplay::GetInstance().SendFileByAgent(type,
                                                                     file);
  }
#endif
}

std::string ReplayController::ConvertEventInfo(const lepus::Value& info) {
#if ENABLE_ARK_REPLAY
  if (info.IsObject() && info.GetProperty("type").IsString()) {
    const auto& type = info.GetProperty("type").String()->str();
    constexpr const static char* kLoad = "load";
    constexpr const static char* kError = "error";
    constexpr const static char* kScroll = "scroll";
    constexpr const static char* kNodeAppear = "nodeappear";
    constexpr const static char* kImpression = "impression";
    constexpr const static char* kContentSizeChanged = "contentsizechanged";
    if (type == kLoad || type == kError || type == kScroll ||
        type == kNodeAppear || type == kImpression ||
        type == kContentSizeChanged) {
      return "";
    }
  }

  const static auto& get_json_string_f = [](const rapidjson::Document& d) {
    rapidjson::StringBuffer buffer;
    buffer.Clear();
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);

    d.Accept(writer);
    return std::string(buffer.GetString());
  };

  const static std::function<rapidjson::Value(
      rapidjson::MemoryPoolAllocator<> & allocator, const lepus::Value&)>&
      to_json_f = [](rapidjson::MemoryPoolAllocator<>& allocator,
                     const lepus::Value& value) {
        rapidjson::Value v;
        auto type = value.Type();
        switch (type) {
          case lepus::ValueType::Value_Int64:
            v.Set(value.Int64());
            break;
          case lepus::ValueType::Value_UInt64:
            v.Set(value.UInt64());
            break;
          case lepus::ValueType ::Value_Int32:
            v.Set(value.Int32());
            break;
          case lepus::ValueType ::Value_UInt32:
            v.Set(value.UInt32());
            break;
          case lepus::ValueType::Value_Double:
            v.Set(value.Double());
            break;
          case lepus::ValueType::Value_Bool:
            v.Set(value.Bool());
            break;
          case lepus::ValueType::Value_String: {
            rapidjson::StringBuffer buf;
            rapidjson::Writer<rapidjson::StringBuffer> writer(buf);
            writer.String(value.String()->c_str());
            v.SetString(buf.GetString(), allocator);
          } break;
          case lepus::ValueType::Value_Table: {
            auto table = value.Table();
            std::vector<lepus::String> temp_v;
            for (auto& it : *table) {
              constexpr const static char* kTimeStamp = "timestamp";
              constexpr const static char* kUid = "uid";
              constexpr const static char* kIdentifier = "identifier";
              if (it.first.str().compare(kTimeStamp) != 0 &&
                  it.first.str().compare(kUid) != 0 &&
                  it.first.str().compare(kIdentifier) != 0) {
                temp_v.push_back(it.first);
              }
            }
            std::sort(
                temp_v.begin(), temp_v.end(),
                [](const lepus::String& left, const lepus::String& right) {
                  return left.impl()->str() < right.impl()->str();
                });
            v.SetObject();
            for (auto& it : temp_v) {
              v.AddMember(rapidjson::Value(it.c_str(), allocator),
                          to_json_f(allocator, table->GetValue(it)), allocator);
            }
            break;
          }
          case lepus::ValueType::Value_Array: {
            auto array = value.Array();
            v.SetArray();
            for (size_t i = 0; i < array->size(); ++i) {
              v.PushBack(to_json_f(allocator, array->get(i)), allocator);
            }
            break;
          }
          case lepus::ValueType::Value_NaN: {
            v.Set(NAN);
          } break;
          default:
            v.SetNull();
            break;
        }
        return v;
      };

  rapidjson::Document d;
  d.CopyFrom(to_json_f(d.GetAllocator(), info), d.GetAllocator());
  return get_json_string_f(d);
#else
  return "";
#endif
}

}  // namespace replay
}  // namespace tasm
}  // namespace lynx
