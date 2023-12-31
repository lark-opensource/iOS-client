// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_CONSOLE_H_
#define LYNX_JSBRIDGE_BINDINGS_CONSOLE_H_

#include <memory>
#include <string>
#include <vector>

#include "jsbridge/bindings/console_message_postman.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class Runtime;

class Console : public HostObject {
 public:
  Console(Runtime* rt, std::shared_ptr<ConsoleMessagePostMan> post_man);

  // void RegFunctionToJs(Runtime& rt, Object& jsbridge);

  virtual Value get(Runtime*, const PropNameID& name) override;
  virtual void set(Runtime*, const PropNameID& name,
                   const Value& value) override;
  virtual std::vector<PropNameID> getPropertyNames(Runtime& rt) override;

  // for debug
  static std::string LogObject(Runtime* rt,
                               // const int level,
                               const Value* value);
  static std::string LogObject(Runtime* rt, const piper::Object* obj);

 private:
  piper::Value LogWithLevel(Runtime* rt, const int level, const Value* args,
                            size_t count, const std::string& func_name);
  piper::Value Assert(Runtime* rt, const int level, const Value* args,
                      size_t count, const std::string& func_name);
  static std::string LogObject_(Runtime* rt,
                                // const int level,
                                const Value* value);
  static std::string LogObject_(Runtime* rt, const Value* value,
                                std::vector<piper::Object>* pre_object_vector,
                                int depth);
  base::logging::LogChannel GetChannelType(Runtime* rt, const Value* args);

 private:
  Runtime* rt_;
  std::weak_ptr<ConsoleMessagePostMan> post_man_;
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_CONSOLE_H_
