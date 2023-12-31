// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/thread_impl_posix.h"

#include "basic/log/logging.h"

#if OS_ANDROID
#include "basic/android/android_jni.h"
#endif

namespace vmsdk {
namespace general {

void *ThreadFunc(void *params) {
  ThreadImplPosix *thread = static_cast<ThreadImplPosix *>(params);
#if OS_IOS
  pthread_setname_np(thread->thread_name().c_str());
#elif OS_ANDROID
  pthread_setname_np(thread->thread_handle(), thread->thread_name().c_str());
#endif
  thread->Run();
#if OS_ANDROID
  android::DetachFromVM();
#endif
  return NULL;
}

ThreadImplPosix::ThreadImplPosix(MessageLoop::MESSAGE_LOOP_TYPE type,
                                 const ThreadInfo &info)
    : ThreadImpl(type, info) {}

// FIXME(heshan):posix thread may cause tls destructor crash or dead lock
// when thread eixt on linux/Android platform. If you need use this now,
// please ensure use a static variable and never destroy!
ThreadImplPosix::~ThreadImplPosix() {
  LOGE("use not static posix thread is illegal now!!!");
}

void ThreadImplPosix::Start() {
  if (message_loop_.type() == MessageLoop::MESSAGE_LOOP_UI) {
    Run();
    return;
  }
  bool err = pthread_create(&thread_handle_, NULL, ThreadFunc, this);

  if (err) {
    LOGE("thread start failed!!!");
    return;
  }
#if OS_ANDROID
  err = pthread_setname_np(thread_handle_, thread_name().c_str());
  if (err) {
    LOGE("thread set name " << thread_name() << " failed: " << strerror(err));
  }
#endif
}

void ThreadImplPosix::Join() {
  if (thread_handle_) {
    pthread_join(thread_handle_, NULL);
  }
}

}  // namespace general
}  // namespace vmsdk
