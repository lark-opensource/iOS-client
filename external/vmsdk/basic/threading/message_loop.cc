// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/message_loop.h"

#include "basic/log/logging.h"
#include "basic/no_destructor.h"
#include "basic/task/task.h"
#include "basic/threading/message_pump_io_posix.h"
#include "basic/threading/message_pump_posix.h"
#include "basic/threading/thread_local.h"

#if OS_ANDROID
#include <basic/android/android_jni.h>
#endif

namespace vmsdk {
namespace general {

// A lazily created thread local storage for quick access to a thread's message
// loop.
ThreadLocalPointer<MessageLoop> *GetTLSMessageLoop() {
  static basic::NoDestructor<ThreadLocalPointer<MessageLoop>> lazy_tls_ptr;
  return lazy_tls_ptr.get();
}

MessageLoop::MessageLoop(MESSAGE_LOOP_TYPE type)
    : lock_(), loop_type_(type), pump_(CreatePump(type)) {}

void MessageLoop::BindToCurrentThread() { GetTLSMessageLoop()->Set(this); }

MessageLoop *MessageLoop::current() { return GetTLSMessageLoop()->Get(); }

MessagePump *MessageLoop::CreatePump(MESSAGE_LOOP_TYPE type) {
  MessagePump *pump = NULL;
  switch (type) {
#if OS_IOS
    case MESSAGE_LOOP_JS:
      // for canvas, they need js thread on ios runloop
      pump = MessagePump::CreateForJS(this);
      break;
#elif OS_ANDROID
    case MESSAGE_LOOP_JS:
      pump = new MessagePumpPosix();
      break;
#endif
    case MESSAGE_LOOP_POSIX:
      pump = new MessagePumpPosix();
      break;

#if OS_IOS || OS_ANDROID
    case MESSAGE_LOOP_UI:
    case MESSAGE_LOOP_PLATFORM:
      pump = MessagePump::Create(this);
      break;
#endif
    case MESSAGE_LOOP_IO:
      pump = new MessagePumpIOPosix();
      break;
    default:
      break;
  }
  return pump;
}

void MessageLoop::PostTask(Closure *closure) {
  AutoLock lock(lock_);
  Task task(closure);
  incoming_task_queue_.push(task);
  if (pump_) {
    pump_->ScheduleWork();
  }
}

void MessageLoop::PostTaskAtFront(Closure *closure) {
  AutoLock lock(lock_);
  Task task(closure);

  TaskQueue temp_task_queue;
  temp_task_queue.push(task);
  while (!incoming_task_queue_.empty()) {
    Task temp_task = incoming_task_queue_.front();
    temp_task_queue.push(temp_task);
    incoming_task_queue_.pop();
  }
  incoming_task_queue_ = temp_task_queue;

  if (pump_) {
    pump_->ScheduleWork();
  }
}

void MessageLoop::RemoveTasks() {
  AutoLock lock(lock_);
  while (!incoming_task_queue_.empty()) {
    incoming_task_queue_.pop();
  }
}

void MessageLoop::RemoveTaskByGroupId(uintptr_t group_Id) {
  AutoLock lock(lock_);
  TaskQueue temp_queue;
  while (!incoming_task_queue_.empty()) {
    Task task = incoming_task_queue_.front();
    if (task.IsValid() && task.GetGroupId() != group_Id) {
      temp_queue.push(task);
    }

    incoming_task_queue_.pop();
  }
  incoming_task_queue_ = temp_queue;
}

void MessageLoop::PostDelayedTask(Closure *closure, int delayed_time) {
  // TODO: implement Android & iOS delayed task
  pump_->ScheduleDelayedWork(closure, delayed_time);
}

void MessageLoop::PostIntervalTask(Closure *closure, int delayed_time) {
  // TODO: implement Android & iOS interval task
  pump_->ScheduleIntervalWork(closure, delayed_time);
}

void MessageLoop::RemoveTask(std::shared_ptr<TimerNode> task) {
  pump_->RemoveWork(std::move(task));
}

std::shared_ptr<TimerNode> MessageLoop::PostDelayedTaskInWorkThread(
    Closure *closure, int delayed_time) {
  return pump_->ScheduleDelayedWorkInWorkThread(closure, delayed_time);
}

// TODO:
std::shared_ptr<TimerNode> MessageLoop::PostIntervalTaskInWorkThread(
    Closure *closure, int delayed_time) {
  return pump_->ScheduleIntervalWorkInWorkThread(closure, delayed_time);
}

bool MessageLoop::DoWork() {
  loop_running_ = true;
  while (loop_running_) {
    {
      AutoLock lock(lock_);
      if (quit_task_.IsValid()) {
        loop_running_ = false;
        break;
      }
      incoming_task_queue_.Swap(&working_task_queue_);
      if (working_task_queue_.empty()) break;
    }
#if OS_ANDROID
    JNIEnv *env = general::android::AttachCurrentThread();
#endif
    while (!working_task_queue_.empty()) {
      Task task = working_task_queue_.front();
#if OS_ANDROID
      {
        general::android::JniLocalScope(env, 256);
#endif
        task.Run();
#if OS_ANDROID
      }
#endif
      working_task_queue_.pop();
    }
#if OS_ANDROID
    if (loop_type_ == MESSAGE_LOOP_UI || loop_type_ == MESSAGE_LOOP_PLATFORM) {
      break;  // fix anr
    }
#endif
  }
  return loop_running_;
}

void MessageLoop::Quit(general::Closure *closure) {
  AutoLock lock(lock_);
  quit_task_.Reset(closure);
  // for unit test, before hook, maybe nullptr
  if (pump_ != nullptr) {
    pump_->ScheduleWork();
  }
}

void MessageLoop::DoQuit() {
#if OS_ANDROID
  android::DetachFromVM();
#endif
  pthread_exit(nullptr);
}

void MessageLoop::Run() {
  if (pump_) {
    pump_->Run(this);
  }
}

void MessageLoop::Stop() {
  if (pump_) {
    pump_->Stop();
  }
}
}  // namespace general
}  // namespace vmsdk
