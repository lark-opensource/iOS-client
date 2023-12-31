//
//  Created by bytedance on 2020/12/28.
//

#ifndef DAVHttpClientDefine_h
#define DAVHttpClientDefine_h

#include <string>
#include <map>
#include <unordered_map>

#ifndef DAV_EXPORT
#ifdef _MSC_VER
#define DAV_EXPORT __declspec(dllexport)
#else
#define DAV_EXPORT __attribute__((visibility("default")))
#endif
#endif

namespace davinci {
    namespace network {
        enum HTTP_TYPE {
            HTTP_GET = 0,        // Get请求方式
            HTTP_POST = 1,       // Post请求方式
        };

        enum REQUEST_STATUS_CODE {
            REQUEST_ERROR_CONNECTION_RESET = -101,
            REQUEST_ERROR_NAME_NOT_RESOLVED = -105,
            REQUEST_ERROR_INTERNET_DISCONNECTED = -106,
            REQUEST_ERROR_CANCELED = -999,
            REQUEST_ERROR_BAD_URL = -1000,
            REQUEST_ERROR_TIME_OUT = -1001,
            REQUEST_ERROR_UN_SUPPORT_URL = -1002,
            REQUEST_ERROR_UN_FIND_HOST = -1003,
            REQUEST_ERROR_CAN_NOT_CONNECT_TO_HOST = -1004,
            REQUEST_ERROR_NETWORK_CONNECTION_LOST = -1005,
            REQUEST_ERROR_DNS_LOOJUP_FAILED = -1006,
            REQUEST_ERROR_HTTP_TOO_MANY_REDIRECTS = -1007,
            REQUEST_ERROR_RESOURCE_UNAVAILABLE = -1008,
            REQUEST_ERROR_NOT_CONNECTED_TO_INTERNET = -1009,
            REQUEST_SUCCEEDED = 0,
            REQUEST_RECEIVING_DATA = 1002,
        };

        typedef struct tagDAVNetItem {
            HTTP_TYPE httpType;
            int64_t requestId;
            std::unordered_map<std::string, std::string> headerMap;
        } DAVNetItem;
    }
}

#endif /* DAVHttpClientDefine_h */
