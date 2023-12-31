//  Copyright 2020 The Vmsdk Authors. All rights reserved.

#import "basic/iOS/VmsdkThreadManager.h"

#include "basic/threading/thread_impl_ios.h"

#include "basic/log/logging.h"

namespace vmsdk {
namespace general {

ThreadImplIOS::ThreadImplIOS(MessageLoop::MESSAGE_LOOP_TYPE type, const ThreadInfo &info)
    : ThreadImpl((type == MessageLoop::MESSAGE_LOOP_JS ? MessageLoop::MESSAGE_LOOP_JS
                                                       : MessageLoop::MESSAGE_LOOP_PLATFORM),
                 info),
      is_ui_(type == MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_UI) {}

ThreadImplIOS::~ThreadImplIOS() {}

typedef void (^dispatch_block_t)(void);

void ThreadImplIOS::Start() {
  dispatch_block_t runnable = ^{
    Run();
  };
  if (is_ui_) {
    if ([[NSThread currentThread] isMainThread]) {
      Run();
    } else {
      [VmsdkThreadManager runBlockInMainQueue:runnable];
    }
  } else {
    // create thread and start runLoop in iOS, then execute
    // "ThreadImplIOS::Run()" in runLoop of this thread
    const char *name_char = thread_name().c_str();
    [VmsdkThreadManager createIOSThread:[NSString stringWithUTF8String:name_char]
                               runnable:runnable];
  }
}

void ThreadImplIOS::Run() {
  pthread_setname_np(thread_name().c_str());
  ThreadImpl::Run();
  thread_handle_ = pthread_self();
}

void ThreadImplIOS::Join() {
  if (thread_handle_) {
    pthread_join(thread_handle_, NULL);
  }
}

}  // namespace general
}  // namespace vmsdk
