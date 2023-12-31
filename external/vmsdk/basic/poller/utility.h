#ifndef VMSDK_BASE_POLLER_UTILITY_H_
#define VMSDK_BASE_POLLER_UTILITY_H_

#include <fcntl.h>

namespace vmsdk {
namespace general {
bool SetNonBlocking(int fd);
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_POLLER_UTILITY_H_
