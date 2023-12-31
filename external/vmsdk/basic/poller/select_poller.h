#ifndef VMSDK_BASE_SELECT_POLLER_H_
#define VMSDK_BASE_SELECT_POLLER_H_

#include <sys/select.h>

#include <set>
#include <vector>

#include "basic/poller/poller.h"

namespace vmsdk {
namespace general {
class SelectPoller : public Poller {
 public:
  SelectPoller();

  virtual ~SelectPoller();

  virtual void WatchFileDescriptor(std::unique_ptr<FileDescriptor> descriptor);

  virtual void RemoveFileDescriptor(int fd);

  virtual void Poll(int64_t timeout);

 private:
  void ResetFileDescriptor();

  void ActiveFileDescriptor();

  fd_set read_fds_;
  fd_set write_fds_;

  std::set<int, std::greater<int>> fd_set_;
  std::vector<int> active_fds_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_SELECT_POLLER_H_
