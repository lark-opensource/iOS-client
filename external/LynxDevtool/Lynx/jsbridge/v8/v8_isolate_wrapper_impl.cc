#include "jsbridge/v8/v8_isolate_wrapper_impl.h"

#include <memory>
#include <mutex>
#include <string>

#include "base/log/logging.h"
#include "libplatform/libplatform.h"
#if defined(OS_WIN)
#include "base/paths_win.h"
#include "base/string/string_conversion_win.h"
#endif

namespace lynx {
namespace piper {

V8IsolateInstanceImpl::V8IsolateInstanceImpl() = default;

V8IsolateInstanceImpl::~V8IsolateInstanceImpl() {
  if (isolate_ != nullptr) {
    isolate_->Dispose();
    LOGI("lynx ~V8IsolateInstance");
  }
}

std::once_flag flag;
void V8IsolateInstanceImpl::InitIsolate(const char* arg, bool useSnapshot) {
  static std::unique_ptr<v8::Platform> platform =
      v8::platform::NewDefaultPlatform();
  std::call_once(flag, []() {
    const char* flag =
        "--noflush_code --noage_code --nocompact_code_space --expose_gc";
    v8::V8::SetFlagsFromString(flag, static_cast<int>(strlen(flag)));

    v8::V8::InitializeICU();
#if defined(OS_WIN)
    auto [_, path] = lynx::base::GetExecutableDirectoryPath();
    std::string path_ansi = lynx::base::Utf8ToANSIOrOEM(path);
    v8::V8::InitializeExternalStartupData((path_ansi + "\\").c_str());
#else
    v8::V8::InitializeExternalStartupData("");
#endif

    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();
  });
#if defined(OS_IOS) || defined(OS_OSX)
  std::string flags = "--expose_gc --jitless --no-lazy";
  v8::V8::SetFlagsFromString(flags.c_str(), flags.size());
#endif
  v8::Isolate::CreateParams create_params(platform.get());
  create_params.array_buffer_allocator =
      v8::ArrayBuffer::Allocator::NewDefaultAllocator();
  isolate_ = v8::Isolate::New(create_params);
}

v8::Isolate* V8IsolateInstanceImpl::Isolate() const { return isolate_; }

}  // namespace piper
}  // namespace lynx
