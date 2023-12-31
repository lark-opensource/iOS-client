
#include "jsbridge/bindings/global.h"

#include <memory>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "jsbridge/bindings/big_int/jsbi.h"
#include "jsbridge/bindings/console.h"
#include "jsbridge/bindings/console_message_postman.h"
#include "jsbridge/bindings/system_info.h"

namespace lynx {
namespace piper {

Global::~Global() { LOGI("lynx ~Global()"); }

void Global::Init(std::shared_ptr<Runtime>& runtime,
                  std::shared_ptr<piper::ConsoleMessagePostMan>& post_man) {
  SetJSRuntime(runtime);
  auto js_runtime_ = GetJSRuntime();
  if (!js_runtime_) {
    return;
  }

  Scope scope(*js_runtime_);

  piper::Object global = js_runtime_->global();
  Object console_obj = Object::createFromHostObject(
      *js_runtime_, std::make_shared<Console>(js_runtime_.get(), post_man));
  global.setProperty(*js_runtime_, "nativeConsole", console_obj);

  Object system_info_obj = Object::createFromHostObject(
      *js_runtime_, std::make_shared<SystemInfo>());
  global.setProperty(*js_runtime_, "SystemInfo", system_info_obj);

  Object jsbi_obj =
      Object::createFromHostObject(*js_runtime_, std::make_shared<JSBI>());
  global.setProperty(*js_runtime_, "LynxJSBI", jsbi_obj);

  if (base::LynxEnv::GetInstance().IsDevtoolEnabled()) {
    auto& group_id = js_runtime_->getGroupId();
    global.setProperty(*js_runtime_, "groupId", group_id);
  }
}

void Global::EnsureConsole(
    std::shared_ptr<piper::ConsoleMessagePostMan>& post_man) {
  auto js_runtime = GetJSRuntime();
  if (!js_runtime) {
    return;
  }
  Scope scope(*js_runtime);
  piper::Object global = js_runtime->global();
  auto console = global.getProperty(*js_runtime, "console");
  if (console && !console->isObject()) {
    Object console_obj = Object::createFromHostObject(
        *js_runtime, std::make_shared<Console>(js_runtime.get(), post_man));
    global.setProperty(*js_runtime, "console", console_obj);
  }
}

void Global::Release() { LOGI("lynx Global::Release"); }

void SharedContextGlobal::SetJSRuntime(std::shared_ptr<Runtime> js_runtime) {
  js_runtime_ = js_runtime;
}

std::shared_ptr<Runtime> SharedContextGlobal::GetJSRuntime() {
  return js_runtime_;
}

void SharedContextGlobal::Release() { js_runtime_.reset(); }

SingleGlobal::~SingleGlobal() { LOGI("lynx ~SingleGlobal"); }

void SingleGlobal::SetJSRuntime(std::shared_ptr<Runtime> js_runtime) {
  js_runtime_ = js_runtime;
}

std::shared_ptr<Runtime> SingleGlobal::GetJSRuntime() {
  return js_runtime_.lock();
}

void SingleGlobal::Release() {}

}  // namespace piper
}  // namespace lynx
