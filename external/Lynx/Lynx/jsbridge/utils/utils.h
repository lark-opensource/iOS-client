// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_UTILS_UTILS_H_
#define LYNX_JSBRIDGE_UTILS_UTILS_H_

#include <jsbridge/bindings/console.h>

#include <string>
#include <utility>
#include <vector>

#include "base/json/json_util.h"
#include "base/log/logging.h"
#include "jsbridge/jsi/jsi.h"
#include "lepus/array.h"
#include "lepus/value-inl.h"
#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/error/en.h"
#include "third_party/rapidjson/reader.h"
#include "third_party/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/writer.h"

namespace lynx {
namespace piper {
class JSIObjectWrapperManager;
std::optional<Value> valueFromLepus(
    Runtime& runtime, const lepus::Value& data,
    JSIObjectWrapperManager* jsi_object_wrapper_manager = nullptr);

std::optional<Array> arrayFromLepus(Runtime& runtime,
                                    const lepus::CArray& array);

std::optional<lepus_value> ParseJSValue(
    piper::Runtime& runtime, const piper::Value& value,
    JSIObjectWrapperManager* jsi_object_wrapper_manager,
    const std::string& jsi_object_group_id, const std::string& targetSDKVersion,
    std::vector<piper::Object>& pre_object_vector);

bool IsCircularJSObject(Runtime& runtime, const Object& object,
                        const std::vector<piper::Object>& pre_object_vector);

bool CheckIsCircularJSObjectIfNecessaryAndReportError(
    Runtime& runtime, const Object& object,
    const std::vector<piper::Object>& pre_object_vector, const char* message);

class ScopedJSObjectPushPopHelper {
 public:
  ScopedJSObjectPushPopHelper(std::vector<piper::Object>& vector,
                              piper::Object object)
      : pre_object_vector_(vector) {
    pre_object_vector_.push_back(std::move(object));
  };
  ~ScopedJSObjectPushPopHelper() { pre_object_vector_.pop_back(); }

 private:
  std::vector<piper::Object>& pre_object_vector_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_UTILS_UTILS_H_
