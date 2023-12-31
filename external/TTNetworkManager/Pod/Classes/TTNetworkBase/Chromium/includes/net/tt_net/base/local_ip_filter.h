#ifndef NET_TT_NET_BASE_LOCAL_IP_FILTER_H_
#define NET_TT_NET_BASE_LOCAL_IP_FILTER_H_

#include "net/base/network_interfaces.h"

namespace net {

typedef bool (*Filter)(const NetworkInterface& interface);

bool DefaultFilter(const NetworkInterface& interface);

bool LocalIpFilter(NetworkInterfaceList* networks,
                   Filter filter = DefaultFilter);

}  // namespace net

#endif  // NET_TT_NET_BASE_LOCAL_IP_FILTER_H_
