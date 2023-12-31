// #import "DouyinOpenPlatformLogger.h"

#ifndef DOUYIN_OPENPLATFORM_LOGGER_h
#define DOUYIN_OPENPLATFORM_LOGGER_h
#import "DouyinOpenSDKApplicationDelegate+Privates.h"
#if DEBUG

#define DOUYINOPENPLATFORM_DEBUG

#else

#endif


// LOGE, LOGW are enabled in release mode

#define DOUYIN_OPENPLATFORM_LOGE(s, ... ) \
do{\
[[DouyinOpenSDKApplicationDelegate sharedInstance] onLog:0 Info:s, ##__VA_ARGS__];\
}while(0)

#define DOUYIN_OPENPLATFORM_LOGW(s, ... )\
do{\
    [[DouyinOpenSDKApplicationDelegate sharedInstance] onLog:1 Info:s, ##__VA_ARGS__];\
}while(0)

// LOGD are disabled in release mode

#ifdef DOUYINOPENPLATFORM_DEBUG
#import "DouyinOpenSDKApplicationDelegate+Privates.h"

#define DOUYIN_OPENPLATFORM_LOGD(s, ... ) do{\
[[DouyinOpenSDKApplicationDelegate sharedInstance] onLog:2 Info:s, ##__VA_ARGS__];\
}while(0)

#define DOUYIN_OPENPLATFORM_LOGI(s, ... ) do{\
[[DouyinOpenSDKApplicationDelegate sharedInstance] onLog:3 Info:s, ##__VA_ARGS__];\
}while(0)


#else

#define DOUYIN_OPENPLATFORM_LOGD( s, ... )

#define DOUYIN_OPENPLATFORM_LOGI( s, ... )

#endif

#endif /* DOUYIN_OPENPLATFORM_LOGGER_h */
