// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_wasm_memory.h"

#include "common/messages.h"
#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "jsc_builtin_objects.h"
#include "jsc_class_creator.h"
#include "jsc_ext_api.h"
#include "runtime/wasm_memory.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
using vmsdk::ExceptionMessages;
namespace jsc {
JSCWasmMemory::~JSCWasmMemory() { delete memory_; }
// static
void JSCWasmMemory::Finalize(JSObjectRef object) {
  JSCWasmMemory* memory =
      static_cast<JSCWasmMemory*>(JSObjectGetPrivate(object));
  if (memory) {
    delete memory;
  }
}

// static
JSObjectRef JSCWasmMemory::CreateJSObject(JSContextRef ctx,
                                          JSObjectRef constructor,
                                          WasmMemory* memory, size_t pages,
                                          JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Memory", Finalize);
  JSClassRef obj_jsclass = JSClassCreate(&def);
  JSCWasmMemory* memory_data = new JSCWasmMemory(memory, pages);
  JSObjectRef obj = JSObjectMake(ctx, obj_jsclass, memory_data);

  JSValueRef maybe_prototype = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);
  JSObjectRef prototype = JSValueToObject(ctx, maybe_prototype, exception);

  JSObjectSetPrototype(ctx, obj, prototype);

  return obj;
}

// static
JSObjectRef JSCWasmMemory::CallAsConstructor(JSContextRef ctx,
                                             JSObjectRef constructor,
                                             size_t argumentCount,
                                             const JSValueRef arguments[],
                                             JSValueRef* exception) {
  WLOGI("JSCWasmMemory::CallAsConstructor @ %s\n", __func__);

  if (argumentCount == 0 || !JSValueIsObject(ctx, arguments[0])) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kDescriptorNeeded);
    return nullptr;
  }

  JSObjectRef memory_descriptor = nullptr;
  { memory_descriptor = JSValueToObject(ctx, arguments[0], exception); }

  uint32_t initial_page_count = 0;
  {
    JSValueRef initial = JSObjectGetProperty(
        ctx, memory_descriptor, JSStringCreateWithUTF8CString("initial"),
        exception);
    if (exception && *exception) return nullptr;
    initial_page_count =
        static_cast<uint32_t>(JSValueToNumber(ctx, initial, exception));
    if (exception && *exception) return nullptr;
    // TODO(zode): initial out of range?
  }

  uint32_t maximum_page_count = kMaxPagesNum;
  {
    JSValueRef maximum = JSObjectGetProperty(
        ctx, memory_descriptor, JSStringCreateWithUTF8CString("maximum"),
        exception);
    if (exception && *exception) return nullptr;
    if (!JSValueIsUndefined(ctx, maximum)) {
      maximum_page_count =
          static_cast<uint32_t>(JSValueToNumber(ctx, maximum, exception));

      if (initial_page_count > maximum_page_count) {
        if (exception)
          *exception = JSCExtAPI::CreateException(
              ctx, ExceptionMessages::kInvalidMemoryLimits);
        return nullptr;
      }
    }
  }

  // TODO(zode): If shared memory

  WasmRuntime* wasm_rt =
      reinterpret_cast<WasmRuntime*>(JSObjectGetPrivate(constructor));
  WasmMemory* memory =
      wasm_rt->CreateWasmMemory(initial_page_count, maximum_page_count);

  if (memory == nullptr) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kMemoryAllocFailed);
    return nullptr;
  }
  return CreateJSObject(ctx, constructor, memory, initial_page_count,
                        exception);
}

// static
JSObjectRef JSCWasmMemory::CreatePrototype(JSContextRef ctx,
                                           JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Memory.Prototype", NULL);

  JSPropertyAttributes default_attr = JSClassCreator::DefaultAttr();

  JSStaticFunction static_funcs[] = {{"grow", GrowCallback, default_attr},
                                     {0, 0, 0}};
  def.staticFunctions = static_funcs;
  JSClassRef prototype_jsclass = JSClassCreate(&def);

  JSObjectRef prototype = JSObjectMake(ctx, prototype_jsclass, NULL);

  property_descriptor instance_values[] = {
      {"buffer", GetBufferCallback, 0, prop_none}, {0, 0, 0, prop_none}};
  JSCExtAPI::DefineProperties(ctx, prototype, instance_values, exception);

  return prototype;
}

// static
JSObjectRef JSCWasmMemory::CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                             JSValueRef* exception) {
  JSClassDefinition def = JSClassCreator::GetClassDefinition(
      "WebAssembly.Memory", NULL, CallAsConstructor);
  JSClassRef ctor_jsclass = JSClassCreate(&def);

  JSObjectRef ctor = JSObjectMake(ctx, ctor_jsclass, rt);

  JSObjectRef prototype = CreatePrototype(ctx, exception);
  JSCExtAPI::InitConstructor(ctx, ctor, "Memory", prototype, exception);

  JS_ENV* env = rt->GetJSEnv();
  if (wasm_likely(env)) {
    env->SetMemoryContructor(ctor);
  }
  return ctor;
}

// static
JSValueRef JSCWasmMemory::GetBufferCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  JSCWasmMemory* jsc_memory =
      static_cast<JSCWasmMemory*>(JSObjectGetPrivate(thisObject));
  if (!jsc_memory) {
    WLOGI(
        "No valid private data found in WebAssembly.Memory, this is illegal.");
    return nullptr;
  }

  // NOTE:
  // When pages_ != memory->memory_->pages(), it backing wasm memory
  // is updated actually, we must provide a new buffer and detach the
  // old one.
  if (__builtin_available(macos 10.12, ios 10.0, *)) {
    if (jsc_memory->buffer_ == nullptr ||
        jsc_memory->pages_ != jsc_memory->memory_->pages()) {
      // Reasonably speaking, the old buffer must be make detached here,
      // but actually no operation will be taken given that no such
      // interface is provided by JavaScriptCore,
      JSValueUnprotect(ctx, jsc_memory->buffer_);

      WasmMemory* wasm_memory = jsc_memory->memory_;
      void* buffer = wasm_memory->buffer();

      if (buffer == nullptr) {
        // This is a trick to persuade JSC to create an ArrayBuffer
        // with zero length and no valid backing store.
        // Otherwise JSC always create a detached ArrayBuffer
        // as the pointer of its backing store is nullptr.
        buffer = static_cast<void*>(&(jsc_memory->pages_));
      }

      jsc_memory->pages_ = jsc_memory->memory_->pages();
      size_t buffer_size = jsc_memory->pages_ * WasmMemory::kWasmPageSize;

      jsc_memory->buffer_ = JSObjectMakeArrayBufferWithBytesNoCopy(
          ctx, buffer, buffer_size, nullptr, nullptr, exception);
      JSValueProtect(ctx, jsc_memory->buffer_);
    }
  } else {
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kOSVersionUnsupported);
  }
  return jsc_memory->buffer_;
}

// static
JSValueRef JSCWasmMemory::GrowCallback(JSContextRef ctx, JSObjectRef function,
                                       JSObjectRef thisObject,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception) {
  WLOGD("memory.grow @ %s\n", __func__);
  JSCWasmMemory* memory =
      static_cast<JSCWasmMemory*>(JSObjectGetPrivate(thisObject));
  if (!memory || !memory->memory_ || argumentCount < 1) {
    WLOGD("memory.grow with invalid arguments!\n");
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kGrowWithInvalidArgs);
    return JSValueMakeUndefined(ctx);
  }
  size_t grow_pages = 0;
  JSValueRef num_obj = arguments[0];
  if (JSValueIsNumber(ctx, num_obj)) {
    grow_pages = JSValueToNumber(ctx, num_obj, exception);
  } else {
    WLOGD("memory.grow with invalid arguments!\n");
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kGrowWithInvalidArgs);
    return JSValueMakeUndefined(ctx);
  }

  // grow the memory size
  size_t pages = memory->memory_->pages();
  if (grow_pages == 0 || memory->memory_->grow(grow_pages)) {
    return JSValueMakeNumber(ctx, pages);
  }
  if (exception) {
    WLOGD("Runtime.GrowTable failed!\n");
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kGrowFailed);
  }
  return nullptr;
}

}  // namespace jsc
}  // namespace vmsdk