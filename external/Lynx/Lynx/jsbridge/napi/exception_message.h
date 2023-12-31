// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_EXCEPTION_MESSAGE_H_
#define LYNX_JSBRIDGE_NAPI_EXCEPTION_MESSAGE_H_

#include "base/base_export.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class ExceptionMessage {
 public:
  ~ExceptionMessage() = default;

  ExceptionMessage(const ExceptionMessage &) = delete;

  ExceptionMessage &operator=(const ExceptionMessage &) = delete;

  ExceptionMessage() = default;

  BASE_EXPORT static void NonObjectReceived(const Napi::Env &env,
                                            const char *dictionary_name);

  //  BASE_EXPORT static void NoRequiredProperty(const Napi::Env &env,
  //                                             const char *dictionary_name,
  //                                             const char *property_name);

  BASE_EXPORT static void IllegalConstructor(const Napi::Env &env,
                                             const char *interface_name);

  BASE_EXPORT static void FailedToCallOverload(const Napi::Env &env,
                                               const char *method_name);

  //  BASE_EXPORT static void NotImplemented(const Napi::Env &env);

  BASE_EXPORT static void NotEnoughArguments(const Napi::Env &env,
                                             const char *interface_name,
                                             const char *pretty_name,
                                             const char *expecting_name);

  BASE_EXPORT static void InvalidType(const Napi::Env &env,
                                      const char *pretty_name,
                                      const char *expecting_name);

  //  BASE_EXPORT static void NotSupportYet(const Napi::Env &env);

  BASE_EXPORT static void FailedToCallOverloadExpecting(
      const Napi::Env &env, const char *overload_name,
      const char *expecting_name);
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_NAPI_EXCEPTION_MESSAGE_H_
