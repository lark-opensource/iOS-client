#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "React/RCTReconnectingWebSocket.h"
#import "React/RCTSRWebSocket.h"
#import "React/RCTWebSocketExecutor.h"
#import "React/RCTWebSocketModule.h"

FOUNDATION_EXPORT double ReactVersionNumber;
FOUNDATION_EXPORT const unsigned char ReactVersionString[];