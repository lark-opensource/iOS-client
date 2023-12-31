#ifndef NET_TT_NET_SSL_TT_SSL_UTILS_H_
#define NET_TT_NET_SSL_TT_SSL_UTILS_H_

#include <string>

namespace net {

namespace ttsslutils {

bool CheckTls13Enable(const std::string& host);

bool Check0RttEnable(const std::string& host);

}  // namespace ttsslutils

}  // namespace net

#endif  // NET_TT_NET_SSL_TT_SSL_UTILS_H_
