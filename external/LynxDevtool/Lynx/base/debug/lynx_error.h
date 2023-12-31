// Copyright 2023 The Lynx Authors. All rights reserved.
#ifndef LYNX_BASE_DEBUG_LYNX_ERROR_H_
#define LYNX_BASE_DEBUG_LYNX_ERROR_H_
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "base/base_export.h"
#include "base/log/logging.h"

namespace lynx {
namespace base {

struct LynxError {
  BASE_EXPORT_FOR_DEVTOOL LynxError(int error_code, const char* format, ...);

  LynxError(int error_code, std::string error_message)
      : error_code_(error_code), error_message_(std::move(error_message)) {
    LOGI("LynxError occurs error_code:" << error_code
                                        << " error_message:" << error_message_);
  }

  int error_code_;

  std::string error_message_;
};

class ErrorStorage {
 public:
  BASE_EXPORT_FOR_DEVTOOL static ErrorStorage& GetInstance();

  template <typename... T>
  void SetError(T&&... args) {
    if (error_ == nullptr) {
      error_ = std::make_unique<LynxError>(std::forward<T>(args)...);
    }
  }

  void Reset() { error_ = nullptr; }

  const std::unique_ptr<LynxError>& GetError() const { return error_; }

 private:
  ErrorStorage() = default;

  std::unique_ptr<LynxError> error_;
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_DEBUG_LYNX_ERROR_H_
