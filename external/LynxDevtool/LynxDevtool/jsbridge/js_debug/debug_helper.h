// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_DEBUG_DEBUG_HELPER_H
#define LYNX_INSPECTOR_JS_DEBUG_DEBUG_HELPER_H

namespace lynx {
namespace devtool {
constexpr int kDefaultViewID = -1;
constexpr int kErrorViewID = -2;
constexpr int kDefaultGroupID = -1;
constexpr int kErrorGroupID = -2;
constexpr int kDefaultWorkerGroupID = -3;
constexpr int kDefaultGlobalRuntimeID = -1;
constexpr char kSingleGroupID[] = "-1";
constexpr char kErrorGroupStr[] = "-2";
constexpr char kDefaultWorkerGroupStr[] = "-3";
constexpr char kSingleGroupPrefix[] = "single_group_";

constexpr char kThreadJS[] = "Lynx_JS";

constexpr char kScriptUrlPrefix[] = "file://view";
constexpr char kScriptUrlAppService[] = "/app-service.js";
constexpr char kStopAtEntryReason[] = "stopAtEntry";

constexpr char kKeyMethod[] = "method";
constexpr char kKeyId[] = "id";
constexpr char kKeyParams[] = "params";
constexpr char kKeySkip[] = "skip";
constexpr char kKeyScriptId[] = "scriptId";
constexpr char kKeyBreakpointId[] = "breakpointId";
constexpr char kKeyThrowOnSideEffect[] = "throwOnSideEffect";
constexpr char kKeyDisableBreaks[] = "disableBreaks";
constexpr char kKeyUrl[] = "url";
constexpr char kKeyCondition[] = "condition";
constexpr char kKeyLineNumber[] = "lineNumber";
constexpr char kKeyColumnNumber[] = "columnNumber";
constexpr char kKeyActive[] = "active";
constexpr char kKeyExecutionContextId[] = "executionContextId";
constexpr char kKeyResult[] = "result";
constexpr char kKeyDebuggerId[] = "debuggerId";
constexpr char kKeyArgs[] = "args";
constexpr char kKeyValue[] = "value";
constexpr char kKeyStringType[] = "string";

constexpr char kKeyViewId[] = "viewId";
constexpr char kKeyConsoleId[] = "consoleId";
constexpr char kKeyRuntimeId[] = "runtimeId";
constexpr char kKeyGroupId[] = "groupId";
constexpr char kKeyLepusRuntimeId[] = "lepusRuntimeId";
constexpr char kKeyConsoleTag[] = "consoleTag";
constexpr char kKeyEngineType[] = "engineType";
constexpr char kKeyEngineV8[] = "V8";
constexpr char kKeyEngineQuickjs[] = "Quickjs";
constexpr char kKeyEngineLepus[] = "Lepus";
constexpr char kKeyEngineLepusNG[] = "LepusNG";

constexpr char kKeyTargetInfo[] = "targetInfo";
constexpr char kKeyTargetId[] = "targetId";
constexpr char kKeyType[] = "type";
constexpr char kKeyTitle[] = "title";
constexpr char kKeyAttached[] = "attached";
constexpr char kKeyCanAccessOpener[] = "canAccessOpener";
constexpr char kKeySessionId[] = "sessionId";
constexpr char kKeyWaitingForDebugger[] = "waitingForDebugger";

constexpr char kMethodDebuggerEnable[] = "Debugger.enable";
constexpr char kMethodDebuggerDisable[] = "Debugger.disable";
constexpr char kMethodDebuggerResume[] = "Debugger.resume";
constexpr char kMethodDebuggerSetSkipAllPauses[] = "Debugger.setSkipAllPauses";
constexpr char kMethodDebuggerSetBreakpointsActive[] =
    "Debugger.setBreakpointsActive";
constexpr char kMethodDebuggerSetBreakpointByUrl[] =
    "Debugger.setBreakpointByUrl";
constexpr char kMethodDebuggerRemoveBreakpoint[] = "Debugger.removeBreakpoint";
constexpr char kMethodDebuggerSetDebugActive[] = "Debugger.setDebugActive";
constexpr char kMethodRuntimeEnable[] = "Runtime.enable";
constexpr char kMethodRuntimeDisable[] = "Runtime.disable";
constexpr char kMethodRuntimeEvaluate[] = "Runtime.evaluate";
constexpr char kMethodProfilerEnable[] = "Profiler.enable";
constexpr char kMethodProfilerStart[] = "Profiler.start";
constexpr char kMethodProfilerStop[] = "Profiler.stop";

constexpr char kEventDebuggerScriptParsed[] = "Debugger.scriptParsed";
constexpr char kEventDebuggerRemoveScriptsForLynxView[] =
    "Debugger.removeScriptsForLynxView";
constexpr char kEventRuntimeConsoleAPICalled[] = "Runtime.consoleAPICalled";
constexpr char kEventRuntimeExecutionContextDestroyed[] =
    "Runtime.executionContextDestroyed";
constexpr char kEventProfilerEnabled[] = "Profiler.enabled";

constexpr char kEventTargetCreated[] = "Target.targetCreated";
constexpr char kEventAttachedToTarget[] = "Target.attachedToTarget";
constexpr char kEventTargetDestroyed[] = "Target.targetDestroyed";
constexpr char kEventDetachedFromTarget[] = "Target.detachedFromTarget";

constexpr char kLepusTargetIdPrefix[] = "LEPUSDEBUGTARGET";
constexpr char kLepusSessionIdPrefix[] = "LEPUSDEBUGSESSIONID";
constexpr char kLepusTargetTitle[] = "Lepus";
constexpr char kLepusTriggerScript[] = "(function() { let a = 1; }())";
constexpr char kLepusTriggerFileName[] = "quickjsTriggerTimer.js";
constexpr char kWorkerTargetIdPrefix[] = "WORKERDEBUGTARGET";
constexpr char kWorkerSessionIdPrefix[] = "WORKERDEBUGSESSIONID";
constexpr char kWorkerTargetTitle[] = "Worker";
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_DEBUG_HELPER_H
