//
//  Created by bytedance on 2020/12/28.
//  @author: xiebo.88
//

#include "DAVHttpClient.h"

#include <utility>
#include <Executor.h>
#include <ExecutorCreator.h>
#include <DavinciLogger.h>
#include <IdGenerator.h>

using namespace davinci::network;

DAVHttpClient::DAVHttpClient(std::shared_ptr<DAVHTTPClientDelegate> httpClientDelegate)
        : transferTime(20000),
          totalTime(600000), onceCallback(true), httpClientDelegate(std::move(httpClientDelegate)) {
    executor = davinci::executor::ExecutorCreator::createExecutor();
}

void DAVHttpClient::SetTimeOut(int64_t ms) {
    totalTime = ms;
}

void DAVHttpClient::SetTransferTimeOut(int64_t ms) {
    transferTime = ms;
}

void DAVHttpClient::AddRequestHeader(const std::string &key, const std::string &value) {
    std::unique_lock<std::recursive_mutex> lock(dataMutex);
    headerMap.emplace(std::make_pair(key, value));
}

void DAVHttpClient::ClearRequestHeader() {
    std::unique_lock<std::recursive_mutex> lock(dataMutex);
    headerMap.clear();
}

void
DAVHttpClient::executeRequest(DAVHttpClient *httpClient, DAVNetItem *item, const std::string &url,
                              const HttpClientCallback &callback) {
    bool bResult = httpClient->httpClientDelegate->request(url, item, httpClient, callback);
    if (!bResult) {
        std::unique_lock<std::recursive_mutex> lock(httpClient->mutex);
        if (callback != nullptr) {
            MsgExtParam stExtParam;
            stExtParam.eHttpType = item->httpType;
            stExtParam.uiReqId = item->requestId;
            stExtParam.errorCode = -1;
            callback(httpClient, HttpClientCallbackAction::FAIL, nullptr, 0, stExtParam);
        }
    }
}

int64_t DAVHttpClient::RequestGet(const std::string &url, const HttpClientCallback &callback) {
    int64_t reqid = davinci::executor::IDGenerator::get().generateId();;
    auto pItem = new DAVNetItem;
    pItem->httpType = HTTP_GET;
    pItem->requestId = reqid;
    pItem->headerMap = headerMap;
    auto self = this->shared_from_this();
    executor->commit([self, pItem, url, callback] {
        auto callbackWrapper = [callback, pItem](void *pHttpClient,
                                                 HttpClientCallbackAction actionCode,
                                                 void *wParam,
                                                 int64_t lParam,
                                                 const MsgExtParam &stExtParam) {
            callback(pHttpClient, actionCode, wParam, lParam, stExtParam);
            delete pItem;
        };
        bool bResult;
        try {
            bResult = self->httpClientDelegate->request(url, pItem, self.get(), callbackWrapper);
        } catch (std::exception &e) {
            LOGGER->e("network error: %s", e.what() ? e.what() : "unknown error");
            bResult = false;
        }
        if (!bResult) {
            std::unique_lock<std::recursive_mutex> lock(self->mutex);
            if (callback != nullptr) {
                MsgExtParam stExtParam;
                stExtParam.eHttpType = pItem->httpType;
                stExtParam.uiReqId = pItem->requestId;
                stExtParam.errorCode = -1;
                callbackWrapper(self.get(), HttpClientCallbackAction::FAIL, nullptr, 0, stExtParam);
            }
        }
    });
    return reqid;
}

bool DAVHttpClient::SetOnceCallback(bool bOnce) {
    onceCallback = bOnce;
    return true;
}

int64_t DAVHttpClient::GetCurContentLength(int64_t reqid) {
    return httpClientDelegate->getContentLength(reqid);
}
