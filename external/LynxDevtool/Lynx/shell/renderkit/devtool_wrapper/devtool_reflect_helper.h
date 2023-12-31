// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_DEVTOOL_REFLECT_HELPER_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_DEVTOOL_REFLECT_HELPER_H_

#include <string>
#include <unordered_map>

#include "base/no_destructor.h"

#define REGISTER_REFLECT(class_name)                            \
  class_name* create##class_name() { return new class_name; }   \
  lynx::devtool::RegisterReflectHelper g##class_name##Register( \
      #class_name, (lynx::devtool::PTRCreateObject)create##class_name)

#define REGISTER_DEVTOOL_SINGLETON(class_name)                        \
  class_name& get##class_name() { return class_name::GetInstance(); } \
  lynx::devtool::RegisterReflectHelper g##class_name##Register(       \
      #class_name, (lynx::devtool::PTRGetInstance)get##class_name)

namespace lynx {
namespace devtool {

class DevtoolObject;

using PTRCreateObject = void* (*)(void);
using PTRGetInstance = DevtoolObject& (*)(void);

class ReflectHelper {
 public:
  static ReflectHelper& GetInstance();

  void* CreateInstanceByName(const std::string& class_name);
  DevtoolObject& GetInstanceByName(const std::string& class_name);

  void RegistClass(const std::string& name, PTRCreateObject method);
  void RegistSingleton(const std::string& name, PTRGetInstance method);

  ReflectHelper(const ReflectHelper&) = delete;
  ReflectHelper& operator=(const ReflectHelper&) = delete;
  ReflectHelper(ReflectHelper&&) = delete;
  ReflectHelper& operator=(ReflectHelper&&) = delete;

 private:
  ReflectHelper() = default;

  friend class base::NoDestructor<ReflectHelper>;

  std::unordered_map<std::string, PTRCreateObject> class_map_;
  std::unordered_map<std::string, PTRGetInstance> singleton_map_;

  static DevtoolObject invalid_object_;
};

class RegisterReflectHelper {
 public:
  explicit RegisterReflectHelper(const std::string& class_name,
                                 PTRCreateObject p_create_func) {
    ReflectHelper::GetInstance().RegistClass(class_name, p_create_func);
  };

  explicit RegisterReflectHelper(const std::string& class_name,
                                 PTRGetInstance p_get_func) {
    ReflectHelper::GetInstance().RegistSingleton(class_name, p_get_func);
  };
};

class DevtoolObject {
 public:
  explicit DevtoolObject() = default;
  explicit DevtoolObject(bool is_null_object)
      : is_null_object_(is_null_object){};
  virtual ~DevtoolObject() = default;
  bool is_null_object() { return is_null_object_; };

 private:
  bool is_null_object_ = false;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_DEVTOOL_REFLECT_HELPER_H_
