// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus_debugger.h"

#include <utility>

#include "jsbridge/js_debug/lepus/lepus_debugger_tools.h"
#include "jsbridge/js_debug/lepus/lepus_inspector_session_impl.h"
#include "lepus/vm_context.h"

#define GET_PROTOCOL (curr_event.GetData()->GetProtocol())
#define EVENT_ID curr_event.GetEventId()
#define RESPOND_DEFAULT_MESSAGE(PROTOCOL)                  \
  do {                                                     \
    auto *protocol = static_cast<PROTOCOL *> GET_PROTOCOL; \
    std::shared_ptr<rapidjson::Document> result_sp;        \
    protocol->GetRetDom(result_sp);                        \
    SendProtocolMessages(result_sp, EVENT_ID);             \
  } while (0)

namespace lynx {
namespace lepus {

Debugger::Debugger()
    : is_enabled_(false),
      state_(eStateInvalid),
      step_mode_(DebuggerStep(0, -1, -1, -1)),
      debug_info_("") {
  tools_ = new DebugTool();
  breakpoint_ = new Breakpoint();
}

Debugger::~Debugger() {
  delete tools_;
  delete breakpoint_;
  tools_ = nullptr;
  breakpoint_ = nullptr;
}

// when runnig, call this function to get protocol message send from frontend
void Debugger::ProcessDebuggerMessages(int32_t current_pc) {
  lynx::base::scoped_refptr<Function> function = GetCurrentFunction();
  SetCurrentPC(function.Get(), current_pc);
  // get the message queue
  if (context_->GetInspector() &&
      static_cast<lepus_inspector::LepusInspectorImpl *>(
          context_->GetInspector())
          ->Client()) {
    std::queue<std::string> message_queue =
        static_cast<lepus_inspector::LepusInspectorImpl *>(
            context_->GetInspector())
            ->Client()
            ->getMessageFromFrontend();
    while (!message_queue.empty()) {
      UpdateDebugger(message_queue.front());
      message_queue.pop();
    }
    SendMessagesToDebugger("");
  }
}

// when pause, call this function to send protocol message to debugger
void Debugger::ProcessPausedMessages(lepus::Context *context,
                                     const std::string &message) {
  if (IsFuncsEmpty() && context_->GetRootFunction()) {
    GetAllFunctions(context_->GetRootFunction().Get());
  }
  SendMessagesToDebugger(message);
}

// construct response message
void Debugger::SendProtocolMessages(std::shared_ptr<rapidjson::Document> &dom,
                                    int32_t event_id,
                                    const std::string &method) {
  std::string return_message;
  if (!method.empty()) {
    // debugger event
    // method: xxx, params: xxx
    return_message = ConstructReturnMessage(dom, event_id, method);
    SendNotificationMessage(return_message);
  } else {
    // id: xxx, result: xxx
    return_message = ConstructReturnMessage(dom, event_id, "");
    SendResponseMessage(event_id, return_message);
  }
}

void Debugger::Paused() {
  // Debugger.paused event
  // ref:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
  Value callframes = tools_->GetCallFrames(context_, curr_pc_info_.second);
  debugProtocols::Paused result(callframes, "other");
  auto result_sp = result.GetDom();
  SendProtocolMessages(result_sp, -1, "Debugger.paused");

  if (context_->GetInspector() &&
      static_cast<lepus_inspector::LepusInspectorImpl *>(
          context_->GetInspector())
          ->Client()) {
    // the param of runMessageLoopOnPause is only used in js thread quickjs
    // debugger, pass empty string in other situations
    static_cast<lepus_inspector::LepusInspectorImpl *>(context_->GetInspector())
        ->Client()
        ->runMessageLoopOnPause("");
  }
}

void Debugger::Resumed() {
  // Debugger.resumed event
  // ref:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-resumed
  debugProtocols::Resumed result;
  auto result_sp = result.GetDom();
  SendProtocolMessages(result_sp, -1, "Debugger.resumed");
  if (context_->GetInspector() &&
      static_cast<lepus_inspector::LepusInspectorImpl *>(
          context_->GetInspector())
          ->Client()) {
    static_cast<lepus_inspector::LepusInspectorImpl *>(context_->GetInspector())
        ->Client()
        ->quitMessageLoopOnPause();
  }
}

void Debugger::HandleStepping() {
  if (step_mode_.stepping_mode) {
    int32_t current_pc_line = 0;
    int32_t current_pc_col = 0;
    int32_t current_depth = 0;
    tools_->GetPCLineCol(GetCurrentFunction(), curr_pc_info_.second,
                         current_pc_line, current_pc_col);
    current_depth = tools_->GetStackDepth(context_);

    if (step_mode_.stepping_mode == LEPUS_DEBUGGER_STEP_IN) {
      // step in stop when stack depth is deeper or line number change
      if (current_depth == step_mode_.stepping_depth) {
        if (current_pc_line == step_mode_.stepping_line) {
          state_ = eStateRunning;
        } else {
          state_ = eStateStopped;
          step_mode_.stepping_mode = 0;
        }
      } else {
        state_ = eStateStopped;
        step_mode_.stepping_mode = 0;
      }
    } else if (step_mode_.stepping_mode == LEPUS_DEBUGGER_STEP) {
      // step over stop when stack depth is smaller or the same,  or line number
      // change
      if (current_depth > step_mode_.stepping_depth ||
          current_pc_line == step_mode_.stepping_line) {
        state_ = eStateRunning;
      } else {
        state_ = eStateStopped;
        step_mode_.stepping_mode = 0;
      }
    } else if (step_mode_.stepping_mode == LEPUS_DEBUGGER_STEP_OUT) {
      // step out stop when stack depth is smaller
      if (current_depth >= step_mode_.stepping_depth) {
        state_ = eStateRunning;
      } else {
        state_ = eStateStopped;
        step_mode_.stepping_mode = 0;
      }
    } else if (step_mode_.stepping_mode == LEPUS_DEBUGGER_STEP_CONTINUE) {
      state_ = eStateStopped;
      step_mode_.stepping_mode = 0;
    }
  }
}

lynx::base::scoped_refptr<Function> Debugger::GetCurrentFunction() {
  lynx::base::scoped_refptr<Closure> current_closure =
      context_->GetCurrentFrame()->function_->GetClosure();
  lynx::base::scoped_refptr<Function> current_function =
      current_closure->function();
  return current_function;
}

// send protocol message to debugger
void Debugger::SendMessagesToDebugger(const std::string &message) {
  switch (state_) {
    case eStateInvalid:
      state_ = eStateUnloaded;
    case eStateUnloaded:
      // Waiting for Debug.enable
      state_ = UpdateDebugger(message);
      break;
    case eStateConnected: {
      state_ = eStateAttaching;
    }
    case eStateAttaching:
      state_ = eStateLaunching;
    case eStateLaunching:
      state_ = UpdateDebugger(message);
      break;
    case eStateStopped: {
      state_ = UpdateDebugger(message);
      break;
    }
    case eStateCrashed:
      break;
    case eStateRunning: {
      // perform stepping checks prior to the breakpoint check
      if (step_mode_.stepping_mode) {
        int32_t current_pc_line = 0;
        int32_t current_pc_col = 0;
        int32_t current_depth = 0;
        tools_->GetPCLineCol(GetCurrentFunction(), curr_pc_info_.second,
                             current_pc_line, current_pc_col);
        current_depth = tools_->GetStackDepth(context_);
        if (current_depth == step_mode_.stepping_depth &&
            current_pc_line == step_mode_.stepping_line) {
          state_ = eStateRunning;
          break;
        }
      }
      // judge current pc is a breakpoint position
      std::string breakpoint_id = "";
      int32_t line_number = 0;
      int32_t col_number = 0;
      if (breakpoint_->IsEnabled() &&
          IsHitBreakpoint(breakpoint_id, line_number, col_number)) {
        state_ = eStateStopped;
        step_mode_.stepping_mode = 0;
      }

      HandleStepping();

      // paused event
      if (state_ == eStateStopped) {
        Paused();
        state_ = eStateRunning;
      }
      break;
    }
    case eStateExited:
      break;
    default:
      break;
  }
}

Debugger::StateType Debugger::UpdateDebugger(const std::string &message) {
  StateType new_state = state_;
  // crate an corresponding event, push to the queue
  HandleMsg(message);
  while (!EventEmpty()) {
    if (context_->GetRootFunction() && context_->GetCurrentFrame()) {
      Event currEvent((*GetEvent().get()));
      PopEvent();
      HandleDebugEvent(currEvent, new_state);
      state_ = new_state;
      // resume or disable
      if (currEvent.IsTerminal()) return new_state;
    } else {
      // root function is null, wait until root function is not null
      break;
    }
  }
  return new_state;
}

void Debugger::SetVMContext(VMContext *ctx) { context_ = std::move(ctx); }

// given the variable, construct a related remoteObject
// remoteObject ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-RemoteObject
void Debugger::GetVariablesProperties(debugProtocols::GetProperties *protocol,
                                      const Value &variables, Frame *frame) {
  if (variables.IsTable()) {
    lynx::lepus::Dictionary *dict = variables.Table().Get();
    for (auto &iter : *dict) {
      // function need to get object id first
      if (iter.second.IsClosure() || iter.second.IsObject() ||
          iter.second.IsArray()) {
        debugProtocols::RemoteObject object(
            iter.second,
            std::to_string(tools_->GenerateObjectId(frame, iter.second)));
        protocol->InitReturn(iter.first.str(), object);
      } else {
        // not function or object, objectid = "-1"
        debugProtocols::RemoteObject object(iter.second);
        protocol->InitReturn(iter.first.str(), object);
      }
    }
  }
}

// Handle the event and return new state.
void Debugger::HandleDebugEvent(Event &curr_event, StateType &current_state) {
  switch (curr_event.GetEventType()) {
    case enable: {
      LOGI("lepus debug: handle enable");
      std::shared_ptr<rapidjson::Document> result;
      if (GET_PROTOCOL->GetProtoType() ==
          debugProtocols::ProtocolType::Runtime) {
        // Runtime.enable
        auto *protocol = static_cast<debugProtocols::REnable *>(GET_PROTOCOL);
        protocol->GetRetDom(result);
        SendProtocolMessages(result, EVENT_ID);
      } else if (GET_PROTOCOL->GetProtoType() ==
                 debugProtocols::ProtocolType::Debug) {
        // Debug.enable
        auto *protocol = static_cast<debugProtocols::Enable *>(GET_PROTOCOL);
        protocol->GetRetDom(result);
        SendProtocolMessages(result, EVENT_ID);
        // if there is a debugger.enable message sent before, do not send
        // debugger.scriptParsed event
        if (!is_enabled_) {
          // return Debugger.scriptParsed event
          // ref:
          // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-scriptParsed
          int32_t start_line = 0, start_col = 0;
          int32_t end_line = 0, end_col = 0;

          if (context_->GetRootFunction().Get()) {
            std::string script =
                tools_->GetFunctionSourceCode(context_->GetRootFunction());
            Value scopes_ = context_->GetRootFunction()->GetScope();
            tools_->GetScopeLineColInfo(scopes_, start_line, start_col,
                                        end_line, end_col);
          }
          current_state = eStateConnected;
          debugProtocols::ScriptParsed res("0", "lepus.js", start_line,
                                           start_col, end_line, end_col, 0, "");
          result = res.GetDom();
          SendProtocolMessages(result, -1, "Debugger.scriptParsed");
          is_enabled_ = true;
        }
      }
      break;
    }
    case getProperties: {
      // Runtime.getProperties
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-getProperties
      LOGI("lepus debug: handle get properties");
      auto *debug_protocol =
          static_cast<debugProtocols::GetProperties *>(GET_PROTOCOL);
      std::string object_id = debug_protocol->GetObjectId();
      Value variables(lynx::lepus::Dictionary::Create());
      Frame *frame = context_->GetCurrentFrame();
      tools_->GetProperties(object_id, variables, frame);
      GetVariablesProperties(debug_protocol, variables, frame);
      std::shared_ptr<rapidjson::Document> result_sp;
      debug_protocol->GetRetDom(result_sp);
      SendProtocolMessages(result_sp, EVENT_ID);
      break;
    }
    case stopAtEntry: {
      // stop at the first line and first column of the lepus.js
      current_state = eStateStopped;
      // send Debugger.paused event
      Paused();
      // when return from Paused function, continue running, set curr_state
      // eStateRunning
      current_state = eStateRunning;
      break;
    }
    case getScriptSource: {
      // Debugger.getScriptSource
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getScriptSource
      LOGI("lepus debug: handle getScriptSource");
      auto *debug_protocol =
          static_cast<debugProtocols::GetScriptSource *>(GET_PROTOCOL);
      std::string script;
      if (context_->GetRootFunction().Get()) {
        script = tools_->GetFunctionSourceCode(context_->GetRootFunction());
      }

      debug_protocol->InitReturn(script);
      std::shared_ptr<rapidjson::Document> result_sp;
      debug_protocol->GetRetDom(result_sp);
      SendProtocolMessages(result_sp, EVENT_ID);
      break;
    }
    case setBreakpointsActive: {
      // Debugger.setBreakpointsActive
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointsActive
      LOGI("lepus debug: "
           << "Handle Debug.setBreakpointsActive.");
      auto *debug_protocol =
          static_cast<debugProtocols::SetBreakpointsActive *>(GET_PROTOCOL);
      breakpoint_->SetEnabled(debug_protocol->GetActive());
      std::shared_ptr<rapidjson::Document> result_sp;
      debug_protocol->GetRetDom(result_sp);
      SendProtocolMessages(result_sp, EVENT_ID);
      break;
    }
    case setBreakpointByUrl: {
      // Debugger.setBreakpointByUrl
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
      LOGI("lepus debug: "
           << "Handle Debug.setBreakpointByUrl.");
      auto *debug_protocol =
          static_cast<debugProtocols::SetBreakpointByUrl *>(GET_PROTOCOL);
      if (all_functions_.empty())
        GetAllFunctions(context_->GetRootFunction().Get());
      // generate breakpoint id
      std::string bId = "1:" + std::to_string(debug_protocol->GetLineNumber()) +
                        ":" +
                        std::to_string(debug_protocol->GetColumnNumber()) +
                        ":" + debug_protocol->GetUrl();
      if (breakpoint_->ResolveBreakpoint(debug_protocol, all_functions_,
                                         "lepus.js")) {
        // this protocol is send to lepus
        debug_protocol->InitRet(bId,
                                template_vector<debugProtocols::Location>(
                                    1, {"0", debug_protocol->GetLineNumber(),
                                        debug_protocol->GetColumnNumber()}));
      } else {
        // this protocol is sent to v8, just return empty locations
        debug_protocol->InitRet(bId,
                                template_vector<debugProtocols::Location>(0));
      }
      std::shared_ptr<rapidjson::Document> result_sp;
      debug_protocol->GetRetDom(result_sp);
      SendProtocolMessages(result_sp, EVENT_ID);
      break;
    }
    case getPossibleBreakpoints: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getPossibleBreakpoints
      LOGI("lepus debug: "
           << "Handle Debug.getPossibleBreakpoints.");
      auto *protocol =
          static_cast<debugProtocols::GetPossibleBreakpoints *>(GET_PROTOCOL);
      breakpoint_->FindAllPossibleBreakpointPos(protocol, all_functions_);
      std::shared_ptr<rapidjson::Document> result_sp;
      protocol->GetRetDom(result_sp);
      SendProtocolMessages(result_sp, EVENT_ID);
      break;
    }
    case stepOver: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepOver
      LOGI("lepus debug: "
           << "handle step over");
      // get current pc, current line and column and function depth
      int32_t step_line = 0;
      int32_t step_col = 0;
      tools_->GetPCLineCol(GetCurrentFunction(), curr_pc_info_.second,
                           step_line, step_col);
      int32_t depth = tools_->GetStackDepth(context_);
      step_mode_ =
          DebuggerStep(LEPUS_DEBUGGER_STEP, step_line, step_col, depth);
      current_state = eStateRunning;
      RESPOND_DEFAULT_MESSAGE(debugProtocols::StepOver);
      // debugger.resumed
      Resumed();
      break;
    }
    case stepInto: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepInto
      int32_t step_line = 0;
      int32_t step_col = 0;
      tools_->GetPCLineCol(GetCurrentFunction(), curr_pc_info_.second,
                           step_line, step_col);
      int32_t depth = tools_->GetStackDepth(context_);
      step_mode_ =
          DebuggerStep(LEPUS_DEBUGGER_STEP_IN, step_line, step_col, depth);
      current_state = eStateRunning;
      RESPOND_DEFAULT_MESSAGE(debugProtocols::StepInto);
      // debugger.resumed
      Resumed();
      break;
    }
    case stepOut: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepOut
      int32_t step_line = 0;
      int32_t step_col = 0;
      tools_->GetPCLineCol(GetCurrentFunction(), curr_pc_info_.second,
                           step_line, step_col);
      int32_t depth = tools_->GetStackDepth(context_);
      step_mode_ =
          DebuggerStep(LEPUS_DEBUGGER_STEP_OUT, step_line, step_col, depth);
      current_state = eStateRunning;
      RESPOND_DEFAULT_MESSAGE(debugProtocols::StepOut);
      Resumed();
      break;
    }
    case resume: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-resume
      LOGI("lepus debug: "
           << "Handle Debug.resume");
      RESPOND_DEFAULT_MESSAGE(debugProtocols::Resume);
      current_state = eStateRunning;
      Resumed();
      break;
    }
    case removeBreakpoint: {
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-removeBreakpoint
      LOGI("lepus debug: "
           << "Handle Debug.removeBreakpoint.");
      auto *rbp = static_cast<debugProtocols::RemoveBreakpoint *>(GET_PROTOCOL);
      breakpoint_->RemoveBreakpointById(rbp->GetBreakpointId());
      RESPOND_DEFAULT_MESSAGE(debugProtocols::RemoveBreakpoint);
      break;
    }
    case disable: {
      // Runtime.disable
      // ref:
      // https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-disable
      if (GET_PROTOCOL->GetProtoType() == debugProtocols::ProtocolType::Runtime)
        break;
      else {
        // Debugger.disable
        // ref:
        // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-disable
        LOGI("lepus debug: "
             << "Handle Debug.disable.");
        current_state = eStateExited;
      }
      RESPOND_DEFAULT_MESSAGE(debugProtocols::Disable);
      break;
    }
    case undefined: {
      // protocols currently we have not implemented, just return {}
      LOGI("lepus debug: "
           << "Protocol undefined!");
      auto dom = std::make_shared<rapidjson::Document>();
      dom->SetObject();
      std::string return_message = ConstructReturnMessage(dom, EVENT_ID);
      dom = nullptr;
      SendResponseMessage(EVENT_ID, return_message);
      break;
    }
    default: {
      RESPOND_DEFAULT_MESSAGE(debugProtocols::BaseProtocol);
      current_state = eStateCrashed;
      break;
    }
  }
}

// construct return protocol message
std::string Debugger::ConstructReturnMessage(
    const std::shared_ptr<rapidjson::Document> &dom, int32_t id,
    const std::string &method) {
  rapidjson::Document res;

  res.SetObject();
  if (!method.empty()) {
    res.AddMember("method", rapidjson::StringRef((method).c_str()),
                  res.GetAllocator());
    res.AddMember("params", dom->GetObject(), res.GetAllocator());
  } else {
    res.AddMember("id", id, res.GetAllocator());
    res.AddMember("result", dom->GetObject(), res.GetAllocator());
  }

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  res.Accept(writer);
  return buffer.GetString();
}

void Debugger::SetDebugInfo(const std::string &debug_info) {
  debug_info_ = debug_info;
}

static Value SetFunctionScope(const rapidjson::Document::Object &function_scope,
                              Value dic = Value()) {
  Value scope_dic = Value(Dictionary::Create());

  // scope start line&column
  int32_t start_line = function_scope["start_line"].GetInt();
  int32_t start_col = function_scope["start_column"].GetInt();
  int64_t start_line_col = (static_cast<uint64_t>(start_line) << 30 |
                            static_cast<uint64_t>(start_col));
  scope_dic.SetProperty(Function::kStartLine, Value(start_line_col));
  // scope end line&column
  int32_t end_line = function_scope["end_line"].GetInt();
  int32_t end_col = function_scope["end_column"].GetInt();
  int64_t end_line_col =
      (static_cast<uint64_t>(end_line) << 30 | static_cast<uint64_t>(end_col));
  scope_dic.SetProperty(Function::kEndLine, Value(end_line_col));

  // variable info: variable name + variable register id
  int32_t var_num = function_scope["variable_number"].GetInt();
  for (int32_t var_index = 0; var_index < var_num; var_index++) {
    auto var = function_scope["variable_info"][var_index].GetObject();
    std::string var_name = var["variable_name"].GetString();
    uint32_t var_reg = var["variable_reg_info"].GetUint();
    scope_dic.SetProperty(var_name, Value(var_reg));
  }

  // child scope
  auto child_scopes = function_scope["child_scope"].GetObject();
  int32_t child_scope_num = child_scopes["child_scope_number"].GetInt();
  if (child_scope_num != 0) {
    auto child_scope = Value();
    auto child_scope_array = Value(CArray::Create());
    for (int32_t scope_index = 0; scope_index < child_scope_num;
         scope_index++) {
      auto each_child =
          child_scopes["child_scope_info"][scope_index].GetObject();
      child_scope = SetFunctionScope(each_child);
      if (child_scope != Value()) {
        child_scope_array.Array()->push_back(child_scope);
      }
    }
    scope_dic.SetProperty(Function::kChilds, child_scope_array);
  }

  if (dic != Value()) {
    dic.SetProperty(Function::kScopesName, scope_dic);
  }
  return scope_dic;
}

static void SetTemplateDebugInfo(
    const std::string &debug_info_json,
    const base::scoped_refptr<Function> &function) {
  if (function->GetFunctionId() == -1) {
    return;
  }

  auto debug_info_dic = Value(Dictionary::Create());
  rapidjson::Document document;
  document.Parse(debug_info_json.c_str());

  // lepus_debug_info
  if (document.HasMember("lepus_debug_info")) {
    auto debug_info = document["lepus_debug_info"].GetObject();
    int32_t func_num = debug_info["function_number"].GetInt();
    int32_t func_index = 0;
    for (func_index = 0; func_index < func_num; func_index++) {
      auto each_func = debug_info["function_info"][func_index].GetObject();
      int64_t each_func_id = each_func["function_id"].GetInt64();
      // find the corresponding function domain for this function
      if (each_func_id == function->GetFunctionId()) {
        break;
      }
    }

    // can not find the corresponding function domain, return
    if (func_index == func_num) {
      return;
    }

    auto func_info = debug_info["function_info"][func_index].GetObject();
    // function name
    std::string func_name = func_info["function_name"].GetString();
    function->SetFunctionName(func_name);

    // line col info
    auto line_col_info = func_info["line_col_info"].GetObject();
    int32_t pc_size = line_col_info["pc_size"].GetInt();
    for (int32_t pc_index = 0; pc_index < pc_size; pc_index++) {
      auto line_col = line_col_info["line_col"][pc_index].GetObject();
      int32_t line = line_col["line"].GetInt();
      int32_t column = line_col["column"].GetInt();
      int64_t line_col_64 =
          (static_cast<uint64_t>(line) << 30 | static_cast<uint64_t>(column));
      function->SetLineInfo(static_cast<int32_t>(pc_index), line_col_64);
    }
    debug_info_dic.SetProperty(Function::kLineColInfo, function->GetLineInfo());

    // function source
    std::string function_source = func_info["function_source"].GetString();
    if (!function_source.empty()) {
      function->SetSource(function_source);
      debug_info_dic.SetProperty(Function::kFuncSource,
                                 Value(function_source.c_str()));
    }

    // function scope
    auto function_scope = func_info["function_scope"].GetObject();
    SetFunctionScope(function_scope, debug_info_dic);

    function->PushDebugInfoToConstValues(debug_info_dic);

    // process the child function recursively
    for (auto child : function->GetChildFunction()) {
      SetTemplateDebugInfo(debug_info_json, child);
    }
  }
}

// get all the debuginfo from template_debug.json
void Debugger::PrepareDebugInfo() {
  if (debug_info_ == "" || !context_) {
    return;
  }

  SetTemplateDebugInfo(debug_info_, context_->GetRootFunction());
}

// get all the function in current context
void Debugger::GetAllFunctions(Function *root_function) {
  all_functions_.push_back(root_function);
  Instruction *ins;

  for (size_t j = 0; j < all_functions_.size(); j++) {
    Function *func_ptr = all_functions_[j];

    for (size_t i = 0; i < func_ptr->OpCodeSize(); i++) {
      ins = func_ptr->GetInstruction(i);

      if (Instruction::GetOpCode(*ins) == TypeOp_Closure) {
        int32_t line = 0, col = 0;
        tools_->GetPCLineCol(func_ptr, static_cast<int32_t>(i), line, col);
        long index = Instruction::GetParamBx(*ins);
        all_functions_.push_back(func_ptr->GetChildFunction(index).Get());
      }
    }
  }
}

// return if current position is a breakpoint
bool Debugger::IsHitBreakpoint(std::string &breakpoint_id, int32_t &line_number,
                               int32_t &col_number) {
  if (breakpoint_->FindBreakpointUsingCurrentPC(curr_pc_info_, breakpoint_id,
                                                line_number, col_number)) {
    return true;
  }
  return false;
}

// given a protocol message, create a corresponding event, and push message
// queue
void Debugger::HandleMsg(const std::string &m) {
  if (!m.empty()) {
    std::shared_ptr<Event> event(new Event(EventType::undefined));
    event->InitData(m);
    AddEvent(event);
  }
}

void Debugger::AddEvent(std::shared_ptr<Event> &event) {
  if (events_.empty()) {
    events_.clear();
  }
  events_.emplace_back(event);
}

void Debugger::SendResponseMessage(int32_t id,
                                   const std::string &return_message) {
  static_cast<lepus_inspector::LepusInspectorSessionImpl *>(
      context_->GetSession())
      ->sendProtocolResponse(id, return_message);
}

void Debugger::SendNotificationMessage(const std::string &return_message) {
  static_cast<lepus_inspector::LepusInspectorSessionImpl *>(
      context_->GetSession())
      ->sendProtocolNotification(return_message);
}
}  // namespace lepus
}  // namespace lynx
