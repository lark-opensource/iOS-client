// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_LEPUS_GLOBAL_H_
#define LYNX_LEPUS_LEPUS_GLOBAL_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/log/logging.h"
#include "lepus/table.h"

namespace lynx {
namespace lepus {
class Context;

class Global {
 public:
  Global() : global_(), global_content_() {}

  ~Global() {}

  inline Value* Get(std::size_t index) {
    if (index < global_content_.size()) {
      return &global_content_[index];
    }
    return nullptr;
  }

  int Search(const String& name) {
    auto iter = global_.find(name);
    if (iter != global_.end()) {
      return iter->second;
    }
    return -1;
  }

  Value* Find(const String& name) {
    auto iter = global_.find(name);
    if (iter != global_.end()) {
      return &global_content_[iter->second];
    }
    return nullptr;
  }

  std::size_t Add(const String& name, Value value) {
    auto iter = global_.find(name);
    if (iter != global_.end()) {
      return iter->second;
    }
    global_content_.push_back(std::move(value));
    global_.insert(std::make_pair(name, global_content_.size() - 1));
    return global_content_.size() - 1;
  }

  void Set(const String& name, Value value) {
    auto iter = global_.find(name);
    if (iter != global_.end()) {
      global_content_[iter->second] = value;
      return;
    }
    global_content_.push_back(std::move(value));
    global_.insert(std::make_pair(name, global_content_.size() - 1));
  }

  void Replace(const String& name, Value value) {
    auto iter = global_.find(name);
    if (iter != global_.end()) {
      global_content_[iter->second] = value;
    } else {
      Add(name, value);
    }
  }

  bool Update(size_t index, Value value) {
    if (index >= global_content_.size()) {
      return false;
    }
    global_content_[index] = value;
    return true;
  }

  bool Update(const String& name, Value value) {
    printf("global update:%s\n", name.c_str());
    auto iter = global_.find(name);
    int index = -1;
    if (iter != global_.end()) {
      index = iter->second;
    } else {
      return false;
    }
    global_content_[index] = value;
    return true;
  }

  std::size_t size() { return global_content_.size(); }

 private:
  friend class ContextBinaryWriter;
  friend class ContextBinaryReader;
  std::unordered_map<String, int> global_;
  std::vector<Value> global_content_;
};

class JsonData {
 public:
  JsonData(const char* json, lepus::Value* value)
      : source_(json), value_(value){};
  ~JsonData() {
    if (value_ != nullptr) delete value_;
  }
  // std::shared_ptr<JsonData> Clone();
  bool Parse();
  std::string source_;
  lepus::Value* value_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_LEPUS_GLOBAL_H_
