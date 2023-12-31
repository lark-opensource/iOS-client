// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus/table.h"

#include "base/log/logging.h"
#include "lepus/context.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace lepus {

Dictionary::Dictionary(HashMap map) : hash_map_(std::move(map)) {}

bool Dictionary::SetValue(const String& key, const Value& value) {
  if (IsConst()) {
    LOGE("Const dictionary can not be set\n");
    // abort();
    return false;
  }
  hash_map_[key] = value;
  return true;
}

bool Dictionary::Contains(const String& key) {
  return hash_map_.find(key) != hash_map_.end();
}

bool Dictionary::Erase(const String& key) {
  if (IsConst()) {
    LOGE("Const dictionary can not be erased key\n");
    return false;
  }
  hash_map_.erase(key);
  return true;
}

const Value& Dictionary::GetValue(const String& key, bool forUndef) {
  HashMap::iterator iter = hash_map_.find(key);
  if (iter != hash_map_.end()) {
    return iter->second;
  }

  static Value kEmpty;
  static Value kUndefined;
  if (forUndef) {
    kUndefined.SetUndefined();
    return kUndefined;
  } else {
    kEmpty.SetNil();
    return kEmpty;
  }
}

void Dictionary::dump() {
  LOGE("begin dump dict----------");
  auto it = begin();
  for (; it != end(); it++) {
    lepus::Value value = it->second;
    if (value.IsNumber()) {
      LOGE(it->first.str() << " : " << value.Number());
    }

    else if (value.IsString()) {
      LOGE(it->first.str() << " : " << value.String()->c_str());
    } else if (value.IsTable()) {
      LOGE(it->first.str() << " : ===>");
      value.Table()->dump();
    } else if (value.IsBool()) {
      LOGE(it->first.str() << " : "
                           << ((value.Bool() == true) ? "true" : "false"));
    } else if (value.IsArray()) {
      LOGE(it->first.str() << " : []");
    } else {
      LOGE(it->first.str() << " : type is " << value.Type());
    }
  }
  LOGE("end dump dict----------");
}

bool operator==(const Dictionary& left, const Dictionary& right) {
  return left.hash_map_ == right.hash_map_;
}

void Dictionary::ReleaseSelf() const {
  if (IsFromRef()) {
    std::lock_guard<std::mutex> guard(Context::GetTableMutex());
    Context::GetLeakTable().erase(const_cast<Dictionary*>(this));
  }
  delete this;
}

void Dictionary::MarkConst() { is_const_ = true; }
}  // namespace lepus
}  // namespace lynx
