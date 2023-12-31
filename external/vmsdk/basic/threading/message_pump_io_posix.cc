// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/message_pump_io_posix.h"

#include <errno.h>
#include <unistd.h>

#include "basic/log/logging.h"
#include "basic/poller/select_poller.h"
#include "basic/poller/utility.h"

namespace vmsdk {
namespace general {

MessagePumpIOPosix::MessagePumpIOPosix()
    : loop_running_(true),
      wakeup_pipe_in_(-1),
      wakeup_pipe_out_(-1),
      poller_(new SelectPoller),
      quit_(false),
      lock_destroy_(),
      condition_destroy_(lock_destroy_) {
  Init();
}

MessagePumpIOPosix::~MessagePumpIOPosix() {
  AutoLock lock(lock_destroy_);
  if (!quit_) {
    condition_destroy_.Wait();
  }
  if (wakeup_pipe_in_ >= 0) {
    close(wakeup_pipe_in_);
  }
  if (wakeup_pipe_out_ >= 0) {
    close(wakeup_pipe_out_);
  }
  poller_->RemoveFileDescriptor(wakeup_pipe_out_);
  poller_.reset();
}

void MessagePumpIOPosix::ScheduleWork() {
  char buf = 0;
  // int nwrite = write(wakeup_pipe_in_, &buf, 1);
  write(wakeup_pipe_in_, &buf, 1);
}

void MessagePumpIOPosix::ScheduleDelayedWork(Closure *closure,
                                             int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time);
  timer_.SetTimerNode(node);
  ScheduleWork();
}

void MessagePumpIOPosix::ScheduleIntervalWork(Closure *closure,
                                              int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time, true);
  timer_.SetTimerNode(node);
  ScheduleWork();
}

void MessagePumpIOPosix::Run(Delegate *delegate) {
  {
    AutoLock lock_destroy(lock_destroy_);
    while (loop_running_) {
      timer_.Loop();
      loop_running_ = delegate->DoWork();
      if (loop_running_) {
        uint64_t next_timeout = timer_.NextTimeout();
        uint64_t current_time = CurrentTimeMilliseconds();
        if (next_timeout > current_time) {
          poller_->Poll(next_timeout - current_time);
        }
      }
    }
    quit_ = true;
  }
  condition_destroy_.Signal();
  delegate->DoQuit();
}

void MessagePumpIOPosix::Stop() {
  loop_running_ = false;
  char buf = 0;
  // int nwrite = write(wakeup_pipe_in_, &buf, 1);
  write(wakeup_pipe_in_, &buf, 1);
}

void MessagePumpIOPosix::OnFileCanRead(int fd) {
  char buf;
  size_t nread = read(fd, &buf, 1);
  if (nread != 1) {
    DLOGE("MessagePumpIOPosix Read Error");
  }
}

void MessagePumpIOPosix::OnFileCanWrite(int fd) {}

bool MessagePumpIOPosix::Init() {
  int fds[2];
  if (pipe(fds)) {
    DLOGE("pipe() failed, errno: " << errno);
    return false;
  }
  if (!SetNonBlocking(fds[0])) {
    DLOGE("SetNonBlocking for pipe fd[0] failed, errno: " << errno);
    return false;
  }
  if (!SetNonBlocking(fds[1])) {
    DLOGE("SetNonBlocking for pipe fd[1] failed, errno: " << errno);
    return false;
  }
  wakeup_pipe_out_ = fds[0];
  wakeup_pipe_in_ = fds[1];

  poller_->WatchFileDescriptor(
      std::make_unique<FileDescriptor>(this, wakeup_pipe_out_, FD_EVENT_IN));
  return true;
}
}  // namespace general
}  // namespace vmsdk
