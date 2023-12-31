#ifndef NET_TT_NET_BASE_REQUEST_LOG_GET_INFO_H_
#define NET_TT_NET_BASE_REQUEST_LOG_GET_INFO_H_

#include "net/base/load_timing_info.h"

namespace net {

class SSLInfo;
class ConnectJob;

std::unique_ptr<base::Value> GetDNSInfo(
    const LoadTimingInfo::ConnectTiming& connect_timing);
std::unique_ptr<base::Value> GetOtherInfo();
std::unique_ptr<base::Value> GetSSLInfo(const SSLInfo& ssl_info);
std::unique_ptr<base::Value> GetTimingInfo(
    const LoadTimingInfo::ConnectTiming& connect_timing);
std::unique_ptr<base::Value> GetSocketInfo(const ConnectJob* job);

}  // namespace net

#endif  // NET_TT_NET_BASE_REQUEST_LOG_GET_INFO_H_
