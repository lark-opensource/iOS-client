#ifndef LYNX_JSBRIDGE_JSC_JSC_CONTEXT_WRAPPER_IMPL_H_
#define LYNX_JSBRIDGE_JSC_JSC_CONTEXT_WRAPPER_IMPL_H_

#include <memory>

#include "jsbridge/jsc/jsc_context_wrapper.h"

namespace lynx {
namespace piper {
using RegisterWasmFuncType = void (*)(void*, void*);

class JSCContextWrapperImpl : public JSCContextWrapper {
 public:
  JSCContextWrapperImpl(std::shared_ptr<VMInstance> vm);
  ~JSCContextWrapperImpl() override;
  void init() override;

  const std::atomic<bool>& contextInvalid() const override;
  std::atomic<intptr_t>& objectCounter() const override;

  JSGlobalContextRef getContext() const override;

  static RegisterWasmFuncType& RegisterWasmFunc();

  static RegisterWasmFuncType register_wasm_func_;

 private:
  JSGlobalContextRef ctx_;
  std::atomic<bool> ctx_invalid_;
  std::atomic<bool> is_auto_create_group_;
  mutable std::atomic<intptr_t> objectCounter_;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_CONTEXT_WRAPPER_IMPL_H_
