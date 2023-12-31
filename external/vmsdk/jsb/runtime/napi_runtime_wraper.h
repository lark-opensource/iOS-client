#ifndef NAPI_RUNTIME_WRAPER_H_
#define NAPI_RUNTIME_WRAPER_H_

#include "basic/log/logging.h"
#include "napi.h"
#include "napi_env.h"
#include "napi_runtime.h"
#include "task_runner.h"

#define JS_ENGINE_QJS  // before include inspector.h and inspector_factory.h
#if defined(ENABLE_DEBUGGER)
#include "jsb/devtool/inspector.h"
#include "jsb/devtool/inspector_factory.h"
#endif

#if defined(OS_IOS)
#define JS_ENGINE_JSC
#endif

#if defined(OS_ANDROID)
#include "jsb/inspector_new/v8_inspector_client_impl.h"
#endif

#ifdef JS_ENGINE_QJS
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif  // __cplusplus
#include "napi_env_quickjs.h"
#endif  // JS_ENGINE_QJS

#if defined(JS_ENGINE_V8)
#include <libplatform/libplatform.h>
#include <v8.h>

#include "napi_env_v8.h"
#endif

#ifdef JS_ENGINE_JSC
#include <JavaScriptCore/JavaScriptCore.h>

#include "napi_env_jsc.h"
#endif

namespace vmsdk {
namespace runtime {
using RegisterWasmFuncType = void (*)(void *, void *);

enum JS_ENGINE_TYPE { QuickJS, JSCore, V8 };

class NAPIRuntime {
 public:
  virtual ~NAPIRuntime() {
    napi_detach_runtime(env_);
    napi_free_env(env_);
  }
  Napi::Env Env() { return env_; }
  virtual void SetRtInfo(const char *name) {}

  virtual void ExecutePendingJob() = 0;
  virtual void Init() {}

#if defined(OS_ANDROID)
  virtual std::shared_ptr<inspector_new::InspectorClient> GetInspectorClient() {
    return nullptr;
  }
#if defined(ENABLE_DEBUGGER)
  virtual void InitInspector(jobject inspector_client,
                             std::shared_ptr<runtime::TaskRunner> taskRunner) {
    VLOGE("Inspector not implement yet!");
  }
#endif
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  virtual void InitInspector(
      std::shared_ptr<vmsdk::devtool::iOS::VMSDKDebugICBase> inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) {
    VLOGE("Inspector not implement yet!");
  }
#endif

#if NAPI_ENABLE_WASM
  virtual void RegisterWebAssembly() {
    VLOGW("Calling RegisterWebAssembly, unimplemented parent function!");
  }
  static RegisterWasmFuncType &RegisterWasmFunc();
  static RegisterWasmFuncType register_wasm_func_;
#endif

 protected:
  napi_env env_;
  NAPIRuntime() {
    env_ = napi_new_env();
    napi_runtime_configuration runtime_conf =
        napi_create_runtime_configuration();
    napi_attach_runtime_with_configuration(env_, runtime_conf);
    napi_delete_runtime_configuration(runtime_conf);
  }
};

#ifdef JS_ENGINE_QJS

// Multi Context shared a common LEPUSRuntime
class CommonRuntimeQJS {
 public:
  static CommonRuntimeQJS *getInstance();
  virtual ~CommonRuntimeQJS() {}

  void freeRuntime();
  LEPUSRuntime *Runtime() { return qjs_runtime_; }

 private:
  static CommonRuntimeQJS *instance_;

  LEPUSRuntime *qjs_runtime_;
  CommonRuntimeQJS() {
    qjs_runtime_ = LEPUS_NewRuntime();
    LEPUS_SetRuntimeInfo(qjs_runtime_, "JSWorker");
  }
};

/**
 * Single Thread Mode
 * All worker run on a single thread
 * Every worker owns one QJS Context
 * All QJS Contexts shared a common QJS Runtime
 */
class NAPIRuntimeQJSSingleMode : public NAPIRuntime {
 public:
  NAPIRuntimeQJSSingleMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeQJSSingleMode()");
    // Shared a common quickjs runtime
    qjs_runtime_ = CommonRuntimeQJS::getInstance()->Runtime();

    // new quickjs context for every worker
    qjs_context_ = LEPUS_NewContext(qjs_runtime_);
    napi_attach_quickjs(env_, qjs_context_);

    ++context_count_;
  }

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  void InitInspector(jobject inspector_client,
                     std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));
      if (inspector_) {
        inspector_->QjsAttachRuntime(qjs_runtime_);
        inspector_->QjsContextCreated(qjs_context_);
      }
    }
  }
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  void InitInspector(
      std::shared_ptr<devtool::iOS::VMSDKDebugICBase> inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));
      if (inspector_) {
        inspector_->QjsAttachRuntime(qjs_runtime_);
        inspector_->QjsContextCreated(qjs_context_);
      }
    }
  }
#endif

  ~NAPIRuntimeQJSSingleMode() override {
#if defined(ENABLE_DEBUGGER)
    if (inspector_) {
      inspector_->QjsContextDestroyed();
      inspector_->QjsDetachRuntime();
    }
#endif
    napi_detach_quickjs(env_);
    LEPUS_FreeContext(qjs_context_);
    --context_count_;
    VLOGD("~NAPIRuntimeQJSSingleMode(), context_count_:%d", context_count_);
    if (context_count_ <= 0) {
      // this is the last Worker(or Context) instance to be free,
      // free the quickjs runtime
      CommonRuntimeQJS::getInstance()->freeRuntime();
    }
  }

  void ExecutePendingJob() override {
    LEPUSContext *context = qjs_context_;
    while (LEPUS_ExecutePendingJob(qjs_runtime_, &context) != 0) {
    }
  }

#if NAPI_ENABLE_WASM
  void RegisterWebAssembly() override {
    // register webassembly here, on ctx.global
    RegisterWasmFunc()(qjs_context_, nullptr);
  }
#endif

 protected:
#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  std::unique_ptr<devtool::Inspector> inspector_;
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  std::shared_ptr<devtool::Inspector> inspector_;
#endif

 private:
  // mark the count of Context(worker)
  static int context_count_;

  LEPUSRuntime *qjs_runtime_;
  LEPUSContext *qjs_context_;
};

/**
 * Multiple Thread Mode
 * Every worker run on a independent thread
 * Every worker owns a independent QJS Context
 * Every Context owns a independent QJS Runtime
 */
class NAPIRuntimeQJSMutiMode : public NAPIRuntime {
 public:
  NAPIRuntimeQJSMutiMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeQJSMutiMode()");
    qjs_runtime_ = LEPUS_NewRuntime();
    qjs_context_ = LEPUS_NewContext(qjs_runtime_);
    napi_attach_quickjs(env_, qjs_context_);
  }

  ~NAPIRuntimeQJSMutiMode() override {
#if defined(ENABLE_DEBUGGER)
    if (inspector_) {
      inspector_->QjsContextDestroyed();
      inspector_->QjsDetachRuntime();
    }
#endif
    napi_detach_quickjs(env_);
    LEPUS_FreeContext(qjs_context_);
    LEPUS_FreeRuntime(qjs_runtime_);
    VLOGD("~NAPIRuntimeQJSMutiMode()");
  }

  void ExecutePendingJob() override {
    LEPUSContext *context = qjs_context_;
    while (LEPUS_ExecutePendingJob(qjs_runtime_, &context) != 0) {
    }
  }
#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  void InitInspector(jobject inspector_client,
                     std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));

      if (inspector_) {
        inspector_->QjsAttachRuntime(qjs_runtime_);
        inspector_->QjsContextCreated(qjs_context_);
      }
    }
  }
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  void InitInspector(
      std::shared_ptr<vmsdk::devtool::iOS::VMSDKDebugICBase> inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));
      if (inspector_) {
        inspector_->QjsAttachRuntime(qjs_runtime_);
        inspector_->QjsContextCreated(qjs_context_);
      }
    }
  }
#endif

#if NAPI_ENABLE_WASM
  void RegisterWebAssembly() override {
    // register webassembly here, on ctx.global
    RegisterWasmFunc()(qjs_context_, nullptr);
  }
#endif

 protected:
#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  std::unique_ptr<devtool::Inspector> inspector_;
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  std::shared_ptr<devtool::Inspector> inspector_;
#endif

 private:
  LEPUSRuntime *qjs_runtime_;
  LEPUSContext *qjs_context_;
};
#endif  // JS_ENGINE_QJS

#ifdef JS_ENGINE_V8

// Multi Context shared a common V8 isolate
class CommonRuntimeV8 {
 public:
  static CommonRuntimeV8 *getInstance();
  virtual ~CommonRuntimeV8() {}

  void freeRuntime();

  v8::Isolate *isolate() { return isolate_; }

 private:
  CommonRuntimeV8() {
    v8::V8::InitializeICU();

    platform_ = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform_.get());
    v8::V8::Initialize();
    v8::Isolate::CreateParams create_params(platform_.get());
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    isolate_ = v8::Isolate::New(create_params);
    isolate_->Enter();
  }

  static CommonRuntimeV8 *instance_;
  std::unique_ptr<v8::Platform> platform_;
  v8::Isolate *isolate_;
};

/**
 * Single Thread Mode
 * All worker run on a single thread
 * Every worker owns one V8 Context
 * All V8 Contexts shared a common V8 Isolate
 */
class NAPIRuntimeV8SingleMode : public NAPIRuntime {
 public:
  NAPIRuntimeV8SingleMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeV8SingleMode()");
  }

  void Init() override {
    // Shared a common V8 isolate
    isolate_ = CommonRuntimeV8::getInstance()->isolate();

    // new V8 context for every worker
    v8::HandleScope handle_scope(isolate_);
    v8::Local<v8::Context> context = v8::Context::New(isolate_);
    context_.Reset(isolate_, context);
    context_.Get(isolate_)->Enter();
#if defined(OS_ANDROID)
    inspect_client_ =
        std::make_shared<inspector_new::V8InspectorClientImpl>(isolate_);
#endif
    napi_attach_v8(env_, context);
    ++context_count_;
  }

#if defined(OS_ANDROID)
  std::shared_ptr<inspector_new::InspectorClient> GetInspectorClient()
      override {
    return inspect_client_;
  }
#endif

  ~NAPIRuntimeV8SingleMode() override {
#if defined(ENABLE_DEBUGGER)
    if (inspector_) {
      v8::HandleScope handle_scope(isolate_);
      v8::Local<v8::Context> t_context =
          v8::Local<v8::Context>::New(isolate_, context_);
      v8::Context::Scope c_scope(t_context);

      inspector_->ContextDestroyed(t_context);
      inspector_->DetachIsolate(isolate_);
    }
#endif

#if defined(OS_ANDROID)
    inspect_client_.reset();
#endif
    napi_detach_v8(env_);
    --context_count_;

    if (!context_.IsEmpty()) {
      v8::HandleScope scoped_isolate(isolate_);
      v8::Local<v8::Context> context = context_.Get(isolate_);
      context->Exit();
      context_.Reset();
    }

    VLOGD("~NAPIRuntimeV8SingleMode(), context_count_:%d", context_count_);
    if (context_count_ <= 0) {
      // this is the last Worker(or Context) instance to be free,
      // free the V8 isolate
      CommonRuntimeV8::getInstance()->freeRuntime();
    }
  }

  void ExecutePendingJob() override { isolate_->RunMicrotasks(); }

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  void InitInspector(jobject inspector_client,
                     std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));

      if (inspector_) {
        v8::HandleScope hs(isolate_);
        v8::Local<v8::Context> t_context =
            v8::Local<v8::Context>::New(isolate_, context_);
        v8::Context::Scope c_scope(t_context);

        inspector_->AttachIsolate(isolate_);
        inspector_->ContextCreated(t_context);
      }
    }
  }
#endif

 protected:
#if defined(OS_ANDROID)
  std::shared_ptr<inspector_new::InspectorClient> inspect_client_;
#endif
#if defined(ENABLE_DEBUGGER)
  std::unique_ptr<devtool::Inspector> inspector_;
#endif

  // mark the count of Context(worker)
  static int context_count_;

  v8::Isolate *isolate_;
  v8::Persistent<v8::Context> context_;
};

/**
 * Multiple Thread Mode
 * Every worker run on a independent thread
 * Every worker owns a independent V8 Context
 * Every Context owns a independent V8 Isolate
 */
class NAPIRuntimeV8MultiMode : public NAPIRuntime {
 public:
  NAPIRuntimeV8MultiMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeV8MultiMode()");
  }
  void Init() override {
    static std::once_flag once_flag;
    static std::unique_ptr<v8::Platform> platform =
        v8::platform::NewDefaultPlatform();
    std::call_once(once_flag, []() {
      v8::V8::InitializeICU();
      v8::V8::InitializePlatform(platform.get());
      v8::V8::Initialize();
    });

    v8::Isolate::CreateParams create_params(platform.get());
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    isolate_ = v8::Isolate::New(create_params);
    isolate_->Enter();

    // new V8 context for every worker
    v8::HandleScope handle_scope(isolate_);
    v8::Local<v8::Context> context = v8::Context::New(isolate_);
    context_.Reset(isolate_, context);
    context_.Get(isolate_)->Enter();
#if defined(OS_ANDROID)
    inspect_client_ =
        std::make_shared<inspector_new::V8InspectorClientImpl>(isolate_);
#endif
    napi_attach_v8(env_, context);
  }

#if defined(OS_ANDROID)
  std::shared_ptr<inspector_new::InspectorClient> GetInspectorClient()
      override {
    return inspect_client_;
  }
#endif

  ~NAPIRuntimeV8MultiMode() override {
    VLOGD("~NAPIRuntimeV8MultiMode()");
#if defined(ENABLE_DEBUGGER)
    if (inspector_) {
      v8::HandleScope handle_scope(isolate_);
      v8::Local<v8::Context> t_context =
          v8::Local<v8::Context>::New(isolate_, context_);
      v8::Context::Scope c_scope(t_context);

      inspector_->ContextDestroyed(t_context);
      inspector_->DetachIsolate(isolate_);
    }
#endif

#if defined(OS_ANDROID)
    inspect_client_.reset();
#endif
    napi_detach_v8(env_);
    if (!context_.IsEmpty()) {
      v8::HandleScope scoped_isolate(isolate_);
      v8::Local<v8::Context> context = context_.Get(isolate_);
      context->Exit();
      context_.Reset();
    }
    if (isolate_) {
      isolate_->Exit();
      isolate_->Dispose();
      isolate_ = nullptr;
    }
  }

  void ExecutePendingJob() override { isolate_->RunMicrotasks(); }

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  void InitInspector(jobject inspector_client,
                     std::shared_ptr<runtime::TaskRunner> taskRunner) override {
    if (inspector_) {
      return;
    }
    if (devtool::InspectorFactory::GetInstance()) {
      inspector_ = devtool::InspectorFactory::GetInstance()->Create(
          inspector_client, std::move(taskRunner));

      if (inspector_) {
        v8::HandleScope hs(isolate_);
        v8::Local<v8::Context> t_context =
            v8::Local<v8::Context>::New(isolate_, context_);
        v8::Context::Scope c_scope(t_context);

        inspector_->AttachIsolate(isolate_);
        inspector_->ContextCreated(t_context);
      }
    }
  }
#endif

 private:
  v8::Isolate *isolate_;
  v8::Persistent<v8::Context> context_;

#if defined(OS_ANDROID)
  std::shared_ptr<inspector_new::InspectorClient> inspect_client_;
#endif
#if defined(ENABLE_DEBUGGER)
  std::unique_ptr<devtool::Inspector> inspector_;
#endif
};

#endif  // JS_ENGINE_V8

#ifdef JS_ENGINE_JSC

class CommonRuntimeJSC {
 public:
  static CommonRuntimeJSC *getInstance();
  virtual ~CommonRuntimeJSC() {}

  void freeRuntime();

  JSContextGroupRef contextGroup() { return context_group_; }

 private:
  CommonRuntimeJSC() { context_group_ = JSContextGroupCreate(); }

  static CommonRuntimeJSC *instance_;
  JSContextGroupRef context_group_;
};

/**
 * Single Thread Mode
 * All worker run on a single thread
 * Every worker owns one JSC context_group
 * All V8 Contexts shared a common JSC global_context
 */
class NAPIRuntimeJSCSingleMode : public NAPIRuntime {
 public:
  NAPIRuntimeJSCSingleMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeJSCSingleMode()");
    // Shared a common JSC contextGroup
    context_group_ = CommonRuntimeJSC::getInstance()->contextGroup();
    // new JSC context for every worker
    global_context_ = JSGlobalContextCreateInGroup(context_group_, nullptr);

    napi_attach_jsc(env_, global_context_);
    ++context_count_;
  }

  ~NAPIRuntimeJSCSingleMode() override {
    napi_detach_jsc(env_);
    JSGlobalContextRelease(global_context_);

    --context_count_;

    VLOGD("NAPIRuntimeJSCSingleMode(), context_count_:%d", context_count_);
    if (context_count_ <= 0) {
      // this is the last Worker(or Context) instance to be free,
      // free the JSC runtime
      CommonRuntimeJSC::getInstance()->freeRuntime();
    }
  }

  void ExecutePendingJob() override {
    // todo
  }

  void SetRtInfo(const char *info) override {
    JSStringRef name_ref = JSStringCreateWithUTF8CString(info);
    JSGlobalContextSetName(global_context_, name_ref);
  }

 private:
  // mark the count of Context(worker)
  static int context_count_;

  JSContextGroupRef context_group_;
  JSGlobalContextRef global_context_;
};

/**
 * Multiple Thread Mode
 * Every worker run on a independent thread
 * Every worker owns a independent JSC context_group
 * Every Context owns a independent JSC global_context
 */
class NAPIRuntimeJSCMultiMode : public NAPIRuntime {
 public:
  NAPIRuntimeJSCMultiMode() : NAPIRuntime() {
    VLOGD("new NAPIRuntimeJSCMultiMode()");
    // new JSC ContextGroup for every worker
    context_group_ = JSContextGroupCreate();
    ;
    // new JSC context for every worker
    global_context_ = JSGlobalContextCreateInGroup(context_group_, nullptr);

    napi_attach_jsc(env_, global_context_);
  }

  ~NAPIRuntimeJSCMultiMode() override {
    VLOGD("~NAPIRuntimeJSCMultiMode()");
    napi_detach_jsc(env_);
    JSGlobalContextRelease(global_context_);
    JSContextGroupRelease(context_group_);
  }

  void ExecutePendingJob() override {}

  void SetRtInfo(const char *info) override {
    JSStringRef name_ref = JSStringCreateWithUTF8CString(info);
    JSGlobalContextSetName(global_context_, name_ref);
  }

 private:
  JSContextGroupRef context_group_;
  JSGlobalContextRef global_context_;
};
#endif  // JS_ENGINE_JSC

class NAPIRuntimeFactory {
 public:
  ~NAPIRuntimeFactory() {}

  NAPIRuntimeFactory(const NAPIRuntimeFactory &) = delete;
  NAPIRuntimeFactory &operator=(const NAPIRuntimeFactory &) = delete;

  static NAPIRuntimeFactory *getInstance() {
    static NAPIRuntimeFactory *instance = new NAPIRuntimeFactory();
    return instance;
  }

  std::unique_ptr<NAPIRuntime> createRuntime(JS_ENGINE_TYPE engine_type,
                                             bool is_multi_thread_mode) {
    switch (engine_type) {
#ifdef JS_ENGINE_QJS
      case QuickJS:
        if (is_multi_thread_mode) {
          return std::make_unique<NAPIRuntimeQJSMutiMode>();
        } else {
          return std::make_unique<NAPIRuntimeQJSSingleMode>();
        }

#endif  // JS_ENGINE_QJS
#ifdef JS_ENGINE_JSC
      case JSCore:
        if (is_multi_thread_mode) {
          return std::make_unique<NAPIRuntimeJSCMultiMode>();
        } else {
          return std::make_unique<NAPIRuntimeJSCSingleMode>();
        }
#endif
#ifdef JS_ENGINE_V8
      case V8:
        if (is_multi_thread_mode) {
          return std::make_unique<NAPIRuntimeV8MultiMode>();
        } else {
          return std::make_unique<NAPIRuntimeV8SingleMode>();
        }
#endif
      default:
        if (is_multi_thread_mode) {
          return std::make_unique<NAPIRuntimeQJSMutiMode>();
        } else {
          return std::make_unique<NAPIRuntimeQJSSingleMode>();
        }
    }
  }

 protected:
  NAPIRuntimeFactory() {}

 private:
};

}  // namespace runtime
}  // namespace vmsdk
#endif  // NAPI_RUNTIME_WRAPER_H_
