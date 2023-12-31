//
// Created by bytedance on 2021/4/16.
//
#ifndef DAVINCIRESOURCE_BASEURLFETCHERTASK_H
#define DAVINCIRESOURCE_BASEURLFETCHERTASK_H

#include "Task.h"
#include "DAVHttpClient.h"
#include "DAVNetworkCreator.h"
#include "DavinciLogger.h"
#include <nlohmann/json.hpp>
#include "ResponseChecker.h"

namespace davinci {
    namespace task {
        template<typename T>
        class BaseUrlFetcherTask : public Task {
        protected:
            std::string url;
        public:
            BaseUrlFetcherTask() = default;

            void run() override {
                auto client = davinci::network::DAVNetworkCreator::createDAVHttpClient();
                auto self = this->shared_from_this();
                std::string *data = new std::string("");
                try {
                    client->RequestGet(url,
                                       [self, client, data](void *pHttpClient,
                                                            network::HttpClientCallbackAction actionCode,
                                                            void *wParam,
                                                            int64_t lParam,
                                                            const network::MsgExtParam &stExtParam) {
                                           std::string dataString((char *) wParam, lParam);
                                           *data = *data + dataString;
                                           if (actionCode ==
                                               network::HttpClientCallbackAction::SUCCESS) {
                                               try {
                                                   auto json = nlohmann::json::parse(*data);
                                                   std::shared_ptr<T> netData = std::make_shared<T>(
                                                           json.get<T>());
                                                   delete data;
                                                   auto checker = static_cast<std::shared_ptr<ResponseChecker>>(netData);
                                                   if (checker->getStatusCode() != 0) {
                                                       const std::string error =
                                                               "status code error, code::" +
                                                               std::to_string(
                                                                       checker->getStatusCode());
                                                       LOGGER->e("fetch url error: %s",
                                                                 error.c_str());
                                                       self->notifyBehindTasksFailed(error);
                                                       return;
                                                   }
                                                   std::dynamic_pointer_cast<BaseUrlFetcherTask>(
                                                           self)->processResponse(netData);
                                                   self->notifyBehindTasksSuccess();
                                               } catch (std::exception &e) {
                                                   std::string error = e.what() ? e.what()
                                                                                : "unknown error";
                                                   LOGGER->e("fetch url error: %s", error.c_str());
                                                   self->notifyBehindTasksFailed(error);
                                                   return;
                                               }
                                               return;
                                           }
                                           if (actionCode ==
                                               network::HttpClientCallbackAction::FAIL) {
                                               delete data;
                                               LOGGER->e("%s", "net request failed");
                                               self->notifyBehindTasksFailed("net request failed");
                                               return;
                                           }
                                       });
                } catch (std::exception &e) {
                    auto error = e.what() ? e.what()
                                          : "unknown error";
                    LOGGER->e("fetch url error: %s", error);
                    notifyBehindTasksFailed(error);
                }
            }

            virtual void processResponse(std::shared_ptr<T>) = 0;

        };

    }
}

#endif//DAVINCIRESOURCE_BASEURLFETCHERTASK_H
