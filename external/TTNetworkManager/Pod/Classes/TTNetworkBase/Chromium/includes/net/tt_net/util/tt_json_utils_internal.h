// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_UTIL_TT_JSON_UTILS_INTERNAL_H_
#define NET_TT_NET_UTIL_TT_JSON_UTILS_INTERNAL_H_

#include <map>

namespace net {

namespace ttutils {

// Traits to deal with different basic types.
template <typename T, typename = void>
struct NodeTraits;

template <>
struct NodeTraits<std::string> {
 public:
  static bool GetNodeValue(const base::Value* node, std::string* out) {
    if (!node->is_string()) {
      return false;
    }
    *out = node->GetString();
    return true;
  }
};

template <>
struct NodeTraits<float> {
 public:
  static bool GetNodeValue(const base::Value* node, float* out) {
    if (!node->is_double()) {
      return false;
    }
    *out = static_cast<float>(node->GetDouble());
    return true;
  }
};

template <>
struct NodeTraits<double> {
 public:
  static bool GetNodeValue(const base::Value* node, double* out) {
    if (!node->is_double()) {
      return false;
    }
    *out = node->GetDouble();
    return true;
  }
};

template <>
struct NodeTraits<bool> {
 public:
  static bool GetNodeValue(const base::Value* node, bool* out) {
    if (!node->is_bool() && !node->is_int()) {
      return false;
    }
    if (node->is_bool()) {
      *out = node->GetBool();
      return true;
    }
    DCHECK(node->is_int());
    int tmp_value = node->GetInt();
    if (tmp_value != 1 && tmp_value != 0) {
      return false;
    }
    *out = tmp_value > 0;
    return true;
  }
};

template <>
struct NodeTraits<base::DictionaryValue*> {
 public:
  static bool GetNodeValue(const base::Value* node, base::DictionaryValue** out) {
    const base::DictionaryValue* dict = nullptr;
    if (node->GetAsDictionary(&dict)) {
      *out = const_cast<base::DictionaryValue*>(dict);
      return true;
    } else {
      return false;
    }
  }
};

template <>
struct NodeTraits<base::ListValue*> {
 public:
  static bool GetNodeValue(const base::Value* node, base::ListValue** out) {
    const base::ListValue* dict = nullptr;
    if (node->GetAsList(&dict)) {
      *out = const_cast<base::ListValue*>(dict);
      return true;
    } else {
      return false;
    }
  }
};

template <typename T, typename = void, typename = void>
struct StringToNumberTraits;

template <>
struct StringToNumberTraits<int> {
 public:
  static bool ToNumber(const std::string& str, int* out) {
    return base::StringToInt(str, out);
  }
};

template <>
struct StringToNumberTraits<int64_t> {
 public:
  static bool ToNumber(const std::string& str, int64_t* out) {
    return base::StringToInt64(str, out);
  }
};

template <typename T>
struct StringToNumberTraits<
    T,
    typename std::enable_if<!std::is_same<T, size_t>::value>::type,
    typename std::enable_if<std::is_same<T, unsigned>::value>::type> {
 public:
  static bool ToNumber(const std::string& str, T* out) {
    return base::StringToUint(str, out);
  }
};

template <>
struct StringToNumberTraits<size_t> {
 public:
  static bool ToNumber(const std::string& str, size_t* out) {
    return base::StringToSizeT(str, out);
  }
};

template <typename T>
struct StringToNumberTraits<
    T,
    typename std::enable_if<std::is_unsigned<T>::value>::type,
    typename std::enable_if<!std::is_same<T, unsigned>::value>::type> {
 public:
  static bool ToNumber(const std::string& str, T* out) {
    uint64_t temp_out = 0;
    if (!base::StringToUint64(str, &temp_out)) {
      return false;
    }
    temp_out = std::max(temp_out,
                        static_cast<uint64_t>(std::numeric_limits<T>::min()));
    temp_out = std::min(temp_out,
                        static_cast<uint64_t>(std::numeric_limits<T>::max()));
    *out = static_cast<T>(temp_out);
    return true;
  }
};

template <typename T>
struct is_non_negative_type {
  static const bool value =
      std::is_same<T, unsigned>::value || std::is_same<T, uint64_t>::value;
};

template <typename T,
          typename std::enable_if<!is_non_negative_type<T>::value>::type* = nullptr>
bool IsNonNegativeOutWithNegativeValue(int temp_out) {
  return false;
}
template <typename T,
          typename std::enable_if<is_non_negative_type<T>::value>::type* = nullptr>
bool IsNonNegativeOutWithNegativeValue(int temp_out) {
  return temp_out < 0;
}

template <typename T>
struct NodeTraits<T, base::void_t<typename std::enable_if<std::is_arithmetic<T>::value>::type>> {
 public:
  static bool GetNodeValue(const base::Value* node, T* out) {
    using Traits = StringToNumberTraits<T>;
    if (!node->is_string() && !node->is_int()) {
      return false;
    }
    if (node->is_string()) {
      T temp_t;
      std::string tmp_str = node->GetString();
      if (tmp_str.empty() || !Traits::ToNumber(tmp_str, &temp_t)) {
        return false;
      }
      *out = temp_t;
      return true;
    }
    DCHECK(node->is_int());
    int temp_out = node->GetInt();
    if (IsNonNegativeOutWithNegativeValue<T>(temp_out)) {
      return false;
    }
    if (std::numeric_limits<int>::min() <= std::numeric_limits<T>::min()) {
      temp_out =
          std::max(temp_out, static_cast<int>(std::numeric_limits<T>::min()));
    }
    if (std::numeric_limits<int>::max() >= std::numeric_limits<T>::max()) {
      temp_out =
          std::min(temp_out, static_cast<int>(std::numeric_limits<T>::max()));
    }
    *out = static_cast<T>(temp_out);
    return true;
  }
};

// Check whether the class or template class T has the |method|.
#define CHECK_METHOD(method) \
template <typename T, typename...Args> \
struct has_method_##method { \
 private: \
  template<typename U> \
  static auto Check(int) -> decltype(std::declval<U>().method(std::declval<Args>()...), std::true_type()); \
  template<typename U> \
  static auto Check(...) -> decltype(std::false_type()); \
 public: \
  static const bool value = std::is_same<decltype(Check<T>(0)), std::true_type>::value; \
}; \

CHECK_METHOD(push_back)
CHECK_METHOD(insert)

template <typename C,
          typename T,
          typename std::enable_if<has_method_push_back<C, T>::value>::type* = nullptr>
void inline AddValueToContainer(C* c, const T& value) {
  c->push_back(value);
}

template <typename C,
          typename T,
          typename std::enable_if<has_method_insert<C, T>::value>::type* = nullptr>
void inline AddValueToContainer(C* c, const T& value) {
  c->insert(value);
}

// Check whether the class or template class T is a container.
template <typename T, typename = void>
struct is_container : std::false_type {};

template <typename T>
struct is_container<T, base::void_t<typename T::value_type>> {
  static const bool value =
      std::is_same<T, std::vector<typename T::value_type>>::value ||
      std::is_same<T, std::set<typename T::value_type>>::value ||
      std::is_same<T, std::unordered_set<typename T::value_type>>::value;
};

// Check whether the class or template class T is a map.
template <typename T, typename = void>
struct is_map : std::false_type {};

template <typename T>
struct is_map<T, base::void_t<typename T::key_type, typename T::mapped_type>> {
  static const bool value =
      std::is_same<T, std::map<typename T::key_type, typename T::mapped_type>>::
          value ||
      std::is_same<T,
                   std::unordered_map<typename T::key_type,
                                      typename T::mapped_type>>::value;
};

// For storing data in a container (vector, set, unordered_set, ect.) except
// map.
template <typename C,
          typename std::enable_if<is_container<C>::value>::type* = nullptr,
          typename T = typename C::value_type>
bool GetJsonNodeValueWithNameInner(const std::string& child_name,
                                   const base::Value* child_node,
                                   C* child_value) {
  using Traits = NodeTraits<T>;
  if (!child_node->is_list()) {
    DLOG(WARNING) << "Invalid type of child node " << child_name;
    return false;
  }
  const auto& list = child_node->GetList();
  child_value->clear();
  for (const auto& it : list) {
    T tmp_val;
    if (!Traits::GetNodeValue(&it, &tmp_val)) {
      DLOG(WARNING) << "Invalid value of child node " << child_name;
      return false;
    }
    AddValueToContainer(child_value, tmp_val);
  }
  return true;
}

// For storing data in basic type (int, string, bool, ect. as well as
// DictionaryValue and ListValue).
template <typename T,
          typename std::enable_if<!is_container<T>::value>::type* = nullptr,
          typename std::enable_if<!is_map<T>::value>::type* = nullptr>
bool GetJsonNodeValueWithNameInner(const std::string& child_name,
                                   const base::Value* child_node,
                                   T* child_value) {
  using Traits = NodeTraits<T>;
  if (!Traits::GetNodeValue(child_node, child_value)) {
    DLOG(WARNING) << "Invalid value of child node " << child_name;
    return false;
  }
  DVLOG(1) << "Get child node " << child_name << " with value " << *child_value;
  return true;
}

// For storing data in a map container (map or unordered_map).
template <typename M,
          typename std::enable_if<is_map<M>::value>::type* = nullptr,
          typename MT = typename M::mapped_type>
bool GetJsonNodeValueWithNameInner(const std::string& child_name,
                                   const base::Value* child_node,
                                   M* child_value) {
  child_value->clear();
  const base::DictionaryValue* dict = nullptr;
  if (!child_node->GetAsDictionary(&dict)) {
    DLOG(WARNING) << "Invalid value of child node " << child_name;
    return false;
  }
  for (base::DictionaryValue::Iterator it(*dict); !it.IsAtEnd(); it.Advance()) {
    const auto& key = it.key();
    MT tmp_val;
    if (!GetJsonNodeValueWithNameInner(key, &it.value(), &tmp_val)) {
      DLOG(WARNING) << "Invalid value of child node " << child_name;
      return false;
    }
    (*((M*)child_value))[key] = tmp_val;
  }
  return true;
}

}  // namespace ttutils
}  // namespace net

#endif