// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxUI;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
@interface LynxAnimationDelegate : NSObject <CAAnimationDelegate>
#else
@interface LynxAnimationDelegate : NSObject
#endif

typedef void (^DidAnimationStart)(CAAnimation* __nullable animation);
typedef void (^DidAnimationStop)(CAAnimation* __nullable animation, BOOL finished);

@property(nonatomic, copy, nullable) DidAnimationStart didStart;
@property(nonatomic, copy, nullable) DidAnimationStop didStop;

+ (instancetype)initWithDidStart:(DidAnimationStart __nullable)start didStop:(DidAnimationStop)stop;

- (void)forceStop;

+ (void)sendAnimationEvent:(LynxUI*)ui
                 eventName:(NSString*)eventName
               eventParams:(NSDictionary*)params;

@end

NS_ASSUME_NONNULL_END
