#include "devtool/quickjs/qjs_inspector_handle.h"

#include <string>

#include "basic/log/logging.h"
#include "devtool/inspector_impl.h"
#ifdef __cplusplus
extern "C" {
#endif
#include "devtool/quickjs/interface.h"
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace {
bool sPauseAtEntry = false;
}  // namespace

namespace vmsdk {
namespace devtool {
namespace qjs {

// static
void QjsInspectorHandle::SetPauseAtEntry(bool enable) {
  VLOGD("[qjs_inspector] Set pause at entry: %d", enable);
  sPauseAtEntry = enable;
}

QjsInspectorHandle::QjsInspectorHandle(LEPUSRuntime* rt,
                                       InspectorImpl* inspector_impl)
    : inspector_impl_(inspector_impl),
      rt_(rt),
      message_queue_(std::make_unique<MessageQueue>()),
      lock_(),
      condition_(lock_) {}

// callback start

static void RunMessageLoopOnPauseCB(LEPUSContext* ctx) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  handle->Pause();
}

static void QuitMessageLoopOnPauseCB(LEPUSContext* ctx) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  handle->QuitPause();
}

static void SendResponseCB(LEPUSContext* ctx, int32_t message_id,
                           const char* message) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  std::string str(message);
  VLOGD("[qjs_inspector] SendResponseCB %s", str.c_str());
  handle->GetInspector()->SendResponseMessage(str);
}

static void SendNotificationCB(LEPUSContext* ctx, const char* message) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  std::string str(message);
  VLOGD("[qjs_inspector] SendNotificationCB %s", str.c_str());
  handle->GetInspector()->SendResponseMessage(str);
}

static void FreeMessagesCB(LEPUSContext* ctx, char** messages, int32_t size) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  for (size_t m_i = 0; m_i < static_cast<size_t>(size); m_i++) {
    free(messages[m_i]);
  }
  free(messages);
}

static void DebuggerExceptionCB(LEPUSContext* ctx) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  HandleDebuggerException(ctx);
}

static void InspectorCheckCB(LEPUSContext* ctx) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  DoInspectorCheck(ctx);
}

static void ConsoleMessageCB(LEPUSContext* ctx, int tag, LEPUSValueConst* argv,
                             int argc) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  int i;
  const char* str;

  for (i = 0; i < argc; i++) {
    if (i != 0) putchar(' ');
    str = LEPUS_ToCString(ctx, argv[i]);
    if (!str) return;
    fputs(str, stdout);
    LEPUS_FreeCString(ctx, str);
  }
  putchar('\n');
}

static void SendScriptParsedMessageCB(LEPUSContext* ctx,
                                      LEPUSScriptSource* script) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  SendScriptParsedNotification(ctx, script);
}

static void SendConsoleMessageCB(LEPUSContext* ctx, LEPUSValue* console_msg) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  SendConsoleAPICalledNotification(ctx, console_msg);
}

static void SendScriptFailToParsedMessageCB(LEPUSContext* ctx,
                                            LEPUSScriptSource* script) {
  auto handle =
      reinterpret_cast<QjsInspectorHandle*>(LEPUS_GetContextOpaque(ctx));
  if (!handle) return;
  SendScriptFailToParseNotification(ctx, script);
}

static uint8_t IsRuntimeDevtoolOnCB(LEPUSRuntime* rt) { return 1; }

// callback end

void QjsInspectorHandle::DispatchMessage(
    const std::string& message,
    std::shared_ptr<runtime::TaskRunner> taskRunner) {
  VLOGD("[qjs_inspector] DispatchMessage %s", message.c_str());
  {
    general::AutoLock lock(lock_);
    if (waiting_for_message_) {
      message_queue_->push(message);
      condition_.Signal();
    } else {
      taskRunner->PostTask(vmsdk::general::Bind(
          [this, message]() { ProcessPausedMessages(ctx_, message.c_str()); }));
    }
  }
}

void QjsInspectorHandle::SendResponse(const std::string& response) {
  if (inspector_impl_ != nullptr) {
    inspector_impl_->SendResponseMessage(response);
  }
}

void QjsInspectorHandle::ContextCreated(LEPUSContext* ctx) {
  // register quickjs debugger related callback functions
  void* funcs[14] = {reinterpret_cast<void*>(RunMessageLoopOnPauseCB),
                     reinterpret_cast<void*>(QuitMessageLoopOnPauseCB),
                     reinterpret_cast<void*>(NULL),
                     reinterpret_cast<void*>(SendResponseCB),
                     reinterpret_cast<void*>(SendNotificationCB),
                     reinterpret_cast<void*>(FreeMessagesCB),
                     reinterpret_cast<void*>(DebuggerExceptionCB),
                     reinterpret_cast<void*>(InspectorCheckCB),
                     reinterpret_cast<void*>(ConsoleMessageCB),
                     reinterpret_cast<void*>(SendScriptParsedMessageCB),
                     reinterpret_cast<void*>(SendConsoleMessageCB),
                     reinterpret_cast<void*>(SendScriptFailToParsedMessageCB),
                     nullptr,
                     reinterpret_cast<void*>(IsRuntimeDevtoolOnCB)};
  ctx_ = ctx;
  PrepareQJSDebuggerDefer(ctx, reinterpret_cast<void**>(funcs), 14);
  QJSDebuggerInitialize(ctx_);
  LEPUS_SetContextOpaque(ctx_, this);

  if (sPauseAtEntry) {
    std::string kProtocolRuntimeEnable =
        R"({"id":0,"method":"Runtime.enable","params":{}})";
    std::string kProtocolDebuggerEnable =
        R"({"id":1,"method":"Debugger.enable","params":{"maxScriptsCacheSize":100000000}})";
    std::string kProtocolStopAtEntry =
        R"({"id":2,"method":"Debugger.stopAtEntry","params":{"stepOverByInstruction":true}})";

    ProcessPausedMessages(ctx_, kProtocolRuntimeEnable.c_str());
    ProcessPausedMessages(ctx_, kProtocolDebuggerEnable.c_str());
    ProcessPausedMessages(ctx_, kProtocolStopAtEntry.c_str());
  }
}

void QjsInspectorHandle::ContextDestroyed() { QuitPause(); }

void QjsInspectorHandle::QuitPause() {
  VLOGD("[qjs_inspector] QuitPause");
  general::AutoLock lock(lock_);
  running_nested_loop_ = false;
  waiting_for_message_ = false;
  condition_.Signal();
}

void QjsInspectorHandle::Pause() {
  if (running_nested_loop_) {
    return;
  }
  VLOGD("[qjs_inspector] Pause");
  {
    general::AutoLock lock(lock_);
    running_nested_loop_ = true;
    waiting_for_message_ = true;
  }

  while (waiting_for_message_) {
    lock_.Acquire();
    std::string msg;
    if (!message_queue_->empty()) {
      msg = message_queue_->front();
      message_queue_->pop();
    } else if (waiting_for_message_) {
      condition_.Wait();
    }
    lock_.Release();
    ProcessPausedMessages(ctx_, msg.c_str());
  }
}

}  // namespace qjs
}  // namespace devtool
}  // namespace vmsdk