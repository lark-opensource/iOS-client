#include "jsbridge/jsc/jsc_context_group_wrapper_impl.h"

#include "base/log/logging.h"
#include "tasm/config.h"

namespace lynx {
namespace piper {

JSCContextGroupWrapperImpl::JSCContextGroupWrapperImpl()
    : JSCContextGroupWrapper() {}

JSCContextGroupWrapperImpl::~JSCContextGroupWrapperImpl() {
  LOGI("~JSCContextGroupWrapperImpl " << this);
  if (group_ != nullptr) {
    LOGI("JSContextGroupRelease");
    JSContextGroupRelease(group_);
  }
}

void JSCContextGroupWrapperImpl::InitContextGroup() {
  LOGI("JSContextGroupCreate");
  group_ = JSContextGroupCreate();
}

}  // namespace piper
}  // namespace lynx
