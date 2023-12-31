//
// Created by shiwentao on 2019/10/28.
//

#include "jsbridge/bindings/system_info.h"

#include "tasm/config.h"

namespace lynx {
namespace piper {

std::vector<PropNameID> SystemInfo::getPropertyNames(Runtime &rt) {
  std::vector<PropNameID> vec;
  vec.push_back(piper::PropNameID::forUtf8(rt, "platform"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "pixelRatio"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "pixelWidth"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "pixelHeight"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "osVersion"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "enableKrypton"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "runtimeType"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "lynxSdkVersion"));
  return vec;
}

Value SystemInfo::get(Runtime *rt, const PropNameID &name) {
  piper::Scope scope(*rt);

  auto methodName = name.utf8(*rt);
  if (methodName == "platform") {
    return String::createFromAscii(*rt, tasm::Config::Platform());
  } else if (methodName == "pixelWidth") {
    return Value(static_cast<double>(tasm::Config::pixelWidth()));
  } else if (methodName == "pixelHeight") {
    return Value(static_cast<double>(tasm::Config::pixelHeight()));
  } else if (methodName == "pixelRatio") {
    return Value(static_cast<double>(tasm::Config::pixelRatio()));
  }
  if (methodName == "osVersion") {
    return String::createFromAscii(*rt, tasm::Config::GetOsVersion());
  } else if (methodName == "enableKrypton") {
    return Value(tasm::Config::enableKrypton());
  } else if (methodName == "runtimeType") {
    switch (rt->type()) {
      case v8:
        return String::createFromAscii(*rt, "v8");
      case jsc:
        return String::createFromAscii(*rt, "jsc");
      case quickjs:
        return String::createFromAscii(*rt, "quickjs");
      default:
        return String::createFromAscii(*rt, "");
    }
  } else if (methodName == "lynxSdkVersion") {
    return String::createFromAscii(*rt, tasm::Config::GetCurrentLynxVersion());
  }
  return piper::Value::undefined();
}

void SystemInfo::set(Runtime *rt, const PropNameID &name, const Value &value) {}

}  // namespace piper
}  // namespace lynx
