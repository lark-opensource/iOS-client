// Copyright 2020 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_BEBUG_VMSDK_ASSERT_H_
#define VMSDK_BASE_BEBUG_VMSDK_ASSERT_H_

#include <memory>
#include <string>

#include "basic/compiler_specific.h"
#include "basic/log/logging.h"

#ifdef BUILD_LEPUS
#include "lepus/exception.h"
#endif

enum ErrCode : int32_t {
  VMSDK_ERROR_CODE_SUCCESS = 0,
  VMSDK_ERROR_CODE_JNI = 100,
  VMSDK_ERROR_CODE_JS = 200,
  // issue: #1510, 9xx, use for module
  VMSDK_ERROR_CODE_MODULE_NOT_EXIST = 900,
  VMSDK_ERROR_CODE_MODULE_FUNC_NOT_EXIST = 901,
  VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM = 902,
  VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE = 903,
  VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION = 904,
  VMSDK_ERROR_CODE_MODULE_BUSINESS_ERROR = 905,
  VMSDK_ERROR_CODE_MODULE_FUNC_PROMISE_ARG_NOT_FUNC = 906,
  VMSDK_ERROR_CODE_MODULE_FUNC_PROMISE_ARG_NUM_WRONG = 907,
  VMSDK_ERROR_CODE_WORKER = 9000,
  VMSDK_ERROR_CODE_OTHER = 10000,
};

namespace vmsdk {
namespace general {

struct VmsdkException {
  VmsdkException(int error_code, const char *format, ...);

  VmsdkException(int error_code, std::string &&error_message)
      : error_code_(error_code), error_message_(error_message) {
    LOGI("VmsdkException occurs error_code:" << error_code << " error_message:"
                                             << error_message_);
  }

  int error_code_;
  std::string error_message_;
};

class ExceptionStorage {
 public:
  static ExceptionStorage &GetInstance();

  template <typename... T>
  void SetException(T &&... args) {
    if (exception_ == nullptr) {
      exception_ = std::make_unique<VmsdkException>(std::forward<T>(args)...);
    }
  }

  void Reset() { exception_ = nullptr; }

  const std::unique_ptr<VmsdkException> &GetException() const {
    return exception_;
  }

 private:
  ExceptionStorage() = default;
  std::unique_ptr<VmsdkException> exception_;
};

}  // namespace general
}  // namespace vmsdk

#endif
