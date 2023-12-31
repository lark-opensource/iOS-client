#ifndef LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_IMPL_H_
#define LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_IMPL_H_

#include "jsbridge/jsc/jsc_context_group_wrapper.h"

namespace lynx {
namespace piper {
class JSCContextGroupWrapperImpl : public JSCContextGroupWrapper {
 public:
  JSCContextGroupWrapperImpl();
  ~JSCContextGroupWrapperImpl() override;
  void InitContextGroup() override;
  inline JSContextGroupRef GetContextGroup() { return group_; }

 private:
  JSContextGroupRef group_;
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_IMPL_H_
