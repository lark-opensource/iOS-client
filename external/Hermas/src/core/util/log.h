//
// Created by bytedance on 2020/8/7.
//


#ifndef HERMAS_PORT_LOG_H
#define HERMAS_PORT_LOG_H

#include <stdlib.h>
#include <BDAlogProtocol/BDAlogProtocol.h>
#include "env.h"

namespace hermas
{
#define logv(tag, args, ...)  ALOG_PROTOCOL_DEBUG_TAG(tag, args, ##__VA_ARGS__);
#define logd(tag, args, ...)  ALOG_PROTOCOL_DEBUG_TAG(tag, args, ##__VA_ARGS__);
#define logi(tag, args, ...)  ALOG_PROTOCOL_INFO_TAG(tag, args, ##__VA_ARGS__);
#define logw(tag, args, ...)  ALOG_PROTOCOL_WARN_TAG(tag, args, ##__VA_ARGS__);
#define loge(tag, args, ...)  ALOG_PROTOCOL_ERROR_TAG(tag, args, ##__VA_ARGS__);

}

#endif //HERMAS_PORT_LOG_H
