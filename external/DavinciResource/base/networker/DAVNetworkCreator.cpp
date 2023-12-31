//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "DavinciLogger.h"
#include "DAVNetworkCreator.h"

using namespace davinci::network;

std::shared_ptr<DAVHttpClient> DAVNetworkCreator::createDAVHttpClient() {
    auto delegate = createDAVHttpClientDelegate();
    return std::make_shared<DAVHttpClient>(delegate);
}

std::shared_ptr<DAVHTTPClientDelegate> DAVNetworkCreator::createDAVHttpClientDelegate() {
    return DAVNetworkClientWrapper::getHttpClientWrapper();
}

DAVNetworkClientWrapper *DAVNetworkClientWrapper::obtain() {
    static DAVNetworkClientWrapper _wrapper;
    return &_wrapper;
}

std::shared_ptr<davinci::network::DAVHTTPClientDelegate> DAVNetworkClientWrapper::getHttpClientWrapper() {
    return DAVNetworkClientWrapper::obtain()->netWraaper;
}

void
DAVNetworkClientWrapper::setHttpClientWrapper(const std::shared_ptr<davinci::network::DAVHTTPClientDelegate> &wraaper) {
    DAVNetworkClientWrapper::obtain()->netWraaper = wraaper;
}