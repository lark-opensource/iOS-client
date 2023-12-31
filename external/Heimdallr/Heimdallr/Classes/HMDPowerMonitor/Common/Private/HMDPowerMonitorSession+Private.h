//
//  HMDPowerMonitorSession+Private.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import "HMDPowerMonitorSession.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDPowerMonitorSession;
@class HDMPowerMonitorInternalSession;

@protocol HMDPowerMonitorInternalSessionDelegate <NSObject>

- (void)internalSessionDidStart:(HMDPowerMonitorSession *)session
                internalSession:(HDMPowerMonitorInternalSession *)internalSession;

- (void)internalSessionDidEnd:(HMDPowerMonitorSession *)session
              internalSession:(HDMPowerMonitorInternalSession *)internalSession;

@end

@interface HMDPowerMonitorSession (Private)

@property (nonatomic,weak) id<HMDPowerMonitorInternalSessionDelegate> delegate;

@property (nonatomic, copy, readwrite) HMDPowerMonitorSessionConfig *config;

@property (nonatomic, copy, readwrite) NSString *identifier;

+ (instancetype)sessionWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name;

- (void)begin;

- (void)end;

- (void)drop;

- (void)startInternalSession;

- (void)stopInternalSession;

- (long long)totalTime;

- (long long)internalSessionStartSysTime;

@end

NS_ASSUME_NONNULL_END
