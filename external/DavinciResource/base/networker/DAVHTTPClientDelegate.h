//
// Created by wangchengyi.1 on 2021/4/29.
//

#ifndef DAVINCIRESOURCEDEMO_DAVHTTPCLIENTDELEGATE_H
#define DAVINCIRESOURCEDEMO_DAVHTTPCLIENTDELEGATE_H

#include "DAVHttpClientDefine.h"
#include "DAVHttpClientCallback.h"
#include <string>

namespace davinci {
    namespace network {

        class DAV_EXPORT DAVHTTPClientDelegate {

        public:
          virtual ~DAVHTTPClientDelegate() = default;

          virtual bool request(const std::string &url, DAVNetItem *item,
                               void *pHttpClient,
                               HttpClientCallback callback) = 0;

          virtual int64_t getContentLength(int64_t reqid) = 0;
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DAVHTTPCLIENTDELEGATE_H
