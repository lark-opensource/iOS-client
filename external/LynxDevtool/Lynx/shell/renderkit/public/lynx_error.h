// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ERROR_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ERROR_H_

#include <string>
namespace lynx {
class LynxError {
 public:
  static constexpr int kLynxErrorCodeSuccess = 0;
  static constexpr int kLynxErrorCodeLoadTemplate = 100;
  static constexpr int kLynxErrorCodeLayout = 102;
  static constexpr int kLynxErrorCodeTemplateProvider = 103;

  /* placeholder */ static constexpr int kLynxErrorCodeRuntimeEntry = 104;
  static constexpr int kLynxErrorCodeJavaScript = 201;
  static constexpr int kLynxErrorCodeForResourceError = 301;
  static constexpr int kLynxErrorCodeComponentNotExist = 302;
  static constexpr int kLynxErrorCodeUpdate = 401;
  /* placeholder */ static constexpr int kLynxErrorCodeDataBinding = 402;
  /* placeholder */ static constexpr int kLynxErrorCodeDom = 403;
  /* placeholder */ static constexpr int kLynxErrorCodeParseData = 404;
  /* placeholder */ static constexpr int kLynxErrorCodeCanvas = 501;
  static constexpr int kLynxErrorCodeException = 601;
  /* placeholder */ static constexpr int kLynxErrorCodeBaseLib = 701;
  /* placeholder */ static constexpr int kLynxErrorCodeJni = 801;
  static constexpr int kLynxErrorCodeModuleNotExist = 900;
  static constexpr int kLynxErrorCodeModuleFuncNotExist = 901;
  static constexpr int kLynxErrorCodeModuleFunWrongArgNum = 902;
  static constexpr int kLynxErrorCodeModuleFuncWrongArgType = 903;
  static constexpr int kLynxErrorCodeModuleFuncCallException = 904;
  static constexpr int kLynxErrorCodeModuleBusinessError = 905;
  static constexpr int kLynxErrorCodeModuleFuncPromiseArgNotFunc = 906;
  static constexpr int kLynxErrorCodeModuleFuncPromiseArgNumWrong = 907;
  /* placeholder */ static constexpr int kLynxErrorCodeEvent = 1001;
  /* placeholder */ static constexpr int kLynxErrorCodeLepus = 1101;
  /* placeholder */ static constexpr int kLynxErrorCodeMainFlow = 1201;
  static constexpr int kLynxErrorCodeLynxViewDestroyNotOnUi = 1202;
  /* placeholder */ static constexpr int kLynxErrorCodeCss = 1301;
  /* placeholder */ static constexpr int kLynxErrorCodeAsset = 1401;
  /* placeholder */ static constexpr int kLynxErrorCodeCli = 1501;
  static constexpr int kLynxErrorDynamicComponentLoadFail = 1601;
  static constexpr int kLynxErrorDynamicComponentFileEmpty = 1602;
  static constexpr int kLynxErrorDynamicComponentDecodeFail = 1603;
  static constexpr int kLynxErrorCodeExternalSource = 1701;
  /* placeholder */ static constexpr int kLynxErrorCodeEventException = 1801;
  /* placeholder */ static constexpr int kLynxErrorCodeBinary = 9901;

  LynxError(const std::string& msg, int code);

  int GetErrorCode() const { return error_code_; }

  std::string GetMsg() { return msg_; }

 private:
  int error_code_;
  std::string msg_;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ERROR_H_
