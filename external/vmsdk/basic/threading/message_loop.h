// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_MESSAGE_LOOP_H_
#define VMSDK_BASE_THREADING_MESSAGE_LOOP_H_

#if OS_ANDROID
#include <queue>
#endif

#include "basic/compiler_specific.h"
#include "basic/task/task.h"
#include "basic/threading/condition.h"
#include "basic/threading/lock.h"
#include "basic/threading/message_pump.h"
#include "basic/threading/message_pump_io_posix.h"

namespace vmsdk {
namespace general {
class TimerNode;

class MessageLoop : public MessagePump::Delegate {
 public:
  enum MESSAGE_LOOP_TYPE {
    MESSAGE_LOOP_UI,
    MESSAGE_LOOP_PLATFORM,
    MESSAGE_LOOP_POSIX,
    MESSAGE_LOOP_IO,
    MESSAGE_LOOP_JS,
  };
  explicit MessageLoop(MESSAGE_LOOP_TYPE type = MESSAGE_LOOP_POSIX);
  void PostTask(Closure *closure);
  void PostTaskAtFront(Closure *closure);
  void PostDelayedTask(Closure *closure, int delayed_time);
  std::shared_ptr<TimerNode> PostDelayedTaskInWorkThread(Closure *closure,
                                                         int delayed_time);
  void PostIntervalTask(Closure *closure, int delayed_time);
  std::shared_ptr<TimerNode> PostIntervalTaskInWorkThread(Closure *closure,
                                                          int delayed_time);
  void RemoveTask(std::shared_ptr<TimerNode> task);
  void RemoveTaskByGroupId(uintptr_t group_Id);
  void RemoveTasks();

  virtual bool DoWork();
  virtual void DoQuit();
  void Run();
  void Stop();
  void BindToCurrentThread();
  void Quit(Closure *closure);

  MessagePump *pump() { return pump_.get(); }

  MESSAGE_LOOP_TYPE type() { return loop_type_; }

  static MessageLoop *current();

 private:
  MessagePump *CreatePump(MESSAGE_LOOP_TYPE type);
  TaskQueue incoming_task_queue_;
  TaskQueue working_task_queue_;
  bool loop_running_;
  Task quit_task_;

  Lock lock_;
  MESSAGE_LOOP_TYPE loop_type_;
  std::unique_ptr<MessagePump> pump_;
};

class MessageLoopForIO : public MessageLoop {
 public:
  MessageLoopForIO() : MessageLoop(MESSAGE_LOOP_IO) {}

  static MessageLoopForIO *current() {
    MessageLoop *loop = MessageLoop::current();
    return static_cast<MessageLoopForIO *>(loop);
  }

  void WatchFileDescriptor(std::unique_ptr<FileDescriptor> descriptor) {
    static_cast<MessagePumpIOPosix *>(pump())->poller()->WatchFileDescriptor(
        std::move(descriptor));
  }

  void RemoveFileDescriptor(int fd) {
    static_cast<MessagePumpIOPosix *>(pump())->poller()->RemoveFileDescriptor(
        fd);
  }

 private:
  MESSAGE_LOOP_TYPE ALLOW_UNUSED_TYPE type_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_MESSAGE_LOOP_H_
