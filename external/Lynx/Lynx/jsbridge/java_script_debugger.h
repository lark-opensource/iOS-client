// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JAVA_SCRIPT_DEBUGGER_H_
#define LYNX_JSBRIDGE_JAVA_SCRIPT_DEBUGGER_H_

#include <memory>
#include <string>

namespace lynx {
namespace lepus {
class Context;
}  // namespace lepus

namespace devtool {
class InspectorManager;
enum DebugType { v8_debug, quickjs_debug, lepus_debug, error_type };
}  // namespace devtool

namespace piper {

class Runtime;

/*
 * The class used to debug javascript, this is a virtual class.
 */

class JavaScriptDebugger
    : public std::enable_shared_from_this<JavaScriptDebugger> {
 public:
  JavaScriptDebugger(){};
  virtual ~JavaScriptDebugger(){};

  virtual void InitWithRuntime(const std::shared_ptr<piper::Runtime>& runtime,
                               const std::string& group_id,
                               bool is_worker = false) = 0;
  virtual void InitWithContext(
      const std::shared_ptr<lepus::Context>& context) = 0;
  virtual void OnDestroy(bool is_worker = false) = 0;
  virtual void StopDebug() = 0;
  virtual void SetInspectorManager(
      std::shared_ptr<devtool::InspectorManager> manager){};
  virtual devtool::DebugType GetDebugType() = 0;
};

class JavaScriptDebuggerWrapper {
 public:
  JavaScriptDebuggerWrapper(std::shared_ptr<JavaScriptDebugger> debugger)
      : debugger_(debugger) {}

 public:
  std::shared_ptr<JavaScriptDebugger> debugger_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JAVA_SCRIPT_DEBUGGER_H_
