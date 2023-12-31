// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_TABLE_H_
#define LYNX_LEPUS_TABLE_H_

#include <algorithm>
#include <optional>
#include <unordered_map>
#include <utility>

#include "base/base_export.h"
#include "base/ref_counted.h"
#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace lepus {
class BASE_EXPORT_FOR_DEVTOOL Dictionary
    : public base::RefCountedThreadSafeStorage {
 public:
  typedef std::unordered_map<String, Value> HashMap;

 public:
  static base::scoped_refptr<Dictionary> Create() {
    return base::AdoptRef<Dictionary>(new Dictionary());
  }
  static base::scoped_refptr<Dictionary> Create(HashMap map) {
    return base::AdoptRef<Dictionary>(new Dictionary(std::move(map)));
  }
  BASE_EXPORT_FOR_DEVTOOL ~Dictionary() override = default;
  BASE_EXPORT_FOR_DEVTOOL bool SetValue(const String& key, const Value& value);
  BASE_EXPORT_FOR_DEVTOOL const Value& GetValue(const String& key,
                                                bool forUndef = false);

  bool Contains(const String& key);

  HashMap::iterator find(const String& key) { return hash_map_.find(key); }

  bool Erase(const String& key);

  size_t size() { return hash_map_.size(); }

  HashMap::iterator begin() { return hash_map_.begin(); }

  HashMap::const_iterator cbegin() const { return hash_map_.cbegin(); }

  HashMap::const_iterator cend() const { return hash_map_.cend(); }

  HashMap::iterator end() { return hash_map_.end(); }

  void dump();
  void ReleaseSelf() const override;

  bool set(const String& key, const Value& v) {
    if (IsConst()) {
      LOGE("ConstValue: table is const");
      return false;
    }
    hash_map_[key] = v;
    return true;
  }

  friend bool operator==(const Dictionary& left, const Dictionary& right);

  friend bool operator!=(const Dictionary& left, const Dictionary& right) {
    return !(left == right);
  }

  bool IsConst() const { return is_const_; }
  void MarkConst();

  bool IsFromRef() const { return is_from_ref_; }
  void MarkFromRef() { is_from_ref_ = true; }

 protected:
  BASE_EXPORT_FOR_DEVTOOL Dictionary() = default;
  Dictionary(HashMap map);

 private:
  HashMap hash_map_;
  bool is_const_ = false;
  bool is_from_ref_ = false;
};

using DictionaryPtr = base::scoped_refptr<Dictionary>;

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_TABLE_H_
