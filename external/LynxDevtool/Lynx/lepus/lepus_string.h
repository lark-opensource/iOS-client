// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_LEPUS_STRING_H_
#define LYNX_LEPUS_LEPUS_STRING_H_

#include <cstring>
#include <iomanip>
#include <limits>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/no_destructor.h"
#include "base/ref_counted.h"
#include "base/ref_counted_ptr.h"

namespace lynx {
namespace lepus {
class StringHash;
class String;
class Value;
// class StringPool;
class BASE_EXPORT_FOR_DEVTOOL StringImpl
    : public base::RefCountedThreadSafeStorage {
 public:
  static base::scoped_refptr<StringImpl> Create(const char* str,
                                                std::size_t len) {
    return base::AdoptRef<StringImpl>(new StringImpl(str, len));
  }

  static base::scoped_refptr<StringImpl> Create(const char* str) {
    return base::AdoptRef<StringImpl>(new StringImpl(str));
  }

  static base::scoped_refptr<StringImpl> Create(std::string str) {
    return base::AdoptRef<StringImpl>(new StringImpl(std::move(str)));
  }

  static StringImpl* RawCreate(const std::string& str) {
    StringImpl* ret = new StringImpl(str);
    return ret;
  }

  ~StringImpl() override = default;

  void ReleaseSelf() const override { delete this; }

  std::size_t hash() const { return hash_; }

  const char* c_str() const { return str_.c_str(); }
  const std::string& str() const { return str_; }

  std::size_t length() const { return length_; }

  std::size_t find(const StringImpl& other, long index) {
    return str_.find(other.str_, index);
  }

  // TODO
  StringImpl& operator=(const std::string& other) {
    length_ = other.length();
    utf16_length_ = 0;
    str_ = std::string(other.c_str(), 0, length_);
    hash_ = std::hash<std::string>()(str_);
    return *this;
  }

  bool operator<(const StringImpl& other) const { return str_ < other.str_; }

  friend bool operator==(const StringImpl& left, const StringImpl& right) {
    return &left == &right || left.str_.compare(right.str_) == 0;
  }

  bool empty() { return str_.empty(); }

  std::size_t size();
  std::size_t size_utf16();

  std::string get_trim() {
    std::string ret = str_;
    if (ret.empty() == 0) {
      ret.erase(0, ret.find_first_not_of(" "));
      ret.erase(ret.find_last_not_of(" ") + 1);
    }
    return ret;
  }

  inline bool IsEqual(const char* other) const {
    return str_.compare(other) == 0;
  }

  inline bool IsEqual(const StringImpl* other) const {
    return str_.compare(other->str_) == 0;
  }
  friend class StringHash;
  friend class ContextBinaryReader;

 protected:
  explicit StringImpl(const char* str, std::size_t len);
  BASE_EXPORT_FOR_DEVTOOL explicit StringImpl(const char* str);
  explicit StringImpl(std::string str);

 private:
  // for encode/decode
  StringImpl() {}
  std::string str_;
  std::size_t length_;
  std::size_t hash_;

  // utf16_length consists of the src's length and the flag bit(1 bit);
  // ------- real utf'8 length -------| flag
  // flag = 1 means length is valid, otherwise length is invalid.
  std::size_t utf16_length_ = 0;
  // StringPool* string_pool_;

  StringImpl(const StringImpl&) = delete;
  StringImpl& operator=(const StringImpl&) = delete;
};

class String {
 public:
  String() : str_(nullptr) {}
  String(const std::string& str)
      : str_(lepus::StringImpl::Create(str.c_str())) {}
  String(const char* c_str) : str_(lepus::StringImpl::Create(c_str)) {}
  String(base::scoped_refptr<StringImpl> str) : str_(str) {}
  String(const String& other) : str_(other.str_) {}
  String& operator=(const String& other) {
    str_ = other.str_;
    return *this;
  }

  const base::scoped_refptr<StringImpl>& impl() const { return str_; }

  bool IsEqual(const char* other) const {
    return str_.Get() && str_->IsEqual(other);
  }

  bool IsEqual(const std::string& other) const {
    return str_.Get() && str_->IsEqual(other.c_str());
  }

  bool IsEqual(const String& other) const {
    return str_.Get() && str_->IsEqual(other.c_str());
  }

  template <size_t N>
  bool IsEquals(char const (&p)[N]) const {
    return str_.Get() && (str_->length() == N - 1) &&
           (!memcmp(str_->c_str(), p, N - 1));
  }

  inline const std::string& str() const {
    if (str_.Get()) {
      return str_->str();
    } else {
      static base::NoDestructor<std::string> empty{""};
      return *empty;
    }
  }

  inline bool empty() const { return str_.Get() ? str_->empty() : true; }

  inline const char* c_str() const {
    return str_.Get() ? str_->c_str() : nullptr;
  }

  inline size_t length() const { return str_.Get() ? str_->length() : 0; }

  bool operator==(const String& other) const {
    return str_ == other.str_ || (str_ && other.str_ && *str_ == *other.str_);
  }

  bool operator<(const String& other) const { return *str_ < *other.str_; }

 private:
  base::scoped_refptr<StringImpl> str_;
};

// used for encode
class StringTable {
 public:
  size_t NewString(const char* str) {
    if (!str) {
      str = "";
    }
    auto iter = string_map_.find(str);
    if (iter != string_map_.end()) {
      return iter->second;
    }

    std::string std_str(str);
    string_list.push_back(std_str);
    size_t index = string_list.size() - 1;
    string_map_.insert(std::make_pair(std_str, index));
    return index;
  }

 public:
  std::unordered_map<std::string, size_t> string_map_;
  std::vector<lepus::String> string_list;
};
/*
class StringPool {
 public:
  StringPool() : string_set_(), string_map_() {}
  ~StringPool() {}
  String* NewString(const char* str);
  String* NewString(const std::string& str);
  size_t size(const std::string& str);
  void EraseAll();

 protected:
  friend class String;
  void Erase(String* string);

 private:
  struct Hash {
    std::size_t operator()(const String* str) const { return str->hash(); }
  };

  struct Equal {
    bool operator()(const String* left, const String* right) const {
      return left == right || *left == *right;
    }
  };
  std::unordered_set<String*, Hash, Equal> string_set_;
  std::unordered_map<std::string, String*> string_map_;
};*/

class StringConvertHelper {
 public:
  static constexpr int kMaxInt = 0x7FFFFFFF;
  static constexpr int kMinInt = -kMaxInt - 1;
  static constexpr long long kMaxInt64 = 0x7fffffffffffffff;
  static constexpr long long kMinInt64 = -kMaxInt64 - 1;

  BASE_EXPORT_FOR_DEVTOOL static bool IsMinusZero(double value);

  static inline double FastI2D(int x) { return static_cast<double>(x); }

  static inline int FastD2I(double x) { return static_cast<int32_t>(x); }

  static inline double FastI642D(int64_t x) { return static_cast<double>(x); }

  static inline int64_t FastD2I64(double x) { return static_cast<int64_t>(x); }

  static bool IsInt32Double(double value) {
    return value >= kMinInt && value <= kMaxInt && !IsMinusZero(value) &&
           value == FastI2D(FastD2I(value));
  }

  static bool IsInt64Double(double value) {
    return FastD2I64(value) >= kMinInt64 && FastD2I64(value) <= kMaxInt64 &&
           !IsMinusZero(value) && value == FastI642D(FastD2I64(value));
  }

  static const char* IntToCString(int n, std::vector<char>& buffer) {
    bool negative = true;
    if (n >= 0) {
      n = -n;
      negative = false;
    }
    // Build the string backwards from the least significant digit.
    size_t i = buffer.size();
    buffer[--i] = '\0';
    do {
      // We ensured n <= 0, so the subtraction does the right addition.
      buffer[--i] = '0' - (n % 10);
      n /= 10;
    } while (n);
    if (negative) buffer[--i] = '-';
    return &buffer[0] + i;
  }

  static const char* NumberToString(double double_value,
                                    std::vector<char>& buffer) {
    if (IsInt32Double(double_value)) {
      return IntToCString(double_value, buffer);
    }

    return nullptr;
  }

  static std::string DoubleToString(double double_value) {
    std::ostringstream double2str;
    double2str << std::setprecision(std::numeric_limits<double>::digits10)
               << double_value;
    return double2str.str();
  }
};

}  // namespace lepus
}  // namespace lynx

namespace std {
template <>
struct hash<lynx::lepus::String> {
  std::size_t operator()(const lynx::lepus::String& k) const {
    return k.impl()->hash();
  }
};
}  // namespace std

#endif  // LYNX_LEPUS_LEPUS_STRING_H_
