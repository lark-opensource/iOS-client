//
//  Log.h
//  Pods
//
//  Created by taoyiyuan on 2020/5/14.
//

#import <BDAlogProtocol/BDAlogProtocol.h>

// LOGE, LOGW, LOGI are enabled in release mode

#define LOGE( s, ... ) BDALOG_PROTOCOL_ERROR(@"Error %s: %@", __FUNCTION__, [NSString stringWithFormat:(s), ##__VA_ARGS__]);

#define LOGW( s, ... ) BDALOG_PROTOCOL_WARN(@"Warn %s: %@", __FUNCTION__, [NSString stringWithFormat:(s), ##__VA_ARGS__]);

#define LOGI( s, ... ) BDALOG_PROTOCOL_INFO(@"Info %s: %@", __FUNCTION__, [NSString stringWithFormat:(s), ##__VA_ARGS__]);

// LOGD, LOGT are disabled in release mode

#if defined(DEBUG) && defined(ENABLE_TTNET_DEBUG_LOG)

#define LOGD( s, ... ) BDALOG_PROTOCOL_DEBUG(@"Debug %s: %@", __FUNCTION__, [NSString stringWithFormat:(s), ##__VA_ARGS__]);

#define TICK  NSDate *startTime = [NSDate date]
#define TOCK  LOGD(@"took time: %f seconds.", -[startTime timeIntervalSinceNow])

#else

#define LOGD( s, ... )

#define LOGT( s, ... )

#define TICK
#define TOCK

#endif
