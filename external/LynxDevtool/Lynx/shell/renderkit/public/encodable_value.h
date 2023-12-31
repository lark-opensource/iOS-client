// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_ENCODABLE_VALUE_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_ENCODABLE_VALUE_H_

#include <any>
#include <cassert>
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "shell/renderkit/public/method_result.h"

#if defined(BUILD_WITH_ABSL)

#include "third_party/abseil-cpp/absl/types/variant.h"
namespace lynx {
using absl::bad_variant_access;
using absl::get;
using absl::get_if;
using absl::holds_alternative;
using absl::monostate;
using absl::variant;
using absl::variant_alternative;
using absl::variant_alternative_t;
using absl::variant_npos;
using absl::variant_size;
using absl::visit;
}  // namespace lynx

#elif (__cplusplus >= 201703L || _MSVC_LANG >= 201703L)

#include <variant>
namespace lynx {
using std::bad_variant_access;
using std::get;
using std::get_if;
using std::holds_alternative;
using std::monostate;
using std::variant;
using std::variant_alternative;
using std::variant_alternative_t;
using std::variant_npos;
using std::variant_size;
using std::variant_size_v;
using std::visit;
}  // namespace lynx

#endif

namespace lynx {
class EncodableValue;

// Convenience type aliases.
using EncodableList = std::vector<EncodableValue>;
using EncodableMap = std::map<std::string, EncodableValue>;
using EncodableMethodResultPtr = std::shared_ptr<MethodResult>;

namespace internal {
using EncodableValueVariant =
    lynx::variant<lynx::monostate, bool, double, std::string, EncodableList,
                  EncodableMap, EncodableMethodResultPtr>;
}  // namespace internal

class EncodableValue : public internal::EncodableValueVariant {
 public:
  // Rely on std::variant for most of the constructors/operators.
  using super = internal::EncodableValueVariant;
  using super::super;
  using super::operator=;

  explicit EncodableValue() = default;

  // Avoid the C++17 pitfall of conversion from char* to bool. Should not be
  // needed for C++20.
  explicit EncodableValue(const char* string) : super(std::string(string)) {}
  EncodableValue& operator=(const char* other) {
    *this = std::string(other);
    return *this;
  }

  // Override the conversion constructors from std::variant to make them
  // explicit, to avoid implicit conversion.
  //
  // While implicit conversion can be convenient in some cases, it can have very
  // surprising effects. E.g., calling a function that takes an EncodableValue
  // but accidentally passing an EncodableValue* would, instead of failing to
  // compile, go through a pointer->bool->EncodableValue(bool) chain and
  // silently call the function with a temp-constructed EncodableValue(true).
  template <class T>
  constexpr explicit EncodableValue(T&& t) noexcept : super(t) {}

  // Returns true if the value is null. Convenience wrapper since unlike the
  // other types, std::monostate uses aren't self-documenting.
  bool IsNull() const {
    return lynx::holds_alternative<lynx::monostate>(*this);
  }
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_ENCODABLE_VALUE_H_
