// Copyright 2019 The Lynx Authors. All rights reserved.

// #include "lepus/vm_context.h"

#include "lepus/vm_context.h"

#include <base/log/logging.h>
#include <math.h>

#include <chrono>
#include <utility>

#include "base/lynx_env.h"
#include "base/string/string_number_convert.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/builtin.h"
#include "lepus/code_generator.h"
#include "lepus/exception.h"
#include "lepus/lepus_string.h"
#include "lepus/parser.h"
#include "lepus/path_parser.h"
#include "lepus/scanner.h"
// #include "ast_dump.h"
#include "lepus/lepus_date.h"
#include "lepus/output_stream.h"
#include "lepus/semantic_analysis.h"
#include "lepus/string_util.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/value_utils.h"

#ifdef LEPUS_TEST
#include "lepus/bytecode_print.h"
#endif

#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
#include "tasm/template_assembler.h"
#endif
#endif

#if ENABLE_CLI
#include "lepus/code_generator.h"
#include "lepus/parser.h"
#include "lepus/scanner.h"
#include "lepus/semantic_analysis.h"
#include "parser/input_stream.h"
#endif

namespace lynx {
namespace lepus {

#define GET_CONST_VALUE(i) (function->GetConstValue(Instruction::GetParamBx(i)))
#define GET_Global_VALUE(i) (global()->Get(Instruction::GetParamBx(i)))
#define GET_Builtin_VALUE(i) (builtin()->Get(Instruction::GetParamBx(i)))
#define GET_REGISTER_A(i) (regs + Instruction::GetParamA(i))
#define GET_REGISTER_B(i) (regs + Instruction::GetParamB(i))
#define GET_REGISTER_C(i) (regs + Instruction::GetParamC(i))

#define GET_UPVALUE_B(i) (closure->GetUpvalue(Instruction::GetParamB(i)))
#define GET_REGISTER_ABC(i) \
  a = GET_REGISTER_A(i);    \
  b = GET_REGISTER_B(i);    \
  c = GET_REGISTER_C(i);

void VMContext::SetSdkVersion(const std::string& sdk_version) {
  sdk_version_ = sdk_version;
}

void VMContext::Initialize() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "VMContext::Initialize");
  RegisterBuiltin(this);
  RegisterLepusVerion();
}

const std::string VMContext::Compile(const std::string& source,
                                     const char* sdk_version) {
  if (sdk_version) {
    std::string version(sdk_version);
    SetSdkVersion(version);
  }
#if ENABLE_CLI
  parser::InputStream input;
  input.Write(source);
  Scanner scanner(&input);
  scanner.SetSdkVersion(sdk_version_);
  Parser parser(&scanner);
  parser.SetSdkVersion(sdk_version_);
  SemanticAnalysis semantic_analysis;
  semantic_analysis.SetInput(&scanner);
  semantic_analysis.SetSdkVersion(sdk_version_);
  semantic_analysis.SetClosureFix(closure_fix_);

  CodeGenerator code_generator(this, &semantic_analysis);
  std::unique_ptr<ASTree> root;
  root.reset(parser.Parse());
  root->Accept(&semantic_analysis, nullptr);
  // ASTDump ast_dump;
  // root->Accept(&ast_dump, nullptr);
  root->Accept(&code_generator, nullptr);

  if (root_function_) {
    root_function_->SetSource(source);
  }
#endif
  return "";
}

bool VMContext::Execute(Value* ret_val) {
  if (root_function_.Get() == nullptr) {
    LOGE(
        "lepus-Execute: root_function_ is nullptr, template.lepus may be "
        "damaged!!");
    return false;
  }

  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LEPUS_EXECUTE);
  Value* top = heap().top_++;
  top->SetClosure(Closure::Create(root_function_.Get()));

  // init debugger
  if (GetInspector()) {
    DebuggerInitializer();
  }

  Value ret;
  if (current_frame_) {
    // not top frame
    CallFunction(heap().top_ - 1, 0, &ret);
  } else {
    // create top frame
    Frame top_frame;
    top_frame.register_ = heap_.base() + top_level_variables_.size() + 1;
    top_frame.prev_frame_ = &top_frame;
    current_frame_ = &top_frame;
    CallFunction(heap().top_ - 1, 0, &ret);
    current_frame_ = nullptr;
  }
  executed_ = true;
  if (ret_val) {
    *ret_val = ret;
  }
  return true;
}

Value VMContext::Call(const std::string& name, const std::vector<Value>& args) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("VMContext::Call:" + name);
              });
  Value ret;
  auto reg_info = top_level_variables_.find(name);
  if (reg_info == top_level_variables_.end()) {
    LOGE("lepus-call: not find " << name);
    return Value();
  }
  long reg = reg_info->second;
  Value* function = heap_.top_;
  *(heap_.top_++) = *(heap_.base() + reg + 1);
  for (const auto& arg : args) {
    *(heap_.top_++) = arg;
  }
  if (current_frame_) {
    // not top frame
    CallFunction(function, args.size(), &ret);
  } else {
    // create top frame
    Frame top_frame;
    top_frame.register_ = heap_.base() + top_level_variables_.size() + 1;
    top_frame.prev_frame_ = &top_frame;
    current_frame_ = &top_frame;
    CallFunction(function, args.size(), &ret);
    current_frame_ = nullptr;
  }
  return ret;
}

Value VMContext::PrepareClosureContext(
    const lynx::base::scoped_refptr<lepus::Closure>& clo) {
  if (clo.Get()) {
    Value last_context = closure_context_;
    closure_context_ = clo->GetContext();
    return last_context;
  }
  return closure_context_;
}

Value VMContext::CallWithClosure(const lepus::Value& closure,
                                 const std::vector<Value>& args) {
  Value ret;
  Value* function = heap_.top_;
  *(heap_.top_++) = closure;
  for (const auto& arg : args) {
    *(heap_.top_++) = arg;
  }
  if (current_frame_) {
    // not top frame
    CallFunction(function, args.size(), &ret);
  } else {
    // create top frame
    Frame top_frame;
    top_frame.register_ = heap_.base() + top_level_variables_.size() + 1;
    top_frame.prev_frame_ = &top_frame;
    current_frame_ = &top_frame;
    CallFunction(function, args.size(), &ret);
    current_frame_ = nullptr;
  }
  return ret;
}

#ifdef LEPUS_TEST
void VMContext::Dump() {
  Dumper dumper(root_function_.Get());
  dumper.Dump();
}
#endif

long VMContext::GetParamsSize() {
  return heap().top_ - current_frame_->register_;
}

Value* VMContext::GetParam(long index) {
  return current_frame_->register_ + index;
}

// check target's first level variable.
// 1. if update key is not path, simply add new k-v pair for the first level
// 2. if update key is value path, clone the first level k-v pair and update
//     the exact value.
bool VMContext::UpdateTopLevelVariable(const std::string& name,
                                       const Value& value) {
  auto result = ParseValuePath(name);
  if (result.empty()) {
    return false;
  }
  auto front_value_iter = result.begin();
  auto front_value = front_value_iter->c_str();
  auto reg_info = top_level_variables_.find(front_value);

  long reg = 0;
  if (reg_info == top_level_variables_.end()) {
    if (enable_top_var_strict_mode_) {
#ifdef LEPUS_LOG
      LOGE("lepus-updateTopLevelVariable: not find variables " << name);
#endif
      return false;
    } else {
      reg = top_level_variables_.size();
      top_level_variables_.insert(std::make_pair(front_value, reg));
    }
  } else {
    reg = reg_info->second;
  }
  result.erase(front_value_iter);
  Value* ptr = heap_.base() + reg + 1;
  if (!result.empty() && ((ptr->IsTable() && ptr->Table()->IsConst()) ||
                          (ptr->IsArray() && ptr->Array()->IsConst()))) {
    *(heap_.base() + reg + 1) = Value::Clone(*ptr);
  }
  lepus::Value::UpdateValueByPath(*ptr, value, result);
  return true;
}

bool VMContext::CheckTableShadowUpdatedWithTopLevelVariable(
    const lepus::Value& update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "VMContext::CheckTableShadowUpdatedWithTopLevelVariable");
  bool enable_deep_check = false;
#if ENABLE_INSPECTOR && LYNX_ENABLE_TRACING
  if (lynx::base::LynxEnv::GetInstance().IsTableDeepCheckEnabled()) {
    enable_deep_check = true;
  }
#endif
  auto update_type = update.Type();
  if (update_type != ValueType::Value_Table) {
    return true;
  }
  // page new data from setData
  auto update_table_value = update.Table();
  // shadow compare new_data_table && top level
  // if any top level data are different, need update;
  for (auto& update_data_iterator : *update_table_value) {
    auto key = update_data_iterator.first.str();
    auto result = ParseValuePath(key);
    if (result.empty()) {
      return true;
    }
    auto front_value_iter = result.begin();
    auto front_value = front_value_iter->c_str();
    auto reg_info = top_level_variables_.find(front_value);
    long reg = 0;
    if (reg_info == top_level_variables_.end()) {
      // target did not have this new key
      return true;
    } else {
      reg = reg_info->second;
    }
    result.erase(front_value_iter);
    Value* ptr = heap_.base() + reg + 1;

    for (auto it = begin(result); it != end(result); ++it) {
      if (ptr->IsTable()) {
        auto key = it->c_str();
        if (!ptr->Table()->Contains(key)) {
          // target table did not have this new key
          return true;
        }
        ptr = &(const_cast<Value&>(ptr->Table()->GetValue(key)));
      } else if (ptr->IsArray()) {
        int index;
        if (lynx::base::StringToInt(*it, &index, 10)) {
          if (static_cast<size_t>(index) >= ptr->Array()->size()) {
            // the array's size is smaller.
            return true;
          }
          ptr = &(const_cast<Value&>(ptr->Array()->get(index)));
        }
      }
    }

    lepus::Value update_item_value = update_data_iterator.second;
    if (!enable_deep_check &&
        tasm::CheckTableValueNotEqual(*ptr, update_item_value)) {
      return true;
    }
#if ENABLE_INSPECTOR && LYNX_ENABLE_TRACING
    if (enable_deep_check &&
        tasm::CheckTableDeepUpdated(*ptr, update_item_value, false)) {
      return true;
    }
#endif
  }
  return false;
}

void VMContext::ResetTopLevelVariable() {
  // `__globalProps` & `SystemInfo` are builtin variable, should not be cleared.
  // Reset should not clear callable value.
  for (const auto& iter : top_level_variables_) {
    if (lepus::BeginsWith(iter.first.str(), "$") ||
        iter.first.str() == "__globalProps" ||
        iter.first.str() == "SystemInfo") {
      continue;
    }

    long reg = iter.second;
    auto* value = heap_.base() + reg + 1;
    if (!value->IsCallable()) {
      value->SetNil();
    }
  }
}

void VMContext::ResetTopLevelVariableByVal(const Value& val) {
  if (val.IsTable()) {
    for (const auto& pair : *val.Table()) {
      // `__globalProps` & `SystemInfo` are builtin variable, should not be
      // cleared.
      if (pair.first.str() == "__globalProps" ||
          pair.first.str() == "SystemInfo") {
        continue;
      }
      auto reg_info = top_level_variables_.find(pair.first);
      if (reg_info == top_level_variables_.end()) {
        return;
      }
      long reg = reg_info->second;
      (*(heap_.base() + reg + 1)).SetNil();
    }
  }
}

std::unique_ptr<lepus::Value> VMContext::GetTopLevelVariable(
    bool ignore_callable) {
  auto dictionary = lepus::Dictionary::Create();
  for (auto it : top_level_variables_) {
    if (!lepus::BeginsWith(it.first.str(), "$")) {
      auto value = *(heap_.base() + it.second + 1);
      if (ignore_callable && value.IsCallable()) {
        continue;
      }
      dictionary->SetValue(it.first.c_str(), value);
    }
  }
  return std::make_unique<lepus::Value>(dictionary);
}

bool VMContext::GetTopLevelVariableByName(const std::string& name, Value* ret) {
  auto variable = top_level_variables_.find(name);
  if (variable != top_level_variables_.end()) {
    *ret = *(heap_.base() + variable->second + 1);
    return true;
  }
  return false;
}

bool VMContext::CallFunction(Value* function, size_t argc, Value* ret) {
  if (unlikely(function->IsClosure())) {
    heap_.top_ = function + 1;
    lynx::base::scoped_refptr<Function> lepus_function =
        function->GetClosure()->function();
    const Instruction* ins = lepus_function->GetOpCodes();
    Frame frame(heap_.top_, function, ret, ins,
                ins + lepus_function->OpCodeSize(), current_frame_, 0);
    if (GetInspector()) {
      frame.SetDebuggerFrameId(debugger_frame_id_++);
    }
    current_frame_ = &frame;
    RunFrame();
    // pop frame, reset register address
    heap_.top_ = frame.prev_frame_->register_;
    current_frame_ = frame.prev_frame_;
    return true;
  } else if (function->IsCFunction()) {
    heap_.top_ = function + argc + 1;
    Frame frame(function + 1, function, ret, nullptr, nullptr, current_frame_,
                0);
    if (GetInspector()) {
      frame.SetDebuggerFrameId(debugger_frame_id_++);
    }
    current_frame_ = &frame;
    CFunction cfunction = function->Function();
    *ret = cfunction(this);
    heap_.top_ = frame.prev_frame_->register_;
    current_frame_ = frame.prev_frame_;
    return true;
  } else {
    return false;
  }
}

// report red box, but the program continues running
void VMContext::ReportRedBox(const std::string& exception_info, int& pc) {
  std::vector<int> frame_pc_;
  Frame* exception_frame = current_frame_;
  this->exception_info_ = exception_info;
  exception_info_.erase(exception_info_.find_last_not_of('\n') + 1,
                        exception_info_.size());
  exception_info_ = exception_info_ + "\n\n";
  frame_pc_.push_back(pc - 1);
  Frame* current_frame = current_frame_;
  while (current_frame) {
    current_frame = current_frame->prev_frame_;
    if (current_frame == current_frame->prev_frame_) break;
    frame_pc_.push_back(current_frame->current_pc_ - 1);
  }
  exception_info_.erase(exception_info_.find_last_not_of('\n') + 1,
                        exception_info_.size());
  this->exception_info_ += (" function name backtrace:\n" +
                            BuildBackTrace(frame_pc_, exception_frame));
  exception_info_ = "lepus exception:\n\n" + exception_info_;
  LOGE("lepus-ReportException: exception happened without catch "
       << this->exception_info_);
  ReportError(exception_info_);
}

void VMContext::ReportException(
    const std::string& exception_info, int& pc, int& instruction_length,
    lynx::base::scoped_refptr<Closure>& current_frame_closure,
    lynx::base::scoped_refptr<Function>& current_frame_function,
    const Instruction*& current_frame_base, Value*& current_frame_regs,
    bool report_redbox) {
  std::vector<int> frame_pc_;
  Frame* exception_frame_ = current_frame_;
  bool find_caught_label = false;
  this->exception_info_ = exception_info;
  exception_info_.erase(exception_info_.find_last_not_of('\n') + 1,
                        exception_info_.size());
  exception_info_ = exception_info_ + "\n\n";
  frame_pc_.push_back(pc - 1);
  while (current_frame_) {
    Frame* current_frame = current_frame_;
    const Instruction* base = current_frame->instruction_;
    const Instruction* end = current_frame->end_;
    int length = static_cast<int>(end - base);
    int current_pc = current_frame->current_pc_;
    while (current_pc < length) {
      Instruction i = *(base + current_pc);
      current_pc++;
      current_frame->current_pc_ = current_pc;
      if (Instruction::GetOpCode(i) == TypeLabel_Catch) {
        pc = current_pc;
        find_caught_label = true;
        this->exception_info_ += (" function name backtrace:\n" +
                                  BuildBackTrace(frame_pc_, exception_frame_));
        instruction_length = static_cast<int>(current_frame_->end_ -
                                              current_frame_->instruction_);
        if (current_frame_->function_) {
          current_frame_closure = current_frame_->function_->GetClosure();
          current_frame_function = current_frame_closure->function();
        }
        current_frame_base = current_frame_->instruction_;
        current_frame_regs = current_frame_->register_;
        break;
      }
    }

    if (current_frame_ == current_frame_->prev_frame_ || find_caught_label) {
      break;
    }
    heap_.top_ = current_frame_->prev_frame_->register_;
    current_frame_ = current_frame_->prev_frame_;
    if (current_frame_ == current_frame_->prev_frame_) break;
    frame_pc_.push_back(current_frame_->current_pc_ - 1);
  }

  if (!find_caught_label) {
    instruction_length =
        static_cast<int>(current_frame_->end_ - current_frame_->instruction_);
    current_frame_base = current_frame_->instruction_;
    current_frame_regs = current_frame_->register_;
    if (current_frame_->function_) {
      current_frame_closure = current_frame_->function_->GetClosure();
      current_frame_function = current_frame_closure->function();
    }
    exception_info_.erase(exception_info_.find_last_not_of('\n') + 1,
                          exception_info_.size());
    this->exception_info_ += (" function name backtrace:\n" +
                              BuildBackTrace(frame_pc_, exception_frame_));
    exception_info_ = "lepus exception:\n\n" + exception_info_;
    LOGE("lepus-ReportException: exception happened without catch "
         << this->exception_info_);
    if (report_redbox) {
      ReportError(exception_info_);
    }
    return;
  } else {
    LOGE("lepus-CatchException: " << this->exception_info_);
  }
}

tasm::TemplateAssembler* VMContext::GetTasmPointer() {
  if (tasm_pointer_ != nullptr) {
    return tasm_pointer_;
  }
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  Value* tasm_point = SearchGlobalData("$kTemplateAssembler");
  if (tasm_point) {
    tasm_pointer_ =
        reinterpret_cast<tasm::TemplateAssembler*>(tasm_point->CPoint());
    return tasm_pointer_;
  }
#endif
#endif
  LOGE("Not Found TemplateAssembler Instance");
  return nullptr;
}

std::string VMContext::BuildBackTrace(std::vector<int> pc,
                                      Frame* exception_frame_) {
  Frame* current_frame = exception_frame_;
  std::string backtrace_info;
  size_t index = 0;
  while (current_frame) {
    int current_pc = index > pc.size() ? -1 : pc[index++];
    lynx::base::scoped_refptr<Closure> current_closure =
        current_frame->function_->GetClosure();
    lynx::base::scoped_refptr<Function> current_function =
        current_closure->function();
    if (!current_function.Get()) break;

    // if there is no template_debug.json, send line + col
    // else send function id + pc index + template_debug.json url
    if (template_debug_url_ == "") {
      // line + col
      int32_t line = -1;
      int32_t col = -1;
      current_function->GetLineCol(current_pc, line, col);
      backtrace_info += ("\tat " + current_function->GetFunctionName() + " :" +
                         to_string(line) + ":" + to_string(col));

    } else {
      // function id + pc_index
      backtrace_info += ("\tat " + current_function->GetFunctionName() + ":" +
                         to_string(current_function->GetFunctionId()) + ":" +
                         to_string(current_pc));
    }
    current_frame = current_frame->prev_frame_;
    if (current_frame == current_frame->prev_frame_) {
      break;
    } else {
      backtrace_info += "\n";
    }
  }

  if (template_debug_url_ != "") {
    // add template_debug.json url to backtrace info
    backtrace_info += "\ntemplate_debug_url:" + template_debug_url_;
  }

  return backtrace_info;
}

void VMContext::RunFrame() {
  if (current_frame_ == nullptr) return;
  lynx::base::scoped_refptr<Closure> closure =
      current_frame_->function_->GetClosure();
  lynx::base::scoped_refptr<Function> function = closure->function();
  Value* a = nullptr;
  Value* b = nullptr;
  Value* c = nullptr;
  const Instruction* base = current_frame_->instruction_;
  Value* regs = current_frame_->register_;
  int length =
      static_cast<int>(current_frame_->end_ - current_frame_->instruction_);
  int pc = 0;
  long reg_b = 0;
  VMContext::ContextScope vcs(this, closure);
  while (pc < length) {
    if (debugger_base_) {
      ProcessDebuggerMessages(pc);
    }
    Instruction i = *(base + pc);
    pc++;
    switch (Instruction::GetOpCode(i)) {
      // LoadNil use reg_b to decide actions:
      // 0: load nil
      // 1: load undefined when enable_null_prop_ad_undef_ is true
      // 2: load top level variables in globalThis
      // 3: load "lynx" in global_ as lynx
      case TypeOp_LoadNil:
        a = GET_REGISTER_A(i);
        reg_b = Instruction::GetParamB(i);
        if (enable_null_prop_as_undef_ && reg_b == 1) {
          a->SetUndefined();
        } else if (reg_b == 2) {
          *a = *GetTopLevelVariable();
        } else if (reg_b == 3) {
          // Now, only generate reg_b==3 when targetSdkVersion >= 2.8. Detail
          // can be seen in code_generator.cc. So the possible scenarios are as
          // follows
          // clang-format off
          // sdkVersion    targetSdkVersion    expectations
          //  < 2.8         < 2.8             will not generate reg_b==3, no bugs
          //  < 2.8         >= 2.8            will report error since targetSdkVersion > sdkVersion, no bugs
          //  >= 2.8        < 2.8             will not generate reg_b==3, no bugs
          //  >= 2.8        >= 2.8            will generate reg_b==3, and sdk >= 2.8 can handle this, no bugs.
          // clang-format on
          constexpr const static char* kGlobalLynx = "lynx";
          auto* ptr = SearchGlobalData(kGlobalLynx);
          if (ptr == nullptr) {
            *a = lepus::Value();
          } else {
            *a = *ptr;
          }
        } else {
          a->SetNil();
        }
        break;
      case TypeOp_SetCatchId:
        a = GET_REGISTER_A(i);
        a->SetString(StringImpl::Create(exception_info_));
        exception_info_ = "";
        break;
      case TypeOp_LoadConst:
        a = GET_REGISTER_A(i);
        b = GET_CONST_VALUE(i);
        *a = *b;
        break;
      case TypeOp_Move:
        a = GET_REGISTER_A(i);
        b = GET_REGISTER_B(i);
        *a = *b;
        break;
      case TypeOp_GetContextSlot: {
        a = GET_REGISTER_A(i);
        long index = Instruction::GetParamB(i);
        long offset = Instruction::GetParamC(i);
        Value array = closure->GetContext();
        while (offset > 0) {
          array = array.Array()->get(0);
          offset--;
        }
        *a = array.Array()->get(index);
        break;
      }
      case TypeOp_SetContextSlot: {
        a = GET_REGISTER_A(i);
        long index = Instruction::GetParamB(i);
        long offset = Instruction::GetParamC(i);
        Value array = closure->GetContext();
        while (offset > 0) {
          array = array.Array()->get(0);
          offset--;
        }
        array.Array()->set(static_cast<int>(index), *a);
        break;
      }
      case TypeOp_GetUpvalue: {
        a = GET_REGISTER_A(i);
        b = GET_UPVALUE_B(i);
        *a = *b;
        break;
      }
      case TypeOp_SetUpvalue: {
        a = GET_REGISTER_A(i);
        b = GET_UPVALUE_B(i);
        *b = *a;
        break;
      }
      case TypeOp_GetGlobal:
        a = GET_REGISTER_A(i);
        b = GET_Global_VALUE(i);
        *a = *b;
        break;
      case TypeOp_SetGlobal:
        break;
      case TypeOp_GetBuiltin:
        a = GET_REGISTER_A(i);
        b = GET_Builtin_VALUE(i);
        *a = *b;
        break;
      case TypeOp_Closure: {
        a = GET_REGISTER_A(i);
        long index = Instruction::GetParamBx(i);
        GenerateClosure(a, index);
      } break;
      case TypeOp_Call: {
        a = GET_REGISTER_A(i);
        long argc = Instruction::GetParamB(i);
        c = GET_REGISTER_C(i);
        current_frame_->current_pc_ = pc;
        if (likely(a->IsClosure())) {
          auto lepus_function = a->GetClosure()->function();
          int32_t params_size = lepus_function->GetParamsSize();
          if (params_size > static_cast<int32_t>(argc)) {
            auto closure = a->GetClosure();
            ReportRedBox("Do not support default function params on function " +
                             lepus_function->GetFunctionName() + ".",
                         pc);
          }
        }
        bool result = CallFunction(a, argc, c);
        if (!result) {
          ReportException(to_string(TYPEERROR) + ", not a function.", pc,
                          length, closure, function, base, regs, true);
        } else if (pc < current_frame_->current_pc_) {
          pc = length;
        }
        break;
      }
      case TypeOp_Ret:
        a = GET_REGISTER_A(i);
        if (current_frame_->return_ != nullptr) {
          *current_frame_->return_ = *a;
        }
        return;
      case TypeOp_JmpFalse:
        a = GET_REGISTER_A(i);
        if (a->IsFalse()) pc += -1 + Instruction::GetParamsBx(i);
        break;
      case TypeOp_JmpTrue:
        a = GET_REGISTER_A(i);
        if (a->IsTrue()) pc += -1 + Instruction::GetParamsBx(i);
        break;
      case TypeOp_Jmp:
        pc += -1 + Instruction::GetParamsBx(i);
        break;
      case TypeLabel_Catch:
        break;
      case TypeLabel_Throw: {
        a = GET_REGISTER_A(i);
        std::ostringstream msg;
        msg << a;
        ReportException(msg.str(), pc, length, closure, function, base, regs,
                        false);
        break;
      }
      case TypeOp_SetContextSlotMove: {
        a = GET_REGISTER_A(i);
        long array_index = Instruction::GetParamB(i);
        c = GET_REGISTER_C(i);
        a->Array()->set(static_cast<int>(array_index), *c);
        break;
      }
      case TypeOp_GetContextSlotMove: {
        a = GET_REGISTER_A(i);
        long array_index = Instruction::GetParamB(i);
        c = GET_REGISTER_C(i);
        *a = c->Array()->get(array_index);
        break;
      }
      case TypeOp_Typeof:
        a = GET_REGISTER_A(i);
        switch (a->Type()) {
          case lepus::ValueType::Value_Undefined:
            a->SetString(lepus::StringImpl::Create("undefined"));
            break;
          case lepus::ValueType::Value_Nil:
          case lepus::ValueType::Value_Table:
          case lepus::ValueType::Value_Array:
            a->SetString(lepus::StringImpl::Create("object"));
            break;
          case lepus::ValueType::Value_Bool:
            a->SetString(lepus::StringImpl::Create("boolean"));
            break;
          case lepus::ValueType::Value_Double:
          case lepus::ValueType::Value_Int32:
          case lepus::ValueType::Value_Int64:
          case lepus::ValueType::Value_UInt32:
          case lepus::ValueType::Value_UInt64:
            a->SetString(lepus::StringImpl::Create("number"));
            break;
          case lepus::ValueType::Value_String:
            a->SetString(lepus::StringImpl::Create("string"));
            break;
          case lepus::ValueType::Value_Closure:
          case lepus::ValueType::Value_CFunction:
            a->SetString(lepus::StringImpl::Create("function"));
            break;
          case lepus::ValueType::Value_JSObject:
            a->SetString(lepus::StringImpl::Create("lepusobject"));
            break;
          default:
            a->SetString(lepus::StringImpl::Create("object"));
            break;
        }
        break;
      case TypeOp_Neg:
        a = GET_REGISTER_A(i);
        if (a->IsInt64()) {
          a->SetNumber(-a->Int64());
        } else if (a->IsNumber()) {
          a->SetNumber(-a->Number());
        } else if (a->IsString()) {
          char* endptr;
          double t = strtod(a->String()->str().c_str(), &endptr);
          if (*endptr) {
            a->SetNan(true);
          } else {
            if (t != static_cast<int64_t>(t)) {
              Value number(t);
              a->SetNumber(-number.Number());
            } else {
              Value number(static_cast<int64_t>(t));
              a->SetNumber(-number.Int64());
            }
          }
        }
        break;
      case TypeOp_Pos:
        a = GET_REGISTER_A(i);
        if (a->IsString()) {
          char* endptr;
          double t = strtod(a->String()->str().c_str(), &endptr);
          if (*endptr) {
            a->SetNan(true);
          } else {
            if (t != static_cast<int64_t>(t)) {
              Value number(t);
              a->SetNumber(number.Number());
            } else {
              Value number(static_cast<int64_t>(t));
              a->SetNumber(number.Int64());
            }
          }
        }
        break;
      case TypeOp_Not:
        a = GET_REGISTER_A(i);
        a->SetBool(!a->Bool());
        break;
      case TypeOp_BitNot:
        a = GET_REGISTER_A(i);
        if (a->IsNumber()) {
          if (a->IsInt64())
            a->SetNumber(~(a->Int64()));
          else {
            int64_t x = static_cast<int64_t>(a->Number()) & 0xffffffff;
            a->SetNumber(~x);
          }
        }
        break;
      case TypeOp_And:
        //&&
        GET_REGISTER_ABC(i);
        if (b->IsTrue()) {
          *a = *c;
        } else {
          *a = *b;
        }
        break;
      case TypeOp_Or:
        //||
        GET_REGISTER_ABC(i);
        if (!b->IsFalse()) {
          *a = *b;
        } else {
          *a = *c;
        }
        break;
      case TypeOp_Len:
        break;
      case TypeOp_Add:
        GET_REGISTER_ABC(i);
        // most cases are string + string
        // some cases are int + string
        // we just optimized those two case
        if (b->IsString() && c->IsString()) {
          std::string sum = b->String()->str() + c->String()->str();
          a->SetString(lynx::lepus::StringImpl::Create(sum));
          break;
        }

        if (b->IsNumber() && c->IsNumber()) {
          if (b->IsInt64() && c->IsInt64()) {
            a->SetNumber(b->Int64() + c->Int64());
          } else {
            a->SetNumber(b->Number() + c->Number());
          }
          break;
        }

        if (b->IsNumber()) {
          std::vector<char> buffer(100);
          const char* num_str;
          if ((num_str =
                   StringConvertHelper::NumberToString(b->Number(), buffer))) {
            // processed as int
            std::string b_str(num_str);
            std::string sum = b_str + c->String()->str();
            a->SetString(lynx::lepus::StringImpl::Create(sum));
          } else {
            std::ostringstream stm;
            if (b->IsInt64()) {
              stm << b->Int64();
            } else {
              stm << StringConvertHelper::DoubleToString(b->Number());
            }
            stm << c->String()->str();
            a->SetString(lynx::lepus::StringImpl::Create(stm.str()));
          }
        } else if (c->IsNumber()) {
          std::vector<char> buffer(100);
          const char* num_str;
          if ((num_str =
                   StringConvertHelper::NumberToString(c->Number(), buffer))) {
            // processed as int
            std::string c_str(num_str);
            std::string sum = b->String()->str() + c_str;
            a->SetString(lynx::lepus::StringImpl::Create(sum));
          } else {
            std::ostringstream stm;
            stm << b->String()->str();
            if (c->IsInt64()) {
              stm << c->Int64();
            } else {
              stm << StringConvertHelper::DoubleToString(c->Number());
            }
            a->SetString(lynx::lepus::StringImpl::Create(stm.str()));
          }
        } else {
          // may string + null or null + string
          std::string sum = b->String()->str() + c->String()->str();
          a->SetString(lynx::lepus::StringImpl::Create(sum));
        }
        break;
      case TypeOp_Sub:
        GET_REGISTER_ABC(i);
        if (b->IsInt64() && c->IsInt64()) {
          a->SetNumber(b->Int64() - c->Int64());
        } else {
          a->SetNumber(b->Number() - c->Number());
        }
        break;
      case TypeOp_Mul:
        GET_REGISTER_ABC(i);
        if (b->IsInt64() && c->IsInt64()) {
          a->SetNumber(b->Int64() * c->Int64());
        } else {
          a->SetNumber(b->Number() * c->Number());
        }
        break;
      case TypeOp_Div: {
        GET_REGISTER_ABC(i);
        if (c->Number() == 0) {
          *a = Value();
          LOGE("lepus-div: div 0");
          break;
        }
        double ans = b->Number() / c->Number();
        if (lynx::lepus::StringConvertHelper::IsInt64Double(ans)) {
          a->SetNumber(static_cast<int64_t>(ans));
        } else {
          a->SetNumber(ans);
        }
        break;
      }
      case TypeOp_Pow:
        GET_REGISTER_ABC(i);
        if (b->IsInt64() && c->IsInt64())
          a->SetNumber(static_cast<int64_t>(pow(b->Int64(), c->Int64())));
        else if (b->IsNumber() && c->IsNumber())
          a->SetNumber(pow(b->Number(), c->Number()));
        break;
      case TypeOp_Mod: {
        GET_REGISTER_ABC(i);
        if (c->Number() == 0) {
          *a = Value();
          LOGE("lepus-mode: div 0");
          break;
        }
        Value b_tmp = *b;
        Value c_tmp = *c;
        if (b->IsInt64() && c->IsInt64()) {
          a->SetNumber(b->Int64() / c->Int64());
          a->SetNumber(b_tmp.Int64() - a->Int64() * c_tmp.Int64());
        } else {
          a->SetNumber(int(b->Number() / c->Number()));
          a->SetNumber(b_tmp.Number() - a->Number() * c_tmp.Number());
        }
        break;
      }
      case TypeOp_BitOr:
        GET_REGISTER_ABC(i);
        if (b->IsNumber() && c->IsNumber()) {
          if (b->IsInt64() && c->IsInt64()) {
            a->SetNumber(b->Int64() | c->Int64());
          } else {
            int64_t x = static_cast<int64_t>(b->Number()) & 0xffffffff;
            int64_t y = static_cast<int64_t>(c->Number()) & 0xffffffff;
            a->SetNumber(x | y);
          }
        }
        break;

      case TypeOp_BitAnd:
        GET_REGISTER_ABC(i);
        if (b->IsNumber() && c->IsNumber()) {
          if (b->IsInt64() && c->IsInt64()) {
            a->SetNumber(b->Int64() & c->Int64());
          } else {
            int64_t x = static_cast<int64_t>(b->Number()) & 0xffffffff;
            int64_t y = static_cast<int64_t>(c->Number()) & 0xffffffff;
            a->SetNumber(x & y);
          }
        }
        break;
      case TypeOp_BitXor:
        GET_REGISTER_ABC(i);
        if (b->IsNumber() && c->IsNumber()) {
          if (b->IsInt64() && c->IsInt64()) {
            a->SetNumber(b->Int64() ^ c->Int64());
          } else {
            int64_t x = static_cast<int64_t>(b->Number()) & 0xffffffff;
            int64_t y = static_cast<int64_t>(c->Number()) & 0xffffffff;
            a->SetNumber(x ^ y);
          }
        }
        break;
      case TypeOp_Less:
        GET_REGISTER_ABC(i);
        a->SetBool(false);
        if (b->IsNumber() && c->IsNumber()) {
          a->SetBool(b->Number() < c->Number());
        } else if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() < c->String()->str();
          a->SetBool(result);
        }
        break;
      case TypeOp_Greater:
        GET_REGISTER_ABC(i);
        a->SetBool(false);
        if (b->IsNumber() && c->IsNumber())
          a->SetBool(b->Number() > c->Number());
        else if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() > c->String()->str();
          a->SetBool(result);
        }
        break;
      case TypeOp_Equal:
        GET_REGISTER_ABC(i);
        if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() == c->String()->str();
          a->SetBool(result);
        } else {
          a->SetBool(*b == *c);
        }

        break;
      case TypeOp_AbsEqual:
        GET_REGISTER_ABC(i);
        if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() == c->String()->str();
          a->SetBool(result);
        } else {
          a->SetBool(*b == *c);
        }

        break;
      case TypeOp_UnEqual:
        GET_REGISTER_ABC(i);
        a->SetBool(*b != *c);
        break;
      case TypeOp_AbsUnEqual:
        GET_REGISTER_ABC(i);
        a->SetBool(*b != *c);
        break;
      case TypeOp_LessEqual:
        GET_REGISTER_ABC(i);
        a->SetBool(false);
        if (b->IsNumber() && c->IsNumber()) {
          a->SetBool((b->Number() <= c->Number()));
        } else if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() <= c->String()->str();
          a->SetBool(result);
        }
        break;
      case TypeOp_GreaterEqual:
        GET_REGISTER_ABC(i);
        a->SetBool(false);
        if (b->IsNumber() && c->IsNumber()) {
          a->SetBool((b->Number() >= c->Number()));
        } else if (b->IsString() && c->IsString()) {
          bool result;
          result = b->String()->str() >= c->String()->str();
          a->SetBool(result);
        }
        break;
      case TypeOp_NewArray: {
        a = GET_REGISTER_A(i);
        long argc = Instruction::GetParamB(i);
        *a = Value(CArray::Create());
        for (int i = 0; i < argc; ++i) {
          a->Array()->push_back(*(a + i + 1));
        }
      } break;
      case TypeOp_CreateContext: {
        a = GET_REGISTER_A(i);
        // context + data
        long array_size = Instruction::GetParamB(i) + 1;
        *a = Value(CArray::Create());
        a->Array()->resize(array_size);
        Frame* frame = current_frame_;
        lynx::base::scoped_refptr<Closure> current_closure =
            frame->function_->GetClosure();
        Value pre_context = current_closure->GetContext();
        a->Array()->set(0, pre_context);
        closure_context_ = *a;
      } break;
      case TypeOp_PushContext: {
        a = GET_REGISTER_A(i);
        context_.push(*a);
        break;
      }
      case TypeOp_PopContext: {
        context_.pop();
        break;
      }
      case TypeOp_NewTable:
        a = GET_REGISTER_A(i);
        a->SetTable(Dictionary::Create());
        break;
      case TypeOp_SetTable:
        GET_REGISTER_ABC(i);
        if (a->IsTable() && b->IsString()) {
          a->Table()->SetValue(b->String(), *c);
        } else if (a->IsArray() && b->IsNumber()) {
          a->Array()->set(static_cast<int>(b->Number()), *c);
        } else if (a->IsTable() && b->IsNumber()) {
          std::ostringstream s;
          s << b->Number();
          a->Table()->SetValue(s.str(), *c);
        }
        break;
      case TypeOp_GetTable:
        GET_REGISTER_ABC(i);
        a->SetNil();

        if (b->IsNil() || b->IsUndefined()) {
          if (enable_strict_check_) {
            std::string key = "";
            if (c->IsString()) {
              key = c->String()->str();
            }
            ReportException("Cannot read " + key + " of null ", pc, length,
                            closure, function, base, regs,
                            enable_strict_check_);
            break;
          } else {
#ifdef LEPUS_LOG
            if (c->IsString()) {
              LOGE("lepus: Cannot read property " << c->String()->c_str()
                                                  << " of undefined.");
            } else if (c->IsNumber()) {
              LOGE("lepus: Cannot read property " << c->Number()
                                                  << " of undefined.");
            } else {
              LOGE("lepus: Cannot read property of undefined");
            }
#endif
          }
          enable_null_prop_as_undef_ ? a->SetUndefined() : a->SetNil();
          break;
        }
        switch (b->Type()) {
          case Value_Table:
            if (c->IsString()) {
              *a =
                  b->Table()->GetValue(c->String(), enable_null_prop_as_undef_);
            } else if (c->IsNumber()) {
              std::ostringstream s;
              s << c->Number();
              *a = b->Table()->GetValue(s.str(), enable_null_prop_as_undef_);
            } else {
              a->SetNil();
            }
            break;
          case Value_Array:
            if (c->IsNumber()) {
              *a = b->Array()->get(c->Number());
            } else if (c->IsString()) {
              Value& array_prototype = array_prototype_;
              if (unlikely(!array_prototype.IsTable())) {
                *a = Value();
              } else {
                if (!strcmp(c->String()->c_str(), "length")) {
                  *a = Value(static_cast<int64_t>((b->Array()->size())));
                } else if (b->Array()->GetIsMatchResult()) {
                  if (!strcmp(c->String()->c_str(), "input")) {
                    *a = b->Array()->GetMatchInput();
                  } else if (!strcmp(c->String()->c_str(), "index")) {
                    *a = b->Array()->GetMatchIndex();
                  } else if (!strcmp(c->String()->c_str(), "groups")) {
                    *a = b->Array()->GetMatchGroups();
                  }
                } else {
                  *a = array_prototype.Table()->GetValue(c->String());
                }
              }
            } else {
#ifdef LEPUS_LOG
              LOGE("lepus: GetTable for Array, key error is " << c->Type());
#endif
              *a = Value();
            }
            break;
          case Value_String:
            if (c->IsString()) {
              Value& string_prototype = string_prototype_;
              if (unlikely(!string_prototype.IsTable())) {
                *a = Value();
              } else {
                if (!strcmp(c->String()->c_str(), "length")) {
                  *a = Value(static_cast<int64_t>((b->String()->size_utf16())));
                } else {
                  *a = string_prototype.Table()->GetValue(c->String());
                }
              }
            } else if (c->IsNumber()) {
              int index = c->Number();
              DCHECK(index >= 0);
              if (static_cast<size_t>(index) >= b->String()->size_utf16()) {
                *a = Value(StringImpl::Create("", 0));
              } else {
                auto c_offset = Utf8IndexToCIndexForUtf16(
                    b->String()->c_str(), b->String()->length(), index);
                auto result_begin = b->String()->c_str() + c_offset;
                auto result_len =
                    *result_begin != 0
                        ? (InlineUTF8SequenceLength(*result_begin))
                        : 0;
                *a = Value(StringImpl::Create(result_begin, result_len));
              }
            } else {
#ifdef LEPUS_LOG
              LOGE("lepus: GetTable for String, key error is " << c->Type());
#endif
              *a = Value();
            }
            break;
          case Value_CDate:
            if (c->IsString()) {
              Value& date_prototype = date_prototype_;
              if (!unlikely(!date_prototype.IsTable())) {
                *a = date_prototype.Table()->GetValue(c->String());
              } else {
                *a = Value();
              }
            } else {
              *a = Value();
            }
            break;
          case Value_RegExp:
            if (c->IsString()) {
              Value& regexp_prototype = regexp_prototype_;
              if (unlikely(!regexp_prototype.IsTable())) {
                *a = Value();
              } else {
                *a = regexp_prototype.Table()->GetValue(c->String());
              }
            } else {
              *a = Value();
            }
            break;
          default:
            if (b->IsNumber() && c->IsString()) {
              *a = number_prototype_.Table()->GetValue(c->String());
            } else {
#ifdef LEPUS_LOG
              LOGE("lepus: GetTable unknown, receiver type  "
                   << b->Type() << ", key type " << c->Type());
#endif
              *a = Value();
            }
            break;
        }
        break;
      case TypeOp_Switch: {
        a = GET_REGISTER_A(i);
        long index = Instruction::GetParamBx(i);
        long jmp = function->GetSwitch(index)->Switch(a);
        pc += -1 + jmp;
      } break;
      case TypeOp_Inc:
        a = GET_REGISTER_A(i);
        if (a->IsNumber()) {
          if (a->IsInt64()) {
            a->SetNumber(a->Int64() + 1);
          } else {
            a->SetNumber(a->Number() + 1);
          }
        }
        break;
      case TypeOp_Dec:
        a = GET_REGISTER_A(i);
        if (a->IsNumber()) {
          if (a->IsInt64()) {
            a->SetNumber(a->Int64() - 1);
          } else {
            a->SetNumber(a->Number() - 1);
          }
        }
        break;
      case TypeOp_Noop:
        break;
      case TypeLabel_EnterBlock: {
        closure->SetContext(closure_context_);
        if (!closure_context_.IsNil()) {
          closures_.AddClosure(closure, executed_);
        }
        block_context_.push(PrepareClosureContext(closure));
        break;
      }
      case TypeLabel_LeaveBlock: {
        Value current_context = closure_context_;
        long array_size = current_context.Array()->size();
        closure_context_ = block_context_.top();
        for (auto i = 1; i < array_size; i++) {
          closure_context_.SetProperty(i, current_context.GetProperty(i));
        }
        block_context_.pop();
        break;
      }
      case TypeOp_CreateBlockContext: {
        a = GET_REGISTER_A(i);
        long array_size = Instruction::GetParamB(i) + 1;
        *a = Value(CArray::Create());
        a->Array()->resize(array_size);
        auto current_closure = current_frame_->function_->GetClosure();
        Value pre_context = current_closure->GetContext();

        a->SetProperty(0, pre_context);
        for (auto i = 1; i < array_size; i++) {
          a->SetProperty(i, pre_context.GetProperty(i));
        }
        closure_context_ = *a;
        break;
      }
      default:
        break;
    }
  }
  if (current_frame_->return_ != nullptr) {
    current_frame_->return_->SetNil();
  }
}

void VMContext::GenerateClosure(Value* value, long index) {
  Frame* frame = current_frame_;
  lynx::base::scoped_refptr<Closure> current_closure =
      frame->function_->GetClosure();
  lynx::base::scoped_refptr<Function> function =
      current_closure->function()->GetChildFunction(index);

  lynx::base::scoped_refptr<Closure> closure = Closure::Create(function);

  std::size_t upvalues_count = function->UpvaluesSize();
  for (int i = 0; static_cast<size_t>(i) < upvalues_count; ++i) {
    UpvalueInfo* info = function->GetUpvalue(i);
    if (info->in_parent_vars_) {
      Value* v = frame->register_ + info->register_;
      closure->AddUpvalue(v);
    } else {
      closure->AddUpvalue(current_closure->GetUpvalue(info->register_));
    }
  }
  closure->SetContext(closure_context_);
  value->SetClosure(closure);

  if (!closure_context_.IsNil()) {
    closures_.AddClosure(closure, executed_);
  }
}

lynx::base::scoped_refptr<Function> VMContext::GetRootFunction() {
  return root_function_.Get();
}

void VMContext::DebugDataInitialize() {
  debugger_frame_id_ = 0;
  debugger_base_ = nullptr;
  inspector_ = nullptr;
}

void VMContext::ProcessDebuggerMessages(int32_t current_pc) {
  debugger_base_->SetVMContext(this);
  debugger_base_->ProcessDebuggerMessages(current_pc);
}

void VMContext::DebuggerInitializer() {
  if (debugger_base_) {
    debugger_base_->GetAllFunctions(root_function_.Get());
    debugger_base_->SetVMContext(this);
    // get debuginfo we needed from template_debug.json
    debugger_base_->PrepareDebugInfo();

    if (debugger_base_->IsFuncsEmpty())
      debugger_base_->GetAllFunctions(root_function_.Get());
    debugger_base_->SendMessagesToDebugger("");
  }
}

void VMContext::ProcessPausedMessages(lepus::Context* context,
                                      const std::string& message) {
  if (debugger_base_) {
    debugger_base_->SetVMContext(this);
    debugger_base_->ProcessPausedMessages(context, message);
  }
}

// devtool: create debugger
void VMContext::SetDebugger(std::shared_ptr<DebuggerBase> debugger) {
  debugger_base_ = debugger;
}

std::shared_ptr<DebuggerBase> VMContext::GetDebugger() {
  return debugger_base_;
}

void VMContext::SetInspector(lepus_inspector::LepusInspector* inspector) {
  inspector_ = inspector;
}

void VMContext::SetSession(lepus_inspector::LepusInspectorSession* session) {
  session_ = session;
}

lepus_inspector::LepusInspectorSession* VMContext::GetSession() {
  return session_;
}

lepus_inspector::LepusInspector* VMContext::GetInspector() {
  return inspector_;
}

Frame* VMContext::GetCurrentFrame() { return current_frame_; }

/**
 * @brief Iterate through the array and delete elements with a reference count
 * of 1
 * For saving reverse the array's time, lepus processes up to one hundred
 * elements at a time, and the remaining elements are processed in the next
 * round.
 */
void VMContext::ClosureManager::ClearClosure() {
  int64_t i = 0;
  int64_t step = all_closures_after_executed_.size() > 100
                     ? 100
                     : all_closures_after_executed_.size();
  while (i++ < step) {
    if (itr_ < all_closures_after_executed_.size()) {
      if (all_closures_after_executed_[itr_]->HasOneRef()) {
        all_closures_after_executed_.erase(
            all_closures_after_executed_.begin() + itr_);
      }
      itr_++;
    } else {
      itr_ = 0;
    }
  }
}

void VMContext::ClosureManager::AddClosure(
    base::scoped_refptr<lepus::Closure>& closure, bool context_executed) {
  ClearClosure();
  if (context_executed) {
    all_closures_after_executed_.push_back(closure);
  } else {
    all_closures_before_executed_.push_back(closure);
  }
}

void VMContext::ClosureManager::CleanUpClosuresCreatedAfterExecuted() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CleanUpClosuresCreatedAfterExecuted");
  for (auto& itr : all_closures_after_executed_) {
    itr->SetContext(Value());
  }
  all_closures_after_executed_.clear();
  itr_ = 0;
}

void VMContext::SetGlobalData(const String& name, const Value& value) {
  global_.Add(name, value);
}

VMContext::ClosureManager::~ClosureManager() {
  CleanUpClosuresCreatedAfterExecuted();
  for (auto& itr : all_closures_before_executed_) {
    itr->SetContext(Value());
  }
  itr_ = 0;
}

void VMContext::RegisterLepusVerion() {
  builtin_.Set("__lepus_version__",
               Value(StringImpl::Create(LYNX_LEPUS_VERSION)));
}

void VMContext::CleanClosuresInCycleReference() {
  closures_.CleanUpClosuresCreatedAfterExecuted();
}

}  // namespace lepus
}  // namespace lynx
