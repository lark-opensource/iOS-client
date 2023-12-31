//
// Created by zhangye on 2020/8/7.
//

#ifndef LYNX_LEPUS_REGEXP_H_
#define LYNX_LEPUS_REGEXP_H_
#include "base/ref_counted.h"
#include "lepus/lepus_string.h"
namespace lynx {
namespace lepus {
class Value;
class RegExp : public base::RefCountedThreadSafeStorage {
 public:
  static base::scoped_refptr<RegExp> Create() {
    return base::AdoptRef<RegExp>(new RegExp());
  }

  static base::scoped_refptr<RegExp> Create(const String& pattern) {
    return base::AdoptRef<RegExp>(new RegExp(pattern, ""));
  }
  static base::scoped_refptr<RegExp> Create(const String& pattern,
                                            const String& flags) {
    return base::AdoptRef<RegExp>(new RegExp(pattern, flags));
  }

  RegExp(const RegExp& other)
      : pattern_(other.pattern_), flags_(other.flags_) {}

  const String& get_pattern() const { return pattern_; }
  const String& get_flags() const { return flags_; }

  void set_pattern(const String& pattern) { pattern_ = pattern; }
  void set_flags(const String& flags) { flags_ = flags; }

  void ReleaseSelf() const override { delete this; }

  ~RegExp() override = default;

  friend bool operator==(const RegExp& left, const RegExp& right) {
    return left.pattern_ == right.pattern_ && left.flags_ == right.flags_;
  }

  friend bool operator!=(const RegExp& left, const RegExp& right) {
    return !(left == right);
  }

 protected:
  RegExp() : pattern_(StringImpl::Create("")), flags_(StringImpl::Create("")) {}
  RegExp(const String& pattern, const String& flags) {
    pattern_ = pattern;
    flags_ = flags;
  }

 private:
  String pattern_;
  String flags_;
};
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_REGEXP_H_
