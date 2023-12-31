//
//  HMDFluencyDisplayLink.h
//  Heimdallr_NewsInHouse_3A238829
//
//  Created by ByteDance on 2023/5/12.
//

#import <Foundation/Foundation.h>

typedef void(^HMDFluencyDiskplayLinckCallback)(CFTimeInterval timestamp, CFTimeInterval duration, CFTimeInterval targetTimestamp);

NS_ASSUME_NONNULL_BEGIN

@interface HMDFluencyDisplayLinkCallbackObj : NSObject

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy) HMDFluencyDiskplayLinckCallback callback;
@property (nonatomic, copy) void(^becomeActiveCallback)(void);
@property (nonatomic, copy) void(^resignActiveCallback)(void);
@property (nonatomic, assign, readonly) BOOL isRegistered;

@end


@interface HMDFluencyDisplayLink : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;

+ (nonnull instancetype)shared;

- (NSInteger)screenMaximumFramesPerSecond;

- (void)registerFrameCallback:(HMDFluencyDisplayLinkCallbackObj *)obsever completion:(nullable void(^)(CADisplayLink *))completionInMainThread;
- (void)unregisterFrameCallback:(HMDFluencyDisplayLinkCallbackObj *)observer;

@end

NS_ASSUME_NONNULL_END
