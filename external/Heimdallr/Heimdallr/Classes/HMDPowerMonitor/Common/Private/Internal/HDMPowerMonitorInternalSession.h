//
//  BDPowerLogInternalSession.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HDMPowerMonitorInternalSession : NSObject

@property(nonatomic,assign) BOOL isForeground;

- (void)begin;

- (void)end;

- (int)state;

- (long long)beginSysTime;

- (long long)endSysTime;

- (void)generateLogInfo:(void(^)(NSDictionary * _Nullable logInfo,NSDictionary * _Nullable extra))completion;

- (void)addCustomEvent:(NSDictionary *)event;

- (void)addEvent:(NSString *)eventName params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
