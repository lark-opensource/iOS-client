#include "basic/poller/select_poller.h"

#include <errno.h>
#include <sys/time.h>

#include <climits>
#include <vector>

namespace vmsdk {
namespace general {
SelectPoller::SelectPoller() {
  FD_ZERO(&read_fds_);
  FD_ZERO(&write_fds_);
}

SelectPoller::~SelectPoller() {}

void SelectPoller::WatchFileDescriptor(
    std::unique_ptr<FileDescriptor> descriptor) {
  int fd = descriptor->fd();

  auto iter = file_descriptors_.find(fd);
  if (iter != file_descriptors_.end()) {
    return;
  }
  //    int event = iter->second->event();
  //          if(event & FD_EVENT_IN) FD_SET(fd, &read_fds_);
  //          else FD_CLR(fd, &read_fds_);
  //          if(event & FD_EVENT_OUT) FD_SET(fd, &write_fds_);
  //          else FD_CLR(fd, &write_fds_);

  file_descriptors_.emplace(fd, std::move(descriptor));
  fd_set_.insert(fd);
}

void SelectPoller::RemoveFileDescriptor(int fd) {
  auto iter = file_descriptors_.find(fd);
  if (iter == file_descriptors_.end()) {
    return;
  }

  //  int event = iter->second->event();
  //
  //  if(event & FD_EVENT_IN) FD_CLR(fd, &read_fds_);
  //  if(event & FD_EVENT_OUT) FD_CLR(fd, &write_fds_);

  file_descriptors_.erase(iter);
  fd_set_.erase(fd);
}

void SelectPoller::Poll(int64_t timeout) {
  struct timeval tv = {0, 0};
  struct timeval *ptv = &tv;

  timeout = timeout < 0 ? INT_MAX : timeout;

  tv.tv_sec = static_cast<time_t>(timeout) / 1000;
  tv.tv_usec = (static_cast<time_t>(timeout) % 1000) * 1000;

  ResetFileDescriptor();
  int active_fd = 0;
  if ((active_fd = select((*fd_set_.begin()) + 1, &read_fds_, &write_fds_,
                          nullptr, ptv)) > 0) {
    for (auto iter = fd_set_.begin(); active_fd > 0 && iter != fd_set_.end();
         ++iter) {
      int fd = *iter;
      if (FD_ISSET(fd, &read_fds_) || FD_ISSET(fd, &write_fds_)) {
        active_fds_.push_back(fd);
      }
    }
  }
  ActiveFileDescriptor();
}

void SelectPoller::ResetFileDescriptor() {
  FD_ZERO(&read_fds_);
  FD_ZERO(&write_fds_);

  for (auto iter = fd_set_.begin(); iter != fd_set_.end(); ++iter) {
    FileDescriptor *descriptor = file_descriptors_.find(*iter)->second.get();
    int event = descriptor->event();
    int fd = descriptor->fd();
    if (event & FD_EVENT_IN)
      FD_SET(fd, &read_fds_);
    else
      FD_CLR(fd, &read_fds_);
    if (event & FD_EVENT_OUT)
      FD_SET(fd, &write_fds_);
    else
      FD_CLR(fd, &write_fds_);
  }
}

void SelectPoller::ActiveFileDescriptor() {
  for (auto iter = active_fds_.begin(); iter != active_fds_.end(); ++iter) {
    FileDescriptor *descriptor = file_descriptors_.find(*iter)->second.get();
    int event = descriptor->event();
    int fd = descriptor->fd();
    if (event & FD_EVENT_IN) {
      descriptor->OnFileCanRead(fd);
    } else if (event & FD_EVENT_OUT) {
      descriptor->OnFileCanWrite(fd);
    }
  }
  active_fds_.clear();
}
}  // namespace general
}  // namespace vmsdk
