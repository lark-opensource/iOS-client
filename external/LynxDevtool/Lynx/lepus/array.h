// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_ARRAY_H_
#define LYNX_LEPUS_ARRAY_H_
#include <vector>

#include "base/ref_counted.h"
#include "lepus/context.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace lepus {
class CArray : public base::RefCountedThreadSafeStorage {
 public:
  static base::scoped_refptr<CArray> Create() {
    return base::AdoptRef<CArray>(new CArray());
  }
  bool push_back(const Value& value) {
    if (IsConst()) {
      LOGE("ConstValue: array is const");
      return false;
    }
    vec_.push_back(value);
    return true;
  }
  bool pop_back() {
    if (IsConst()) {
      LOGE("ConstValue: array is const");
      return false;
    }
    if (vec_.size() > 0) vec_.pop_back();
    return true;
  }

  bool Erase(uint32_t idx) {
    if (is_const_) {
      LOGE("ConstValue: array is const");
      return false;
    }

    if (idx >= 0 && idx < vec_.size()) {
      vec_.erase(vec_.begin() + idx);
    }
    return true;
  }

  bool Erase(size_t start, size_t del_count) {
    if (is_const_) {
      LOGE("Const Value: array is const of array::Erase");
      return false;
    }

    auto begin = (start < vec_.size()) ? (vec_.begin() + start) : vec_.end();
    auto end =
        (start + del_count <= vec_.size()) ? (begin + del_count) : vec_.end();

    vec_.erase(begin, end);
    return true;
  }

  bool Insert(size_t pos, size_t ins_count, LEPUSContext* ctx,
              LEPUSValue* argv) {
    if (is_const_) {
      LOGE("Const Value: array is const of array::Insert");
      return false;
    }

    auto pos_itr = (pos <= vec_.size()) ? (vec_.begin() + pos) : vec_.end();
    for (size_t i = 0; i < ins_count; ++i) {
      pos_itr = vec_.emplace(pos_itr, ctx, argv[i]) + 1;
    }
    return true;
  }

  bool Insert(uint32_t idx, const lepus::Value& value) {
    if (is_const_) {
      LOGE("ConstValue: array is const");
      return false;
    }

    if (idx >= 0 && idx <= vec_.size()) {
      vec_.insert(vec_.begin() + idx, value);
    }
    return true;
  }

  Value get_shift() {
    if (vec_.size() > 0) {
      Value ret = vec_[0];
      vec_.erase(vec_.begin(), vec_.begin() + 1);
      return ret;
    } else
      return Value();
  }

  const Value& get(size_t index) const {
    if (index >= vec_.size()) {
      static Value empty;
      empty = Value();
      return empty;
    }
    return vec_[index];
  }

  void resize(long size) { vec_.resize(size); }

  bool set(size_t index, const Value& v) {
    if (IsConst()) {
      LOGE("ConstValue: array is const");
      return false;
    }
    if (static_cast<size_t>(index) >= vec_.size()) {
      resize(index + 1);
    }
    vec_[index] = v;
    return true;
  }

  void SetIsMatchResult() { is_regexp_match_result_ = true; }

  bool GetIsMatchResult() { return is_regexp_match_result_; }

  size_t size() const { return vec_.size(); }

  void ReleaseSelf() const override {
    if (IsFromRef()) {
      std::lock_guard<std::mutex> guard(Context::GetArrayMutex());
      Context::GetLeakArray().erase(const_cast<CArray*>(this));
    }
    delete this;
  }

  ~CArray() override = default;

  friend bool operator==(const CArray& left, const CArray& right) {
    // normal array
    if (!left.is_regexp_match_result_ && !right.is_regexp_match_result_) {
      return left.vec_ == right.vec_;
    } else {
      // regexp match result
      bool vec_res = left.vec_ == right.vec_;
      if (vec_res) {
        return left.is_regexp_match_result_ == right.is_regexp_match_result_ &&
               left.regexp_match_index_ == right.regexp_match_index_ &&
               left.regexp_match_input_ == right.regexp_match_input_ &&
               left.regexp_match_groups_ == right.regexp_match_groups_;
      }
      return false;
    }
  }

  friend bool operator!=(const CArray& left, const CArray& right) {
    return !(left == right);
  }

  Value GetMatchIndex() {
    DCHECK(is_regexp_match_result_);
    DCHECK(size() >= 3);
    return get(size() - 3);
  }

  Value GetMatchGroups() {
    DCHECK(is_regexp_match_result_);
    DCHECK(size() >= 3);
    return get(size() - 1);
  }

  Value GetMatchInput() {
    DCHECK(is_regexp_match_result_);
    DCHECK(size() >= 3);
    return get(size() - 2);
  }

  bool IsConst() const { return is_const_; }
  void MarkConst() { is_const_ = true; }

  bool IsFromRef() const { return is_from_ref_; }
  void MarkFromRef() { is_from_ref_ = true; }

 protected:
  CArray()
      : vec_(),
        is_regexp_match_result_(false),
        regexp_match_index_(Value()),
        regexp_match_groups_(Value()),
        regexp_match_input_(Value()) {}

 private:
  std::vector<Value> vec_;
  bool is_regexp_match_result_;
  bool is_const_ = false;
  bool is_from_ref_ = false;
  Value regexp_match_index_;
  Value regexp_match_groups_;
  Value regexp_match_input_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_ARRAY_H_
