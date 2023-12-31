// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_LEPUS_DEBUGGER_TOOLS_H
#define LEPUS_LEPUS_DEBUGGER_TOOLS_H
#include <unordered_map>
#include <unordered_set>

#include "base/ref_counted.h"

namespace lynx {
namespace lepus {

class VMContext;
class Value;
struct Frame;
class Function;

class DebugTool {
 public:
  DebugTool() {
    debugger_object_id_ = 0;
    id_object_map_.clear();
    object_id_map_.clear();
    SetRootFunctionSource("");
  }
  // when paused, use this function to get the callframe stack, for variables
  // display
  Value GetCallFrames(VMContext* context, int32_t current_pc);
  // when paused, use this function to get scope chain for one frame.
  Value GetCallFrameScopeChain(VMContext* context, Frame* frame,
                               int32_t current_pc);

  // get current function of the frame
  lynx::base::scoped_refptr<Function> GetCurrentFunction(Frame* frame);
  // use bfs to get the parent scope of scope target
  Value GetParentScopeBFS(VMContext* context, Frame* frame,
                          const Value& target);

  // scope information ref:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
  Value GetScopeInfo(Frame* current_frame, const Value& current_scope,
                     const std::string& type);
  // get unique id for each object
  int32_t GenerateObjectId(Frame* frame, const Value& object);

  // given object id, call this function to get the object properties
  void GetProperties(const std::string& object_id, Value& variables,
                     Frame* frame);
  // given the scope and the frame it belongs, return the variables in this
  // given scope
  void GetScopeVariables(Frame* frame, const Value& scopes, Value& variables);
  // traverse the callframe stack, get the current frame depth
  int32_t GetStackDepth(VMContext* context);
  // given a function, return the function source code
  static std::string GetFunctionSourceCode(
      const lynx::base::scoped_refptr<Function>& function,
      bool is_root_function = true);
  // use start line, start col, end line, end col, return the child function
  // source in lepus.js
  static std::string GetChildFunctionSourceCode(const std::string& root_source,
                                                int32_t start_line,
                                                int32_t start_col,
                                                int32_t end_line,
                                                int32_t end_col);

  // < object_id(string), <object(lepus value type), frame this object belongs>>
  std::unordered_map<std::string, std::pair<Value, Frame*>>
  GetDebuggerIdObjectMap();
  // <object_id(int32_t), <object(lepus value type), frame this object belongs>>
  std::unordered_map<int32_t, std::pair<Value, Frame*>>
  GetDebuggerObjectIdMap();
  void SetDebuggerIdObjectMap(const std::string& key,
                              std::pair<Value, Frame*> value);
  void SetDebuggerObjectIdMap(int32_t key, std::pair<Value, Frame*> value);

  // given a scope, return the start and end position(type int32_t)
  static void GetScopeLineColInfo(const Value& scope, int32_t& start_line,
                                  int32_t& start_col, int32_t& end_line,
                                  int32_t& end_col);
  // given a function and pc index, return the line and col number of this pc
  // line and col number start from 0
  void GetPCLineCol(const lynx::base::scoped_refptr<Function>&, int32_t index,
                    int32_t& line, int32_t& col);

  // initialize root function source
  static std::string& GetRootFunctionSource();
  static void SetRootFunctionSource(const std::string& source);

 private:
  // use pc th get the current location
  Value GetCallframeLocation(VMContext* context, Frame* frame,
                             int32_t current_pc);
  // get this object of current frame, ref:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-CallFrame
  Value GetCallFrameThisObject(VMContext* context);
  // given pc, find the smallest satisfied scope
  Value GetPCScope(const Value& function_scope, int32_t pc_line,
                   int32_t pc_col);
  // given a scope, return the start and end position(lepus value type)
  void GetScopeStartAndEndLocation(const Value& function_scope,
                                   Value& start_location, Value& end_location);

  // for debugger.properties: <object id, <scope, frame>>
  std::unordered_map<std::string, std::pair<Value, Frame*>> id_object_map_;
  std::unordered_map<int32_t, std::pair<Value, Frame*>> object_id_map_;
  int32_t debugger_object_id_;
};
}  // namespace lepus
}  // namespace lynx
#endif  // LEPUS_LEPUS_DEBUGGER_TOOLS_H
