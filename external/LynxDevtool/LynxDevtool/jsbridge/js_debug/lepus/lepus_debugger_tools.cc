// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus_debugger_tools.h"

#include <queue>

#include "lepus/vm_context.h"

namespace lynx {
namespace lepus {

std::string &DebugTool::GetRootFunctionSource() {
  static std::string root_function_source;
  return root_function_source;
}

void DebugTool::SetRootFunctionSource(const std::string &source) {
  GetRootFunctionSource() = source;
}

// given a scope, return the start and end location
void DebugTool::GetScopeLineColInfo(const Value &scope, int32_t &start_line,
                                    int32_t &start_col, int32_t &end_line,
                                    int32_t &end_col) {
  Value start = scope.GetProperty(Function::kStartLine);
  Value end = scope.GetProperty(Function::kEndLine);
  Function::DecodeLineCol(start.Number(), start_line, start_col);
  Function::DecodeLineCol(end.Number(), end_line, end_col);
}

void DebugTool::GetPCLineCol(
    const lynx::base::scoped_refptr<Function> &function, int32_t index,
    int32_t &line, int32_t &col) {
  function->GetLineCol(index, line, col);
  // line and col start from 0
  if (line != -1 && col != -1) {
    line--;
    col--;
  }
}

// given callframe, return the current function this frame belongs
lynx::base::scoped_refptr<Function> DebugTool::GetCurrentFunction(
    Frame *frame) {
  lynx::base::scoped_refptr<Closure> current_closure =
      frame->function_->GetClosure();
  lynx::base::scoped_refptr<Function> current_function =
      current_closure->function();
  return current_function;
}

// use BFS to get the parent scope of the targe scope
Value DebugTool::GetParentScopeBFS(VMContext *context, Frame *frame,
                                   const Value &target) {
  std::queue<base::scoped_refptr<Function>> function_queue;
  function_queue.push(context->GetRootFunction());

  // the scope structure is as follows
  // function has nested scope. and the function has nested child function.
  // so if we use bfs to search parent scope of the target scope.
  // we need to traverse from the root function, using bfs to visit child
  // function. in each function, we need to traverse from the top scope, using
  // bfs to visit child scope

  while (!function_queue.empty()) {
    base::scoped_refptr<Function> function = function_queue.front();
    function_queue.pop();

    // scope -> child scope
    // given a function, traverse from the top scope, using the bfs to visit
    // child scope
    std::queue<Value> scope_queue;
    scope_queue.push(function->GetScope());
    while (!scope_queue.empty()) {
      Value value = scope_queue.front();
      scope_queue.pop();
      Value child_scopes = value.GetProperty(Function::kChilds);
      if (child_scopes.Array()) {
        size_t size = child_scopes.Array()->size();
        // traverse all the child scope
        for (size_t i = 0; i < size; i++) {
          Value child_scope = child_scopes.Array()->get(i);
          if (child_scope == target) {
            if (function == GetCurrentFunction(frame)) {
              return value;
            } else {
              // other frame
              return Value();
            }
          }
          scope_queue.push(child_scope);
        }
      }
    }

    // function -> child function
    std::vector<base::scoped_refptr<Function>> childs =
        function->GetChildFunction();
    // given the function, traverse all the child function using bfs
    for (const auto &child_function : childs) {
      // if the scope of child function is the target, mean the parent scope is
      // in current function
      if (child_function->GetScope() == target) {
        if (function == GetCurrentFunction(frame)) {
          // in the function, the first scope is the parameters scope.
          // we need to get function body scope, that is the first child scope
          Value result_child =
              function->GetScope().GetProperty(Function::kChilds);
          if (result_child.Array()) {
            size_t size = result_child.Array()->size();
            if (size > 0) {
              return result_child.Array()->get(0);
            }
          }
          return function->GetScope();
        } else {
          // other frame
          return Value();
        }
      }
      function_queue.push(child_function);
    }
  }
  return Value();
}

// get unique id for object or function
int32_t DebugTool::GenerateObjectId(Frame *current_frame, const Value &object) {
  Value id = Value();
  // debugger_object_id_map: <object_id, <object, frame>>
  for (auto &iter : object_id_map_) {
    // if this object is already has an object id, just return this object id
    if (iter.second.first == object) {
      id = Value(iter.first);
      break;
    }
  }

  if (id.IsNil()) {
    // genereate an unique object id
    id = Value(debugger_object_id_++);
    // save in debugger object_id_map
    object_id_map_.insert(
        {static_cast<int32_t>(id.Number()), {object, current_frame}});
  }
  // save in id_object_map
  id_object_map_.insert({std::to_string(static_cast<int32_t>(id.Number())),
                         {object, current_frame}});
  return id.Number();
}

// given a scope, get start end end location
// location format ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
void DebugTool::GetScopeStartAndEndLocation(const Value &function_scope,
                                            Value &start_location,
                                            Value &end_location) {
  int32_t scope_start_line = 0, scope_start_column = 0, scope_end_line = 0,
          scope_end_column = 0;

  GetScopeLineColInfo(function_scope, scope_start_line, scope_start_column,
                      scope_end_line, scope_end_column);

  start_location = Value(Dictionary::Create());
  end_location = Value(Dictionary::Create());
  start_location.Table()->SetValue("scriptId", Value(StringImpl::Create("0")));
  start_location.Table()->SetValue("lineNumber", Value(scope_start_line));
  start_location.Table()->SetValue("columnNumber", Value(scope_start_column));

  end_location.Table()->SetValue("scriptId", Value(StringImpl::Create("0")));
  end_location.Table()->SetValue("lineNumber", Value(scope_end_line));
  end_location.Table()->SetValue("columnNumber", Value(scope_end_column));
}

// given scope, get scope information we needed
// scope format ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
Value DebugTool::GetScopeInfo(Frame *current_frame, const Value &current_scope,
                              const std::string &type) {
  auto current_function = GetCurrentFunction(current_frame);
  Value function_scope = current_function->GetScope();

  Value scopeInfo = Value(Dictionary::Create());
  scopeInfo.Table()->SetValue("type", Value(StringImpl::Create(type.c_str())));
  Value object = Value(Dictionary::Create());
  object.Table()->SetValue("type", Value(StringImpl::Create("object")));
  int32_t scope_id = GenerateObjectId(current_frame, current_scope);
  object.Table()->SetValue("objectId", Value(scope_id));
  scopeInfo.Table()->SetValue("object", object);

  Value scope_start_location;
  Value scope_end_location;
  GetScopeStartAndEndLocation(function_scope, scope_start_location,
                              scope_end_location);

  scopeInfo.Table()->SetValue("startLocation", scope_start_location);
  scopeInfo.Table()->SetValue("endLocation", scope_end_location);
  return scopeInfo;
}

// find the smallest satisfied scope for this pc
Value DebugTool::GetPCScope(const Value &function_scope, int32_t pc_line,
                            int32_t pc_col) {
  // find all the child scope of this function scope, find the smallest range
  // scope this pc belongs
  Value current_scope = function_scope;
  Value childs = function_scope.GetProperty(Function::kChilds);
  if (childs.Array()) {
    size_t size = childs.Array()->size();
    for (size_t i = 0; i < size; i++) {
      Value child_scope = childs.Array()->get(i);
      if (child_scope.IsTable()) {
        int32_t child_start_line, child_start_col, child_end_line,
            child_end_col;
        GetScopeLineColInfo(function_scope, child_start_line, child_start_col,
                            child_end_line, child_end_col);

        if ((pc_line > child_start_line && pc_line < child_end_line) ||
            (pc_line == child_start_line && pc_col > child_start_col) ||
            (pc_line == child_end_line && pc_col < child_end_col)) {
          current_scope = child_scope;
          Value next_scope_satisfied = GetPCScope(child_scope, pc_line, pc_col);
          if (next_scope_satisfied == Value()) {
            return current_scope;
          } else {
            return next_scope_satisfied;
          }
        } else {
          continue;
        }
      }
    }
  }
  return Value();
}

// get the scope chain of this frame
// scope chain is an array of scope, including local scope and closure scope
Value DebugTool::GetCallFrameScopeChain(VMContext *context, Frame *frame,
                                        int32_t current_pc) {
  auto current_function = GetCurrentFunction(frame);
  Value scopeChain = Value(lepus::CArray::Create());

  // get line & col of current pc
  int32_t pc_line = 0;
  int32_t pc_col = 0;
  GetPCLineCol(current_function, current_pc, pc_line, pc_col);

  // get the scope of current pc
  Value function_scope = current_function->GetScope();
  // get the smallest-range scope using pc line & col
  Value current_scope = GetPCScope(function_scope, pc_line, pc_col);

  // first get all the scope in current function,
  // then devided into two parts, local variables, and closure variables
  std::vector<Value> scopes_in_this_function;
  Value local_variables = Value(Dictionary::Create());
  Value closure_variables = Value(Dictionary::Create());
  local_variables.SetProperty(Function::kScopesName, Value("scope"));
  closure_variables.SetProperty(Function::kScopesName, Value("scope"));

  Value scope = current_scope;
  while (!scope.IsNil()) {
    scopes_in_this_function.push_back(scope);
    Value parent_scope = GetParentScopeBFS(context, frame, scope);
    scope = parent_scope;
  }

  // traverse all the variables, find which is local variable and which is
  // closure variable
  for (auto &iter : scopes_in_this_function) {
    if (!iter.IsTable()) continue;
    for (const auto &it : *iter.Table()) {
      int32_t type = -1;
      int32_t reg_index = -1;
      int32_t array_index = -1;
      int32_t offset = -1;
      if (!it.second.IsUInt32()) continue;
      Function::DecodeVariableInfo(it.second.UInt32(), type, reg_index,
                                   array_index, offset);
      // type = 0: local varialbes
      // type = 1 or type = 2: closure variables
      // type = 1: closure variables it is not defined in this function
      // type = 2: closure variables it is defined in this function
      if (type == 0) {
        local_variables.SetProperty(it.first, Value(it.second.UInt32()));
      } else if (type == 1) {
        closure_variables.SetProperty(it.first, Value(it.second.UInt32()));
      } else if (type == 2) {
        closure_variables.SetProperty(it.first, Value(it.second.UInt32()));
      }
    }
  }

  Value scopeInfo_local = GetScopeInfo(frame, local_variables, "local");
  Value scopeInfo_closure = GetScopeInfo(frame, closure_variables, "closure");
  scopeChain.Array()->push_back(scopeInfo_local);
  scopeChain.Array()->push_back(scopeInfo_closure);

  return scopeChain;
}

// given frame, find the current position
Value DebugTool::GetCallframeLocation(VMContext *context, Frame *frame,
                                      int32_t current_pc) {
  Value location = Value(lepus::Dictionary::Create());
  auto current_function = GetCurrentFunction(frame);
  int32_t call_frame_start_line = 0;
  int32_t call_frame_start_col = 0;
  if (frame == context->GetCurrentFrame()) {
    GetPCLineCol(current_function, current_pc, call_frame_start_line,
                 call_frame_start_col);
  } else {
    GetPCLineCol(current_function, frame->current_pc_, call_frame_start_line,
                 call_frame_start_col);
  }

  location.Table()->SetValue("scriptId", Value(StringImpl::Create("0")));
  location.Table()->SetValue("lineNumber", Value(call_frame_start_line));
  location.Table()->SetValue("columnNumber", Value(call_frame_start_col));
  return location;
}

Value DebugTool::GetCallFrameThisObject(VMContext *context) {
  Value this_object = Value(Dictionary::Create());
  this_object.Table()->SetValue("type", Value(StringImpl::Create("object")));
  this_object.Table()->SetValue("className",
                                Value(StringImpl::Create("Object")));
  this_object.Table()->SetValue("description",
                                Value(StringImpl::Create("Object")));
  this_object.Table()->SetValue(
      "objectId",
      Value(GenerateObjectId(context->GetCurrentFrame(),
                             *context->GetCurrentFrame()->function_)));
  return this_object;
}

// get callframe stack given current pc
// callframe format ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-CallFrame
Value DebugTool::GetCallFrames(VMContext *context, int32_t current_pc) {
  // when system paused, reset these variables for variable display
  object_id_map_.clear();
  id_object_map_.clear();
  debugger_object_id_ = 0;
  Frame *frame = context->GetCurrentFrame();
  Value result_callframe_array = Value(lepus::CArray::Create());
  // traverse the frame stack
  while (frame) {
    auto current_function = GetCurrentFunction(frame);
    Value dic = Value(lepus::Dictionary::Create());

    dic.Table()->SetValue("callFrameId", Value(frame->debugger_frame_id_));

    std::string function_name = current_function->GetFunctionName();
    dic.Table()->SetValue("functionName",
                          Value(StringImpl::Create(function_name.c_str())));

    std::string url = "lepus.js";
    dic.Table()->SetValue("url", Value(StringImpl::Create(url.c_str())));

    Value location = GetCallframeLocation(context, frame, current_pc);
    dic.Table()->SetValue("location", location);

    Value scopeChain = GetCallFrameScopeChain(context, frame, current_pc);
    dic.Table()->SetValue("scopeChain", scopeChain);

    Value this_object = GetCallFrameThisObject(context);
    dic.Table()->SetValue("this", this_object);

    result_callframe_array.Array()->push_back(dic);
    frame = frame->prev_frame_;
    if (frame == frame->prev_frame_) {
      break;
    }
  }
  return result_callframe_array;
}

// given the scope and the frame it belongs, return the variables in this given
// scope
void DebugTool::GetScopeVariables(Frame *frame, const Value &scopes_value,
                                  Value &variables) {
  if (!scopes_value.IsTable()) return;
  for (const auto &it : *scopes_value.Table()) {
    int32_t type = -1;
    int32_t reg_index = -1;
    int32_t array_index = -1;
    int32_t offset = -1;
    if (!it.second.IsUInt32()) continue;
    Function::DecodeVariableInfo(it.second.UInt32(), type, reg_index,
                                 array_index, offset);
    if (type == 0) {
      Value *regs = frame->register_;
      Value *result = regs + reg_index;
      variables.Table()->SetValue(it.first.str(), *result);
    } else if (type == 1) {
      lynx::base::scoped_refptr<Closure> current_closure =
          frame->function_->GetClosure();
      Value array = current_closure->GetContext();
      if (array.IsArray()) {
        while (offset > 0) {
          array = array.Array()->get(0);
          offset--;
        }
        if (array.IsArray()) {
          variables.Table()->SetValue(it.first.str(),
                                      array.Array()->get(array_index));
        }
      }
    } else if (type == 2) {
      Value *regs = frame->register_;
      Value *current_context = regs + offset;
      if (current_context->IsArray()) {
        variables.Table()->SetValue(it.first.str(),
                                    current_context->Array()->get(array_index));
      }
    }
  }
}

// given an object_id, return the properties
void DebugTool::GetProperties(const std::string &object_id, Value &variables,
                              Frame *frame) {
  auto element = id_object_map_.find(object_id);
  // find the scope object with this object_id
  if (element != id_object_map_.end()) {
    // element: <scope object, frame it belongs>
    Value value = element->second.first;
    frame = element->second.second;
    // if this object is a scope object, just return the variables in this scope
    // else this object is a normal object, generate a unique object id, and
    // reutrn
    if (value.IsTable() && !value.GetProperty(Function::kScopesName).IsNil()) {
      // get variables in this scope
      GetScopeVariables(frame, value, variables);
      // if the variable if a table,
      if (variables.IsTable()) {
        for (auto tb_iter : *variables.Table()) {
          if (tb_iter.second.IsObject() || tb_iter.second.IsClosure() ||
              tb_iter.second.IsArray() || tb_iter.second.IsCDate() ||
              tb_iter.second.IsRegExp()) {
            GenerateObjectId(frame, tb_iter.second);
          }
        }
      }
    } else if (value.IsTable() &&
               value.GetProperty(Function::kScopesName).IsNil()) {
      GenerateObjectId(frame, value);
      variables = value;
    }
  } else {
    LOGI("can not find this object, object id: " << object_id);
  }
}

// compute current frame depth
int32_t DebugTool::GetStackDepth(VMContext *context) {
  int32_t stack_depth = 0;
  // begin with 1
  Frame *frame = context->GetCurrentFrame();
  while (frame) {
    stack_depth++;
    if (frame == frame->prev_frame_) {
      break;
    }
    frame = frame->prev_frame_;
  }
  return stack_depth;
}

// get child function according to start and end line&col
// for example: root_source:
// function test() {
//  let a = 1;
//}
// function test2() {
//  let b = 1;
//}
// test1();
// test2();
// given start_line: 0, start_col: 0, end_line: 2, end_col: 1. this function
// will return: function test() {
//    let a = 1;
//}
std::string DebugTool::GetChildFunctionSourceCode(
    const std::string &root_source_code, int32_t start_line, int32_t start_col,
    int32_t end_line, int32_t end_col) {
  if (root_source_code == "") {
    return "";
  }
  int32_t line_num = 0;
  std::string result;
  std::string line = "";
  uint32_t index = 0;
  while (index < root_source_code.size()) {
    if (!(root_source_code[index] == '\n')) {
      line += root_source_code[index];
    } else {
      if (line_num < start_line) {
      } else if (line_num == start_line) {
        // in the target start line, search for the target start column
        for (size_t column_index = 0; column_index < line.size();
             column_index++) {
          if (column_index >= static_cast<size_t>(start_col)) {
            result += line[column_index];
          }
        }
        result += '\n';
      } else if (line_num == end_line) {
        // in the target end line, search for the target end column
        for (size_t column_index = 0; column_index < line.size();
             column_index++) {
          if (column_index < static_cast<size_t>(end_col)) {
            result += line[column_index];
          } else {
            break;
          }
        }
        break;
      } else {
        result += line;
        result += "\n";
      }
      line_num++;
      line = "";
    }
    index++;
  }

  // if target end_line is the last line
  if (line != "" && end_line == line_num) {
    for (size_t column_index = 0; column_index < line.size(); column_index++) {
      if (column_index < static_cast<size_t>(end_col)) {
        result += line[column_index];
      } else {
        break;
      }
    }
  }
  return result;
}

// if the given function is root function, return the entire lepus.js content
// if the given function is not the root function, use function scope and get
// the function start and end range. use this range to get the child scope
// function source
std::string DebugTool::GetFunctionSourceCode(
    const base::scoped_refptr<Function> &function, bool is_root_function) {
  std::string source = function->GetSource();
  if (source != "") return source;
  std::vector<Value> const_values = function->GetConstValue();
  if (const_values.empty()) return "";
  lepus::Value last = const_values.back();

  if (last.IsTable()) {
    if (is_root_function) {
      Value name = last.Table()->GetValue(Function::kFuncSource);
      if (name.IsString()) {
        source = name.String()->str();
        SetRootFunctionSource(source);
        function->SetSource(source);
        return source;
      }
    } else {
      int32_t start_line, start_col, end_line, end_col;
      lepus::Value scope = function->GetScope();

      GetScopeLineColInfo(scope, start_line, start_col, end_line, end_col);
      LOGI("child function: " << start_line << " " << start_col << " "
                              << end_line << " " << end_col);
      source = GetChildFunctionSourceCode(GetRootFunctionSource(), start_line,
                                          start_col, end_line, end_col);
      function->SetSource(source);
    }
  }
  return source;
}

std::unordered_map<std::string, std::pair<Value, Frame *>>
DebugTool::GetDebuggerIdObjectMap() {
  return id_object_map_;
};

std::unordered_map<int32_t, std::pair<Value, Frame *>>
DebugTool::GetDebuggerObjectIdMap() {
  return object_id_map_;
};

void DebugTool::SetDebuggerIdObjectMap(const std::string &key,
                                       std::pair<Value, Frame *> value) {
  id_object_map_[key] = value;
}

void DebugTool::SetDebuggerObjectIdMap(int32_t key,
                                       std::pair<Value, Frame *> value) {
  object_id_map_[key] = value;
}

}  // namespace lepus
}  // namespace lynx
