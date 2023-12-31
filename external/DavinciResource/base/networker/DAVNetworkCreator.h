//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_NETWORKER_H
#define DAVINCIRESOURCE_NETWORKER_H

#include <cstdint>
#include "DAVHttpClientCallback.h"
#include "DAVHttpClient.h"
#include <memory>

namespace davinci {
    namespace network {
        class DAV_EXPORT DAVNetworkCreator {
        public:
            static std::shared_ptr<DAVHttpClient> createDAVHttpClient();

            static std::shared_ptr<DAVHTTPClientDelegate> createDAVHttpClientDelegate();

        };

        class DAV_EXPORT DAVNetworkClientWrapper {

        public:
            static void setHttpClientWrapper(const std::shared_ptr<davinci::network::DAVHTTPClientDelegate> &wraaper);

            static std::shared_ptr<davinci::network::DAVHTTPClientDelegate> getHttpClientWrapper();

            static DAVNetworkClientWrapper *obtain();

        private:
            std::shared_ptr<davinci::network::DAVHTTPClientDelegate> netWraaper;
        };
    }
}

#endif //DAVINCIRESOURCE_NETWORKER_H
