// Copyright 2020 The Vmsdk Authors. All rights reserved.

#include "basic/vmsdk_exception_common.h"

#include "basic/compiler_specific.h"
#include "basic/debug/backtrace.h"

#if defined(OS_IOS) && defined(__i386__)
#include "basic/threading/thread_local.h"
#endif

#ifdef BUILD_LEPUS
#include <cstdarg>
#endif

namespace vmsdk {
namespace general {

std::string GetMessage(const char *format, va_list args) {
  int length, size = 100;
  char *mes = nullptr;
  if ((mes = (char *)malloc(size * sizeof(char))) == nullptr) {
    return "";
  }
  while (1) {
    va_list copy_args;
    va_copy(copy_args, args);
    length = vsnprintf(mes, size, format, copy_args);
    va_end(copy_args);
    if (length > -1 && length < size) break;
    size *= 2;
    char *clone = (char *)realloc(mes, size * sizeof(char));
    if (clone == nullptr) {
      break;
    } else {
      mes = clone;
      clone = nullptr;
    }
  }
  std::string message = mes;
  free(mes);
  mes = nullptr;
  return message;
}

std::string GetErrorMessage(const char *format, ...) {
  std::string error_msg;
  va_list args;
  va_start(args, format);
  error_msg = GetMessage(format, args);
  va_end(args);
  return error_msg;
}

VmsdkException::VmsdkException(int error_code, const char *format, ...)
    : error_code_(error_code) {
  va_list args;
  va_start(args, format);
  error_message_ = GetMessage(format, args);
  va_end(args);
  LOGE("VmsdkException occurs error_code:" << error_code << " error_message:"
                                           << error_message_);
}

ExceptionStorage &ExceptionStorage::GetInstance() {
#if defined(OS_IOS) && defined(__i386__)
  // constructor is private, so must pass here
  static ThreadLocal<ExceptionStorage> instance(
      [] { return new ExceptionStorage; });
#else
  // static thread_local ExceptionStorage instance;
  static ExceptionStorage instance;
#endif
  return instance;
}

}  // namespace general
}  // namespace vmsdk
