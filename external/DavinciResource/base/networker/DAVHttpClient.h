//
//  DAVHttpClient.h
//  PiexlPaltform
//
//  Created by bytedance on 2020/12/28.
//  @author:
//

#ifndef DAVHttpClient_h
#define DAVHttpClient_h

#include <stdio.h>
#include <atomic>
#include <map>
#include <string>
#include <mutex>
#include "DAVHttpClientCallback.h"
#include "DAVHTTPClientDelegate.h"

namespace davinci {
    namespace executor {
        class Executor;
    }
}
namespace davinci {
    namespace network {
        class DAV_EXPORT DAVHttpClient : public std::enable_shared_from_this<DAVHttpClient> {
        public:
            explicit DAVHttpClient(std::shared_ptr<DAVHTTPClientDelegate> httpClientDelegate);

            virtual ~DAVHttpClient() = default;

        public:

            /* 设置总超时时间
             * @param ms [in] 超时时间(单位:毫秒)
             *
             *        @return
             */
            void SetTimeOut(int64_t ms);

            /* 设置传输超时时间
             * @param ms [in] 超时时间(单位:毫秒)
             *
             *        @return
             */
            void SetTransferTimeOut(int64_t ms);

            /* 添加请求头
             */
            void AddRequestHeader(const std::string &key, const std::string &value);

            /* 清除头参数
             *
             *        @return.
             */
            void ClearRequestHeader();

            /* 发送get请求，不会立刻发送，会有任务等待
             * @param url         [in] domain
             * @param bShowStatus [in] 是否回调数据流程结果
             *
             *        @return 成功返回true, 否则返回false.
             */
            int64_t RequestGet(const std::string &url, const HttpClientCallback &callback = nullptr);

            /* 设置是否接受一次回调
             *
             *        @return 成功返回true, 否则返回false.
             */
            bool SetOnceCallback(bool bOnce = true);

            /* 获取总的接受数据长度 content-length
             *
             *        @return 返回长度.
             */
            int64_t GetCurContentLength(int64_t reqid);

        private:
            static void executeRequest(DAVHttpClient *httpClient, DAVNetItem *item, const std::string &url,
                                       const HttpClientCallback &callback);

//            std::shared_ptr<DAVThreadPool> threadPool;
            std::shared_ptr<davinci::executor::Executor> executor;
            std::shared_ptr<DAVHTTPClientDelegate> httpClientDelegate;
            std::recursive_mutex dataMutex;
            std::recursive_mutex mutex;
            int64_t totalTime;
            int64_t transferTime;
            std::string postData;
            std::string filePath;
            std::unordered_map<std::string, std::string> headerMap;
            bool onceCallback;
        };
    }
}

#endif /* DAVHttpClient_h */
