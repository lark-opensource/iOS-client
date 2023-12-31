// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef LYNX_BASE_DEBUG_LYNX_ASSERT_H_
#define LYNX_BASE_DEBUG_LYNX_ASSERT_H_

#include <string>
#include <utility>

#include "base/compiler_specific.h"
#include "base/debug/error_code.h"
#include "base/debug/lynx_error.h"
#include "base/log/logging.h"
#include "base/string/string_utils.h"

#ifdef BUILD_LEPUS
#include "lepus/exception.h"
#endif

#define LynxInfo(error_code, ...)                                  \
  auto exception = lynx::base::LynxError(error_code, __VA_ARGS__); \
  lynx::base::ErrorStorage::GetInstance().SetError(std::move(exception));

#define LynxWarning(expression, error_code, ...)                            \
  if (!(expression)) {                                                      \
    auto exception = lynx::base::LynxError(error_code, __VA_ARGS__);        \
    lynx::base::ErrorStorage::GetInstance().SetError(std::move(exception)); \
  }

// ATTENTION: invoke this, will log and abort
#define LynxFatal(expression, error_code, ...)                           \
  if (!(expression)) {                                                   \
    LOGF("LynxFatal error: error_code:"                                  \
         << error_code                                                   \
         << " error_message:" << lynx::base::FormatString(__VA_ARGS__)); \
  }

// when env is lepus or debug, fatal.
// when runtime just warning.
#ifdef BUILD_LEPUS

#define CSS_WARNING(expression, ...)                           \
  do {                                                         \
    if (!(expression)) {                                       \
      auto error_msg = lynx::base::FormatString(__VA_ARGS__);  \
      if (tasm::UnitHandler::EnableCSSStrictMode()) {          \
        throw lynx::lepus::ParseException(error_msg.c_str(),   \
                                          " is not defined."); \
      } else {                                                 \
        LOGE(error_msg);                                       \
      }                                                        \
    }                                                          \
  } while (0)

#define CSS_WARNING_RETURN_FALSE(expression, ...)              \
  do {                                                         \
    if (!(expression)) {                                       \
      auto error_msg = lynx::base::FormatString(__VA_ARGS__);  \
      if (tasm::UnitHandler::EnableCSSStrictMode()) {          \
        throw lynx::lepus::ParseException(error_msg.c_str(),   \
                                          " is not defined."); \
      } else {                                                 \
        LOGE(error_msg);                                       \
      }                                                        \
      return false;                                            \
    }                                                          \
  } while (0)

#define CSS_UNREACHABLE(...)                                                  \
  if (tasm::UnitHandler::EnableCSSStrictMode()) {                             \
    auto error_msg = lynx::base::FormatString(__VA_ARGS__);                   \
    throw lynx::lepus::ParseException(error_msg.c_str(), " is not defined."); \
  }
#else

#define CLI_UNREACHABLE(...) \
  LynxWarning(false, LYNX_ERROR_CODE_ASSET, __VA_ARGS__)

#endif

#endif  // LYNX_BASE_DEBUG_LYNX_ASSERT_H_
