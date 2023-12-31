#include "jsbridge/jsc/jsc_context_wrapper_impl.h"

#include <JavaScriptCore/JavaScript.h>

#include <memory>
#include <unordered_map>

#include "base/log/logging.h"
#include "jsbridge/jsc/jsc_context_group_wrapper_impl.h"
#include "jsbridge/jsc/jsc_helper.h"
#include "jsbridge/jsi/jsi.h"
#include "tasm/config.h"

namespace lynx {
namespace piper {

JSCContextWrapperImpl::JSCContextWrapperImpl(std::shared_ptr<VMInstance> vm)
    : JSCContextWrapper(vm),
      ctx_invalid_(false),
      is_auto_create_group_(false),
      objectCounter_(0) {}

void JSCContextWrapperImpl::init() {
  JSContextGroupRef jsc_context_group = nullptr;

  std::shared_ptr<JSCContextGroupWrapperImpl> context_group_wrapper =
      std::static_pointer_cast<JSCContextGroupWrapperImpl>(vm_);
  if (context_group_wrapper && context_group_wrapper->GetContextGroup()) {
    jsc_context_group = context_group_wrapper->GetContextGroup();
  }
  if (jsc_context_group) {
    ctx_ = JSGlobalContextCreateInGroup(jsc_context_group, nullptr);
  } else {
    LOGI("~JSCContextWrapperImpl auto create jscontext group" << this);
    jsc_context_group = JSContextGroupCreate();
    ctx_ = JSGlobalContextCreateInGroup(jsc_context_group, nullptr);
    is_auto_create_group_ = true;
  }
  // register webassembly here, on ctx.global
  RegisterWasmFunc()(ctx_, &ctx_invalid_);
  auto name = JSStringCreateWithUTF8CString("Lynx");
  JSGlobalContextSetName(ctx_, name);
  JSStringRelease(name);
}

JSCContextWrapperImpl::~JSCContextWrapperImpl() {
  ctx_invalid_ = true;

  // remove all global object
  JSObjectRef global = JSContextGetGlobalObject(ctx_);
  JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx_, global);
  size_t count = JSPropertyNameArrayGetCount(names);
  for (size_t i = 0; i < count; i++) {
    JSStringRef name = JSPropertyNameArrayGetNameAtIndex(names, i);
    JSObjectDeleteProperty(ctx_, global, name, nullptr);
  }
  // get jscontext group
  JSContextGroupRef group = JSContextGetGroup(ctx_);
  if (group != nullptr && is_auto_create_group_) {
    LOGI("~JSCContextWrapperImpl release group" << this);
    JSGlobalContextRelease(ctx_);
    JSContextGroupRelease(group);
  } else {
    JSGlobalContextRelease(ctx_);
  }

#ifdef DEBUG
  // assert(objectCounter_ == 0 &&
  //       "JSCRuntime destroyed with a dangling API object");
  if (objectCounter_ != 0) {
    LOGE("Error: " << __FILE__ << ":" << __LINE__ << ":"
                   << "JSCRuntime destroyed with a dangling API object");
    //  abort();  // for  douyin, 'assert' is invalid
  }

#endif

  LOGI("~JSCContextWrapper " << this);
}

const std::atomic<bool>& JSCContextWrapperImpl::contextInvalid() const {
  return ctx_invalid_;
}

std::atomic<intptr_t>& JSCContextWrapperImpl::objectCounter() const {
  return objectCounter_;
}

JSGlobalContextRef JSCContextWrapperImpl::getContext() const { return ctx_; }

// static
RegisterWasmFuncType JSCContextWrapperImpl::register_wasm_func_ = [](void*,
                                                                     void*) {};
// static
RegisterWasmFuncType& JSCContextWrapperImpl::RegisterWasmFunc() {
  static RegisterWasmFuncType RegisterWebAssembly = register_wasm_func_;
  return RegisterWebAssembly;
}

}  // namespace piper
}  // namespace lynx
