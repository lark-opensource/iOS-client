//
// Created by xuzhi on 2020/10/22.
//

#ifndef HERMAS_LOG_H
#define HERMAS_LOG_H

HERMAS_API void logd_ios(const char* tag, const char* msg, ...);
HERMAS_API void logi_ios(const char* tag, const char* msg, ...);
HERMAS_API void logw_ios(const char* tag, const char* msg, ...);
HERMAS_API void loge_ios(const char* tag, const char* msg, ...);
HERMAS_API void logf_ios(const char* tag, const char* msg, ...);

#endif //HERMAS_LOG_H
