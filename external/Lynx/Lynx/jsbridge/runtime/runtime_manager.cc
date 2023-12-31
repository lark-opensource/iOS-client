#include "jsbridge/runtime/runtime_manager.h"

#include <memory>
#include <string>
#include <unordered_map>

#include "base/log/logging.h"
#include "jsbridge/bindings/global.h"
#include "jsbridge/js_executor.h"
#include "jsbridge/jsi/jsi.h"
#include "tasm/config.h"

namespace lynx {
namespace runtime {

bool RuntimeManager::IsSingleJSContext(const std::string& group_id) {
  return group_id == "-1";
}

std::shared_ptr<piper::Runtime> RuntimeManager::CreateJSRuntime(
    const std::string& group_id,
    std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
    std::vector<std::pair<std::string, std::string>>& js_pre_sources,
    bool force_use_lightweight_js_engine,
    std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
    bool ensure_console) {
  std::shared_ptr<piper::Runtime> js_runtime;
  bool need_create_vm = false;

  if (IsSingleJSContext(group_id)) {
    js_runtime = MakeRuntime(force_use_lightweight_js_engine);
    js_runtime->setRuntimeId(rt_id);

    CreateJSContextResult result = CreateJSContext(js_runtime, false);
    need_create_vm = result.first;
    std::shared_ptr<piper::JSIContext> js_context = result.second;

    LOGI("GetSharedJSContext : create none shared jscontext!: "
         << js_context.get());
    EnsureConsolePostMan(js_context, executor);
    js_runtime->InitRuntime(js_context, exception_handler);

    auto context_wrapper =
        std::make_shared<NoneSharedJSContextWrapper>(js_context, this);
    js_context->SetReleaseObserver(context_wrapper);
    context_wrapper->initGlobal(js_runtime, js_context->GetPostMan());
    if (ensure_console) {
      context_wrapper->EnsureConsole(js_context->GetPostMan());
    }

    context_wrapper->loadPreJS(js_runtime, js_pre_sources);

    InitJSRuntimeCreatedType(need_create_vm, js_runtime);
  } else {
    std::shared_ptr<piper::JSIContext> js_context = GetSharedJSContext(
        executor->CreateConsoleMessagePostMan(), group_id, ensure_console);
    if (js_context) {
      EnsureConsolePostMan(js_context, executor);

      auto vm = js_context->getVM();
      if (vm) {
        // page need shared context with same lynx group id, js runtime must be
        // create with the type from js context different js runtime type using
        // shared context will cause crash. here we change the
        // force_use_lightweight_js_engine param for MakeRuntime to control the
        // runtime type.
        if (vm->GetRuntimeType() == piper::v8) {
          if (force_use_lightweight_js_engine) {
            LOGI(
                "use shared jscontext with v8, change "
                "force_use_lightweight_js_engine to false");
            force_use_lightweight_js_engine = false;
          } else {
            LOGI("use shared jscontext");
          }
        } else {
          if (!force_use_lightweight_js_engine) {
            LOGI(
                "use shared jscontext with none-v8, change "
                "force_use_lightweight_js_engine to true");
            force_use_lightweight_js_engine = true;
          } else {
            LOGI("use shared jscontext");
          }
        }
      } else {
        DCHECK(false);
      }
      js_runtime = MakeRuntime(force_use_lightweight_js_engine);
      js_runtime->setRuntimeId(rt_id);

      js_runtime->InitRuntime(js_context, exception_handler);
      js_runtime->setCreatedType(
          piper::JSRuntimeCreatedType::none_vm_none_context);
    } else {
      js_runtime = MakeRuntime(force_use_lightweight_js_engine);
      js_runtime->setRuntimeId(rt_id);

      CreateJSContextResult result = CreateJSContext(js_runtime, false);
      need_create_vm = result.first;
      js_context = result.second;

      LOGI(" : create shared jscontext!: " << js_context.get()
                                           << " group: " << group_id);

      EnsureConsolePostMan(js_context, executor);
      js_runtime->InitRuntime(js_context, exception_handler);

      auto context_wrapper =
          std::make_shared<SharedJSContextWrapper>(js_context, group_id, this);
      js_context->SetReleaseObserver(context_wrapper);
      auto global_runtime = MakeRuntime(force_use_lightweight_js_engine);
      // FIXME(heshan):now set exception_handler to global runtime, not
      // correct...
      global_runtime->InitRuntime(js_context, exception_handler);

      context_wrapper->initGlobal(global_runtime, js_context->GetPostMan());
      if (ensure_console) {
        context_wrapper->EnsureConsole(js_context->GetPostMan());
      }
      context_wrapper->loadPreJS(js_runtime, js_pre_sources);

      shared_context_map_.insert(std::make_pair(group_id, context_wrapper));

      InitJSRuntimeCreatedType(need_create_vm, js_runtime);
    }
  }
  return js_runtime;
}

void RuntimeManager::OnRelease(const std::string& group_id) {
  auto it = shared_context_map_.find(group_id);
  if (it != shared_context_map_.end()) {
    LOGI("RuntimeManager remove context:" << group_id);
    shared_context_map_.erase(it);
  } else {
    LOGI("RuntimeManager::OnRelease : not find shared jscontext in group:"
         << group_id << " It may has been released in global runtime.");
  }
}

void RuntimeManager::OnVMUnref(piper::JSRuntimeType runtime_type) {
  if (runtime_type != piper::jsc) {
    return;
  }
  if (vm_container_ref_count_[runtime_type] > 0) {
    vm_container_ref_count_[runtime_type]--;
  } else if (vm_container_ref_count_[runtime_type] == 0) {
    for ([[maybe_unused]] const auto& [key, context] : shared_context_map_) {
      if (context->isSharedVM()) {
        return;
      }
    }
    auto iter = mVMContainer_.find(runtime_type);
    if (iter != mVMContainer_.end()) {
      mVMContainer_.erase(iter);
    }
  }
}

std::shared_ptr<piper::JSIContext> RuntimeManager::GetSharedJSContext(
    std::shared_ptr<piper::ConsoleMessagePostMan> post_man,
    const std::string& group_id, bool ensure_console) {
  if (shared_context_map_.find(group_id) == shared_context_map_.end()) {
    return std::shared_ptr<piper::JSIContext>(nullptr);
  }

  auto context_wrapper = shared_context_map_[group_id];
  if (ensure_console) {
    context_wrapper->EnsureConsole(post_man);
  }

  auto js_context = context_wrapper->getJSContext();

  // TODO: check !js_context

  return js_context;
}

CreateJSContextResult RuntimeManager::CreateJSContext(
    std::shared_ptr<piper::Runtime>& rt, bool shared_vm) {
  if (rt->type() == piper::jsc && !shared_vm) {
    return std::make_pair(true, rt->createContext(nullptr));
  } else {
    bool need_create_vm = EnsureVM(rt);
    auto context = rt->createContext(mVMContainer_[rt->type()]);
    if (context != nullptr) {
      vm_container_ref_count_[rt->type()]++;
    }
    return std::make_pair(need_create_vm, context);
  }
}

void RuntimeManager::InitJSRuntimeCreatedType(
    bool need_create_vm, std::shared_ptr<piper::Runtime>& rt) {
  piper::JSRuntimeCreatedType type =
      need_create_vm ? piper::JSRuntimeCreatedType::vm_context
                     : piper::JSRuntimeCreatedType::context;
  rt->setCreatedType(type);
}

bool RuntimeManager::EnsureVM(std::shared_ptr<piper::Runtime>& rt) {
  if (mVMContainer_.find(rt->type()) == mVMContainer_.end()) {
    piper::StartupData* data = nullptr;

    mVMContainer_.insert(std::make_pair(rt->type(), rt->createVM(data)));
    if (data != nullptr) {
      delete data;
      data = nullptr;
    }
    return true;
  }
  return false;
}

void RuntimeManager::EnsureConsolePostMan(
    std::shared_ptr<piper::JSIContext>& context,
    std::shared_ptr<piper::JSExecutor>& executor) {
  if (context != nullptr && executor != nullptr) {
    if (context->GetPostMan() == nullptr) {
      context->SetPostMan(executor->CreateConsoleMessagePostMan());
    }
    auto postman = context->GetPostMan();
    if (postman != nullptr) {
      postman->InsertRuntimeObserver(executor->getRuntimeObserver());
    }
  }
}

}  // namespace runtime
}  // namespace lynx
