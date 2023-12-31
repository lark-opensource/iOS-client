// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "third_party/fml/thread.h"

#include <memory>
#include <string>
#include <utility>

#include "third_party/fml/build_config.h"
#include "third_party/fml/message_loop.h"
#include "third_party/fml/synchronization/waitable_event.h"

#if defined(FML_OS_WIN)
#include <windows.h>
#elif defined(OS_FUCHSIA)
#include <lib/zx/thread.h>
#else
#include <pthread.h>
#endif

#if defined(FML_OS_IOS)
#include "third_party/fml/platform/thread_config_setter.h"
#endif

#if defined(FML_OS_ANDROID)
#include "base/android/android_jni.h"
#endif

namespace lynx {
namespace fml {

#if defined(FML_OS_WIN)
// The information on how to set the thread name comes from
// a MSDN article: http://msdn2.microsoft.com/en-us/library/xcb2z8hs.aspx
const DWORD kVCThreadNameException = 0x406D1388;
typedef struct tagTHREADNAME_INFO {
  DWORD dwType;      // Must be 0x1000.
  LPCSTR szName;     // Pointer to name (in user addr space).
  DWORD dwThreadID;  // Thread ID (-1=caller thread).
  DWORD dwFlags;     // Reserved for future use, must be zero.
} THREADNAME_INFO;
#endif

void SetThreadName(const std::string& name) {
  if (name == "") {
    return;
  }
#if defined(FML_OS_MACOSX)
  pthread_setname_np(name.c_str());
#elif defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)
  pthread_setname_np(pthread_self(), name.c_str());
#elif defined(FML_OS_WIN)
  THREADNAME_INFO info;
  info.dwType = 0x1000;
  info.szName = name.c_str();
  info.dwThreadID = GetCurrentThreadId();
  info.dwFlags = 0;
  __try {
    RaiseException(kVCThreadNameException, 0, sizeof(info) / sizeof(DWORD),
                   reinterpret_cast<DWORD_PTR*>(&info));
  } __except (EXCEPTION_CONTINUE_EXECUTION) {
  }
#elif defined(OS_FUCHSIA)
  zx::thread::self()->set_property(ZX_PROP_NAME, name.c_str(), name.size());
#else
  DLOGI("Could not set the thread name to '" << name << "' on this platform.");
#endif
}

void Thread::SetCurrentThreadName(const Thread::ThreadConfig& config) {
  SetThreadName(config.name);
}

Thread::Thread(const std::string& name)
    : Thread(Thread::SetCurrentThreadName, ThreadConfig(name)) {}

#if defined(FML_OS_IOS)
Thread::Thread(const ThreadConfig& config)
    : Thread(PlatformThreadPriority::Setter, config) {}
#else
Thread::Thread(const ThreadConfig& config)
    : Thread(Thread::SetCurrentThreadName, config) {}
#endif

Thread::Thread(const ThreadConfigSetter& setter, const ThreadConfig& config)
    : joined_(false) {
  fml::AutoResetWaitableEvent latch;
  fml::RefPtr<fml::TaskRunner> runner;

  base::closure setup_thread = [&latch, &runner, setter, config]() {
    setter(config);
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = MessageLoop::GetCurrent();
    runner = loop.GetTaskRunner();
    latch.Signal();
    loop.Run();
    // hack, because we cannot detach vm within MessageLoop Terminate,
    // Terminate is called in Android Looper, the java code.
    // If we invoke attempting DetachCurrentThread within Terminate,
    // we will get another exception "attempting to detach while still running
    // code". so we must detach here, after the loop stop running.
#if defined(FML_OS_ANDROID)
    lynx::base::android::DetachFromVM();
#endif
  };
  thread_ = std::make_unique<std::thread>(std::move(setup_thread));
  latch.Wait();
  task_runner_ = runner;
}

Thread::~Thread() { Join(); }

fml::RefPtr<fml::TaskRunner> Thread::GetTaskRunner() const {
  return task_runner_;
}

void Thread::Join() {
  if (joined_) {
    return;
  }
  joined_ = true;
  task_runner_->PostTask([]() { MessageLoop::GetCurrent().Terminate(); });
  thread_->join();
}

}  // namespace fml
}  // namespace lynx
