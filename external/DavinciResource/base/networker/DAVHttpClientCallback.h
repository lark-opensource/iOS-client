//
//  Created by bytedance on 2020/12/28.
//  @author: xiebo.88
//

#ifndef DAVHttpClientObserver_h
#define DAVHttpClientObserver_h

#include "DAVHttpClientDefine.h"
#include <functional>
#include <string>
#include <utility>

namespace davinci {
    namespace network {

        // 消息扩展参数结构
        typedef struct tag_MsgExtParam {
            HTTP_TYPE eHttpType;                // 请求方式，见EN_HTTP_TYPE
            int64_t uiReqId;                  // 请求ID
            int32_t errorCode = REQUEST_SUCCEEDED; // 发生错误时，错误码, 0为成功
        } MsgExtParam;

        enum class HttpClientCallbackAction {
            SUCCESS = 0,
            RECEIVING_DATA = 1,
            CANCELED = 2,
            FAIL = 3
        };

        /**
         * 消息回调事件通知接口
         *
         * @param    [in] pHttpClient    HttpClient对象
         * @param    [in] actionCode          回调类型.
         * @param    [in] wParam              参数1
         * @param    [in] lParam              参数2
         * @param    [in] stExtParam     消息扩展参数
         *
         */
        using HttpClientCallback = std::function<void(void *pHttpClient, HttpClientCallbackAction actionCode,
                                                      void *wParam,
                                                      int64_t lParam,
                                                      const MsgExtParam &stExtParam)>;

    }
}

#endif /* DAVHttpClientObserver_h */
