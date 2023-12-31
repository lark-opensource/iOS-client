#include "jsb/runtime/napi_runtime_wraper.h"

namespace vmsdk {
namespace runtime {

#ifdef JS_ENGINE_QJS
CommonRuntimeQJS* CommonRuntimeQJS::instance_ = nullptr;

CommonRuntimeQJS* CommonRuntimeQJS::getInstance() {
  // single JS thread
  if (instance_ == nullptr) {
    instance_ = new CommonRuntimeQJS();
  }
  return instance_;
}

void CommonRuntimeQJS::freeRuntime() {
  VLOGD("CommonRuntimeQJS()::freeRuntime");
  if (qjs_runtime_) {
    LEPUS_FreeRuntime(qjs_runtime_);
    qjs_runtime_ = nullptr;
  }
  // if last context freed. delete instance_
  if (instance_) {
    delete instance_;
    instance_ = nullptr;
  }
}

int NAPIRuntimeQJSSingleMode::context_count_ = 0;

#endif  // JS_ENGINE_QJS

#ifdef JS_ENGINE_V8
CommonRuntimeV8* CommonRuntimeV8::instance_ = nullptr;

CommonRuntimeV8* CommonRuntimeV8::getInstance() {
  // v8 context & v8 isolate must created on same thread
  if (instance_ == nullptr) {
    instance_ = new CommonRuntimeV8();
  }
  return instance_;
}

void CommonRuntimeV8::freeRuntime() {
  VLOGD("CommonRuntimeV8()::freeRuntime");
  if (isolate_) {
    isolate_->Exit();
    isolate_->Dispose();
    isolate_ = nullptr;
  }

  if (instance_) {
    instance_ = nullptr;
  }
}

int NAPIRuntimeV8SingleMode::context_count_ = 0;

#endif  // JS_ENGINE_V8

#ifdef JS_ENGINE_JSC
CommonRuntimeJSC* CommonRuntimeJSC::instance_ = nullptr;

CommonRuntimeJSC* CommonRuntimeJSC::getInstance() {
  // JSCore global_context & contextGroup must created on same thread
  if (instance_ == nullptr) {
    instance_ = new CommonRuntimeJSC();
  }
  return instance_;
}

void CommonRuntimeJSC::freeRuntime() {
  VLOGD("CommonRuntimeJSC()::freeRuntime");
  if (context_group_) {
    JSContextGroupRelease(context_group_);
    context_group_ = NULL;
  }

  if (instance_) {
    instance_ = nullptr;
  }
}

int NAPIRuntimeJSCSingleMode::context_count_ = 0;

#endif  // JS_ENGINE_JSC

#if NAPI_ENABLE_WASM
// static
RegisterWasmFuncType NAPIRuntime::register_wasm_func_ = [](void*, void*) {};

// static
RegisterWasmFuncType& NAPIRuntime::RegisterWasmFunc() {
  // singleton
  static RegisterWasmFuncType RegisterWebAssembly = register_wasm_func_;
  return RegisterWebAssembly;
}
#endif

}  // namespace runtime
}  // namespace vmsdk
