// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/lepusng/debugger/lepusng_debugger.h"

#include "jsbridge/js_debug/lepusng/interface.h"

#define CAST_SESSION(SESSION) \
  static_cast<lepus_inspector::LepusInspectorSessionImpl*>(SESSION)
#define CAST_INSPECTOR(inspector) \
  static_cast<lepus_inspector::LepusInspectorImpl*>(inspector)

namespace lynx {
namespace debug {
LepusNGDebugger::LepusNGDebugger() : debug_info_("") {}
void LepusNGDebugger::DebuggerSendNotification(lepus::Context* context,
                                               const char* message) {
  if (context->GetSession()) {
    CAST_SESSION(context->GetSession())->sendProtocolNotification(message);
  }
}

void LepusNGDebugger::DebuggerSendResponse(lepus::Context* ctx,
                                           int32_t message_id,
                                           const char* message) {
  if (ctx->GetSession()) {
    CAST_SESSION(ctx->GetSession())->sendProtocolResponse(message_id, message);
  }
}

void LepusNGDebugger::SetDebugInfo(const std::string& debug_info) {
  debug_info_ = debug_info;
}

static void FillFunctionBytecodeDebugInfo(
    LEPUSContext* ctx, LEPUSFunctionBytecode* b,
    rapidjson::Document::Object& debug_info) {
  uint32_t func_num = debug_info["function_number"].GetUint();
  uint32_t function_id = GetFunctionDebugId(b);
  uint32_t func_index = 0;
  for (; func_index < func_num; func_index++) {
    auto each_func = debug_info["function_info"][func_index].GetObject();
    auto each_func_id = each_func["function_id"].GetUint();
    // find the corresponding function domain for this function
    if (each_func_id == function_id) {
      break;
    }
  }
  // can not find the corresponding function domain, return
  if (func_index == func_num) {
    return;
  }

  auto func_info = debug_info["function_info"][func_index].GetObject();

  // filename
  if (func_info.HasMember("file_name")) {
    std::string function_file_name = func_info["file_name"].GetString();
    SetFunctionDebugFileName(ctx, b, function_file_name.c_str(),
                             static_cast<int>(function_file_name.length()));
  } else {
    SetFunctionDebugFileName(ctx, b, "", 0);
  }

  // line number
  int32_t debug_line_num = func_info["line_number"].GetInt();
  SetFunctionDebugLineNum(b, debug_line_num);

  // column number
  int64_t debug_column_num = func_info["column_number"].GetInt64();
  SetFunctionDebugColumnNum(b, debug_column_num);

  // pc2line_len
  int32_t pc2line_len = func_info["pc2line_len"].GetInt();

  // pc2line_buf
  if (func_info.HasMember("pc2line_buf")) {
    uint8_t* buf =
        static_cast<uint8_t*>(lepus_malloc(ctx, sizeof(uint8_t) * pc2line_len));
    if (buf) {
      for (int32_t i = 0; i < pc2line_len; i++) {
        buf[i] = func_info["pc2line_buf"][i].GetUint();
      }
    }
    SetFunctionDebugPC2LineBufLen(ctx, b, buf, pc2line_len);
    lepus_free(ctx, buf);
  } else {
    SetFunctionDebugPC2LineBufLen(ctx, b, nullptr, 0);
  }

  // child function source
  if (func_info.HasMember("function_source") &&
      func_info.HasMember("function_source_len")) {
    int32_t function_source_len = func_info["function_source_len"].GetInt();
    std::string function_source = func_info["function_source"].GetString();
    SetFunctionDebugSource(ctx, b, function_source.c_str(),
                           function_source_len);
  } else {
    SetFunctionDebugSource(ctx, b, nullptr, 0);
  }
}

static void SetTemplateDebugInfo(LEPUSContext* ctx,
                                 const std::string& debug_info_json,
                                 LEPUSValue obj) {
  rapidjson::Document document;
  document.Parse(debug_info_json.c_str());
  if (document.HasMember("lepusNG_debug_info")) {
    auto debug_info = document["lepusNG_debug_info"].GetObject();
    if (!LEPUS_IsUndefined(obj) && debug_info.HasMember("function_number")) {
      uint32_t func_size = 0;
      auto* function_list = GetDebuggerAllFunction(ctx, obj, &func_size);
      uint32_t function_num = debug_info["function_number"].GetUint();
      if (function_num != func_size) {
        LOGE("error in set lepusNG debuginfo");
        lepus_free(ctx, function_list);
        return;
      }
      if (function_list) {
        for (uint32_t i = 0; i < func_size; i++) {
          auto* b = function_list[i];
          if (b) {
            FillFunctionBytecodeDebugInfo(ctx, b, debug_info);
          }
        }
      } else {
        LOGE("lepusng debug: get all function fail");
      }
      lepus_free(ctx, function_list);
    }

    if (LEPUS_IsUndefined(obj) && debug_info.HasMember("function_source") &&
        debug_info.HasMember("end_line_num")) {
      std::string source = debug_info["function_source"].GetString();
      char* source_str = const_cast<char*>(source.c_str());
      SetDebuggerSourceCode(ctx, source_str);
      int32_t end_line_num = debug_info["end_line_num"].GetInt();
      SetDebuggerEndLineNum(ctx, end_line_num);
      AddDebuggerScript(ctx, source_str, static_cast<int32_t>(source.length()),
                        end_line_num);
    }
  }
}

void LepusNGDebugger::PrepareDebugInfo() {
  if (debug_info_ == "" || !context_) {
    const std::string source = "debug-info.json download fail, please check!";
    AddDebuggerScript(context_->context(), const_cast<char*>(source.c_str()),
                      static_cast<int32_t>(source.length()), 0);
    return;
  }

  SetTemplateDebugInfo(context_->context(), debug_info_,
                       context_->GetTopLevelFunction());
}

void LepusNGDebugger::DebuggerRunMessageLoopOnPause(lepus::Context* context) {
  if (context->GetInspector()) {
    // the param of runMessageLoopOnPause is only used in js thread quickjs
    // debugger, pass empty string in other situations
    CAST_INSPECTOR(context->GetInspector())
        ->Client()
        ->runMessageLoopOnPause("");
  }
}

void LepusNGDebugger::DebuggerQuitMessageLoopOnPause(lepus::Context* context) {
  if (context->GetInspector()) {
    CAST_INSPECTOR(context->GetInspector())->Client()->quitMessageLoopOnPause();
  }
}

void LepusNGDebugger::DebuggerGetMessages(lepus::Context* context) {
  LEPUSContext* ctx = context->context();
  if (context->GetInspector()) {
    std::queue<std::string> message_queue =
        CAST_INSPECTOR(context->GetInspector())
            ->Client()
            ->getMessageFromFrontend();

    LEPUSDebuggerInfo* info = GetDebuggerInfo(ctx);
    if (!info) return;
    while (!message_queue.empty()) {
      std::string m = message_queue.front();
      if (m.length()) {
        PushBackQueue(GetDebuggerMessageQueue(info), m.c_str());
      }
      message_queue.pop();
    }
  }
}

// for each pc, first call this function for debugging
void LepusNGDebugger::InspectorCheck(lepus::Context* context) {
  LEPUSContext* ctx = context->context();
  DoInspectorCheck(ctx);
}

void LepusNGDebugger::DebuggerException(lepus::Context* context) {
  LEPUSContext* ctx = context->context();
  HandleDebuggerException(ctx);
}

void LepusNGDebugger::DebuggerFree(lepus::Context* context) {
  LEPUSContext* ctx = context->context();
  QJSDebuggerFree(ctx);
}

void LepusNGDebugger::ProcessPausedMessages(lepus::Context* context,
                                            const std::string& message) {
  LEPUSContext* ctx = context->context();
  LEPUSDebuggerInfo* info = GetDebuggerInfo(ctx);
  if (!info) return;
  if (message != "") {
    PushBackQueue(GetDebuggerMessageQueue(info), message.c_str());
  }
  ProcessProtocolMessages(info);
}

void LepusNGDebugger::DebuggerInitialize(lepus::Context* context) {
  LEPUSContext* ctx = context->context();
  QJSDebuggerInitialize(ctx);
  context_ = context;
}

void LepusNGDebugger::DebuggerSendConsoleMessage(lepus::Context* ctx,
                                                 LEPUSValue* message) {
  SendConsoleAPICalledNotification(ctx->context(), message);
}

void LepusNGDebugger::DebuggerSendScriptParsedMessage(
    lepus::Context* ctx, LEPUSScriptSource* script) {
  SendScriptParsedNotification(ctx->context(), script);
}

void LepusNGDebugger::DebuggerSendScriptFailToParseMessage(
    lepus::Context* ctx, LEPUSScriptSource* script) {
  SendScriptFailToParseNotification(ctx->context(), script);
}

}  // namespace debug
}  // namespace lynx
